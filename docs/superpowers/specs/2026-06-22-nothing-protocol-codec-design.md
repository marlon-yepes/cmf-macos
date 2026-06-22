# NothingProtocol Codec — Design Spec

**Date:** 2026-06-22
**Status:** Approved (pending written-spec review)
**Author:** Marlon Yepes (with Claude)

## 1. Context & Motivation

A prior audit of this repo surfaced three connected weaknesses, all rooted in
the same place — the device protocol layer inside the 1,150-line
`NothingServiceImpl.swift`:

- **Zero real test coverage.** The only test files are empty Xcode template
  stubs (`testExample`, `testPerformanceExample`).
- **Brittle parsing with magic numbers.** Decoders read fixed offsets
  (`hexArray[8]`, `[9]`, `[10]`, ...) scattered through the class, with no named
  constants and no typed packet model.
- **Broken CI.** `.github/workflows/swift.yml` runs `swift build` / `swift test`,
  but there is no `Package.swift` (it is an `.xcodeproj`), so the job fails on
  every push.

Nothing publishes **no official SDK or protocol documentation** for its earbuds;
the protocol is reverse-engineered by the community (Gadgetbridge, earctl,
Ear-web, Nothing-Ear-Linux). That makes the protocol layer the highest-risk part
of the app: a firmware update can silently break parsing, and today there is
nothing that would catch it.

The two PRs already integrated into `main` (latency-parse fix, request-queue race
fixes) were both bugs in exactly this layer — empirical proof that this is where
defects live.

## 2. Goal

Extract the device protocol into a **standalone, pure-Swift, fully-tested SwiftPM
package** (`NothingProtocol`), and give the repo a **CI that actually runs those
tests**. This directly addresses the three weaknesses above and creates a
testable foundation for later work.

## 3. Scope

### In scope
- A new SwiftPM package `NothingProtocol` in a `NothingProtocol/` subdirectory,
  pure Foundation (no SwiftUI / IOBluetooth / AppKit).
- Frame **encoding** (outbound command packets) and **decoding** (inbound packet
  framing + CRC validation).
- Typed **decoders** for the inbound payloads currently parsed in
  `NothingServiceImpl.swift` (battery, latency, in-ear, ANC, EQ, firmware,
  serial, ear-tip result, etc. — see §5).
- A test suite with golden byte-vectors, runnable **two ways**: XCTest
  (`swift test`, for Xcode/CI) and a `verify` executable (`swift run`, for local
  and toolchain-agnostic CI).
- A new CI workflow that runs the codec tests and (best-effort) builds the app.

### Out of scope (explicitly deferred)
- **Wiring the package into the app.** `NothingServiceImpl.swift` is NOT modified
  in this work. `main` keeps compiling unchanged. App integration is a separate,
  Xcode-verified follow-up.
- **Changing protocol behavior / fixing protocol bugs.** This is an extraction,
  not a redesign (see §4).
- Concurrency rework, localization, force-cast fixes, `#warning` TODOs — separate
  improvements.

## 4. Guiding Principle: Extraction, Not Redesign

The codec must reproduce current behavior:
- **Encoding** must be **byte-identical** to `send(command:operationID:payload:)`.
- **Decoding** must be **value-identical** to the current `read*` functions for
  the same input bytes.

Tests freeze the *current* behavior. If a current decoder looks buggy, it is
**documented in the spec/tests but not changed here** — fixes ship as separate,
reviewable steps so behavior changes are never entangled with the refactor.

The **only** new behavior introduced is **defensive robustness**: malformed or
too-short frames, or frames failing CRC, return `nil` / empty results instead of
crashing or reading out of bounds. (The current code already uses `guard count >
N` in places; this generalizes that consistently.)

## 5. Protocol Reference (as implemented today)

Transport: Bluetooth Classic RFCOMM, channel 15. Confirmed against community docs
(Gadgetbridge): packets framed with magic `0x55`.

### Outbound packet (from `send(...)`)
```
byte:   0     1     2     3      4      5          6     7            8..      n-2    n-1
        0x55  0x60  0x01  cmdHi  cmdLo  payloadLen 0x00  operationID  payload  crcLo  crcHi
```
- `cmdHi/cmdLo` = `Command.rawValue` big-endian (`UInt16`).
- `payloadLen` = `UInt8(clamping: payload.count)`.
- `operationID` = `Command.firstEightBits` = `rawValue >> 8`.
- CRC = **CRC-16/MODBUS** (init `0xFFFF`, reflected poly `0xA001`) over bytes
  `[0 ..< n-2]`, appended little-endian (low byte first).

### Inbound packet
Same 8-byte header shape; `operationID` at index `7`; payload from index `8`;
trailing CRC. Decoders read fixed payload offsets (e.g. battery count at `[8]`,
device pairs at `9+2i`/`10+2i`; latency flag at `[8]`).

### Command IDs
Lifted verbatim from `domain/enums/Commands.swift` (GET_*/SET_*/READ_* groups).

### Decoders to port (parity-checked)
`readBattery`, `readLatencyMode`, `readInEarDetection`, `readANC`, `readEQ`,
`readFirmware`, `readSerial`, `readGestures`, `readCustomEQ`, `readAdvancedEQ`,
`readEnhancedBass`, `readPersonalizedANC`, `readEarTipTestResult`, `readCaseLED`.
Each becomes a pure function returning a typed value (struct/enum), not a mutation
of a device model.

## 6. Package Structure

```
NothingProtocol/
  Package.swift                 (swift-tools-version 5.7; no external deps)
  Sources/
    NothingProtocol/            ← library: the codec
      CRC16.swift
      Command.swift
      Packet.swift              (PacketEncoder / PacketDecoder, InboundPacket)
      Constants.swift           (header bytes, offsets, masks, device IDs)
      Decoders/                 (BatteryStatus, LatencyMode, ANCState, ... )
      Models.swift              (typed result structs/enums)
    NothingProtocolTestKit/     ← library: golden vectors + runChecks()
      Vectors.swift
      Checks.swift              (runChecks() -> [CheckResult])
    nothing-protocol-verify/    ← executable: swift run, exits 1 on failure
      main.swift
  Tests/
    NothingProtocolTests/       ← XCTest: thin wrapper over runChecks()
```

**Single source of test cases.** All input→expected vectors and the assertion
logic live in `NothingProtocolTestKit.runChecks()`, which returns a list of
pass/fail results. Two runners consume it:
- `nothing-protocol-verify` (executable): prints results, exits non-zero on any
  failure. Runnable **locally** via `swift run` (no XCTest needed) and in CI.
- `NothingProtocolTests` (XCTest): one `XCTAssert` per check. Runs in Xcode and
  via `swift test` on CI.

This avoids duplicate test data and works around the local toolchain lacking
XCTest (CommandLineTools has SwiftPM + `swift run`, but not XCTest/Xcode).

## 7. Test Coverage

- **CRC16:** known buffer → known checksum; round-trip (encode then verify CRC).
- **Encode:** each in-scope `GET_*`/`SET_*` command with representative payloads
  → exact expected byte arrays (golden vectors captured from current `send`
  logic).
- **Decode framing:** valid frame → correct command/operationID/payload;
  CRC-mismatch frame → rejected (`nil`); truncated frame → `nil`; wrong magic →
  `nil`.
- **Typed decoders:** representative real frames → exact expected values
  (battery L/R/case + charging, latency on/off, in-ear, ANC mode, EQ profile,
  firmware/serial strings, ear-tip result, ...). Cross-checked against
  Gadgetbridge where a reference vector exists.
- **Robustness:** empty / short / oversized frames never crash.

## 8. CI Design

Replace `.github/workflows/swift.yml` with jobs that actually pass:

- **`codec` job** (`macos-latest`):
  `cd NothingProtocol && swift build && swift run nothing-protocol-verify && swift test`
  — fast, validates the codec on every push/PR.
- **`app-build` job** (`macos-latest`, best-effort):
  `xcodebuild -project "Nothing X MacOS.xcodeproj" -scheme "<scheme>" -destination 'platform=macOS' build CODE_SIGNING_ALLOWED=NO`
  — validates the app compiles.
  *Caveat:* requires a **shared** Xcode scheme (current schemes live in
  `xcuserdata`, i.e. not shared). Marking a scheme shared is a small prerequisite;
  if it's not feasible in this step, the `app-build` job is added but allowed to be
  a follow-up. The `codec` job is the primary deliverable and is fully verifiable.

## 9. Success Criteria

1. `cd NothingProtocol && swift run nothing-protocol-verify` passes locally
   (verified in this environment).
2. `swift build` of the package succeeds locally.
3. The package is pure Foundation (no app frameworks); the app and `main` are
   untouched and still compile.
4. CI runs the codec tests on push/PR (no more failing `swift build`).
5. Encode output is byte-identical and decode output value-identical to the
   current implementation for all golden vectors.

## 10. Risks & Mitigations

- **Behavior drift during extraction** → golden vectors derived from current
  logic lock parity; principle §4 forbids behavior changes here.
- **Unknown real-world frames** → defensive decoding returns `nil` rather than
  crashing; unhandled commands are surfaced, not swallowed.
- **CI app-build needs a shared scheme** → handled as a flagged prerequisite;
  does not block the codec deliverable.

## 11. Follow-ups (after this lands)
- Integrate `NothingProtocol` into `NothingServiceImpl` (Xcode-verified).
- Fix any protocol bugs found, now covered by tests.
- Concurrency → actor; force-cast removal; localization; `#warning` cleanup.
