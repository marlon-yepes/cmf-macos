# NothingProtocol Codec Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans or
> superpowers:subagent-driven-development to implement this plan task-by-task.
> Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extract the Nothing/CMF earbud RFCOMM protocol into a standalone,
pure-Swift, fully-tested SwiftPM package (`NothingProtocol`) and give the repo CI
that actually runs the tests.

**Architecture:** A `NothingProtocol/` subpackage (own `Package.swift`) with a
codec library, a test-kit library holding golden vectors + a `runChecks()`
function, an executable `verify` runner (`swift run`, local + CI), and an XCTest
target wrapping `runChecks()`. The app and `main` are not modified.

**Tech Stack:** Swift 5.7, SwiftPM, Foundation only. No external dependencies.
XCTest (CI/Xcode) + plain-assertion executable (local).

## Global Constraints

- Package is **pure Foundation** — no SwiftUI / IOBluetooth / AppKit imports.
- **No external dependencies** in `Package.swift`.
- `swift-tools-version:5.7`.
- **Extraction, not redesign:** encode output byte-identical to current
  `send(command:operationID:payload:)`; decode output value-identical to current
  `read*` functions. No protocol-behavior changes.
- Only new behavior allowed: defensive parsing (return `nil`/empty on malformed,
  short, or CRC-failing frames — never crash, never out-of-bounds).
- The app (`Nothing X MacOS/`) and `main` history are untouched by this plan.
- Local verification gate per task: `cd NothingProtocol && swift run nothing-protocol-verify`.

---

### Task 1: Package skeleton, CRC16, and the test harness

**Files:**
- Create: `NothingProtocol/Package.swift`
- Create: `NothingProtocol/Sources/NothingProtocol/CRC16.swift`
- Create: `NothingProtocol/Sources/NothingProtocolTestKit/CheckResult.swift`
- Create: `NothingProtocol/Sources/NothingProtocolTestKit/Checks.swift`
- Create: `NothingProtocol/Sources/nothing-protocol-verify/main.swift`
- Create: `NothingProtocol/Tests/NothingProtocolTests/RunChecksTests.swift`

**Interfaces:**
- Produces: `NothingProtocol.crc16(_ bytes: [UInt8]) -> UInt16`
- Produces: `struct CheckResult { let name: String; let passed: Bool; let detail: String }`
- Produces: `func runChecks() -> [CheckResult]` (in `NothingProtocolTestKit`)

- [ ] **Step 1: Write `Package.swift`** with four targets: library `NothingProtocol`,
  library `NothingProtocolTestKit` (deps: `NothingProtocol`), executable
  `nothing-protocol-verify` (deps: `NothingProtocolTestKit`), test target
  `NothingProtocolTests` (deps: `NothingProtocolTestKit`).

- [ ] **Step 2: Write the failing CRC check** in `Checks.swift`:

```swift
import NothingProtocol

public struct CheckResult { public let name: String; public let passed: Bool; public let detail: String
  public init(_ name: String, _ passed: Bool, _ detail: String = "") { self.name = name; self.passed = passed; self.detail = detail } }

public func runChecks() -> [CheckResult] {
    var r: [CheckResult] = []
    // CRC-16/MODBUS of [0x55,0x60,0x01] — golden value captured from current CRC16.
    let crc = crc16([0x55, 0x60, 0x01])
    r.append(CheckResult("crc16/modbus basic", crc == 0x_____, "got \(String(crc, radix: 16))"))
    return r
}
```
(The golden `0x____` is filled in Step 4 after observing the real value, then frozen.)

- [ ] **Step 3: Write `main.swift`** for the verify executable:

```swift
import NothingProtocolTestKit
let results = runChecks()
for x in results { print((x.passed ? "PASS " : "FAIL ") + x.name + (x.detail.isEmpty ? "" : "  [\(x.detail)]")) }
let failed = results.filter { !$0.passed }
print("\n\(results.count - failed.count)/\(results.count) passed")
if !failed.isEmpty { exit(1) }
```

- [ ] **Step 4: Implement `CRC16.swift`** (port of existing, free function + named constants):

```swift
public func crc16(_ bytes: [UInt8]) -> UInt16 {
    let initial: UInt16 = 0xFFFF, poly: UInt16 = 0xA001
    var crc = initial
    for b in bytes { crc ^= UInt16(b); for _ in 0..<8 { crc = (crc & 1) != 0 ? (crc >> 1) ^ poly : crc >> 1 } }
    return crc
}
```
Run `swift run nothing-protocol-verify`, read the printed CRC, freeze it as the golden in Step 2.

- [ ] **Step 5: Verify** `swift build && swift run nothing-protocol-verify` → all PASS, exit 0.

- [ ] **Step 6: XCTest wrapper** `RunChecksTests.swift`:

```swift
import XCTest
import NothingProtocolTestKit
final class RunChecksTests: XCTestCase {
    func testAllChecks() {
        for c in runChecks() { XCTAssertTrue(c.passed, "\(c.name): \(c.detail)") }
    }
}
```

- [ ] **Step 7: Commit** `feat(protocol): package skeleton + CRC16 + test harness`.

---

### Task 2: Command enum + protocol constants

**Files:**
- Create: `NothingProtocol/Sources/NothingProtocol/Command.swift`
- Create: `NothingProtocol/Sources/NothingProtocol/Constants.swift`
- Modify: `NothingProtocol/Sources/NothingProtocolTestKit/Checks.swift` (add checks)

**Interfaces:**
- Produces: `enum Command: UInt16` with all cases from `domain/enums/Commands.swift`,
  plus `var operationID: UInt8 { UInt8(rawValue >> 8) }`.
- Produces: `enum ProtocolConstants` with `magic: UInt8 = 0x55`, header bytes,
  offsets (`operationIDIndex = 7`, `payloadStart = 8`, ...), masks
  (`batteryMask = 0x7F`, `chargingMask = 0x80`), device IDs (`left=0x02`,`right=0x03`,`case=0x04`).

- [ ] **Step 1: Add failing checks** for `Command.GET_BATTERY.rawValue == 0x07C0`,
  `Command.GET_BATTERY.operationID == 0x07`, and one constant
  (`ProtocolConstants.magic == 0x55`).
- [ ] **Step 2: Run** `swift run nothing-protocol-verify` → FAIL (compile error / not found).
- [ ] **Step 3: Implement** `Command.swift` (verbatim raw values from `Commands.swift`)
  and `Constants.swift`.
- [ ] **Step 4: Run** → all PASS.
- [ ] **Step 5: Commit** `feat(protocol): Command enum + named constants`.

---

### Task 3: PacketEncoder (byte-identical to `send`)

**Files:**
- Create: `NothingProtocol/Sources/NothingProtocol/PacketEncoder.swift`
- Modify: `Checks.swift`

**Interfaces:**
- Produces: `enum PacketEncoder { static func encode(command: Command, operationID: UInt8? = nil, payload: [UInt8] = []) -> [UInt8] }`
  — defaults `operationID` to `command.operationID`. Builds
  `[0x55,0x60,0x01, cmdHi, cmdLo, len, 0x00, opID] + payload + [crcLo, crcHi]`.

- [ ] **Step 1: Add failing check:** `encode(.GET_BATTERY)` equals the exact byte
  array (header + CRC). Compute the expected array by hand from the format and the
  CRC of the first bytes; freeze after first run (capture-and-freeze).
- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Implement** `PacketEncoder.encode` (mirror of `send`, big-endian command, clamped length, CRC low/high).
- [ ] **Step 4: Run** → PASS. Add a check with a non-empty payload (e.g. `SET_LATENCY`, payload `[0x01]`).
- [ ] **Step 5: Commit** `feat(protocol): packet encoder`.

---

### Task 4: PacketDecoder + InboundPacket (defensive framing)

**Files:**
- Create: `NothingProtocol/Sources/NothingProtocol/PacketDecoder.swift`
- Create: `NothingProtocol/Sources/NothingProtocol/InboundPacket.swift`
- Modify: `Checks.swift`

**Interfaces:**
- Produces: `struct InboundPacket { let command: UInt16; let operationID: UInt8; let payload: [UInt8]; let raw: [UInt8] }`
- Produces: `enum PacketDecoder { static func decode(_ bytes: [UInt8]) -> InboundPacket? }`
  — returns `nil` if shorter than min header+CRC, magic != 0x55, or CRC mismatch.

- [ ] **Step 1: Add failing checks:** round-trip a known encoded frame → decode →
  command/operationID/payload match; corrupt last CRC byte → `nil`; truncate to 3
  bytes → `nil`; flip byte 0 → `nil`.
- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Implement** `PacketDecoder.decode` with bounds + CRC validation.
- [ ] **Step 4: Run** → PASS.
- [ ] **Step 5: Commit** `feat(protocol): defensive packet decoder`.

---

### Task 5: Typed decoders — battery, latency, in-ear

**Files:**
- Create: `NothingProtocol/Sources/NothingProtocol/Models.swift`
- Create: `NothingProtocol/Sources/NothingProtocol/Decoders.swift`
- Modify: `Checks.swift`

**Interfaces:**
- Produces: `struct BatteryStatus { var left, right, caseLevel: Int?; var leftCharging, rightCharging, caseCharging: Bool }`
- Produces: `enum PayloadDecoder { static func battery(_ frame: [UInt8]) -> BatteryStatus
   ; static func latencyEnabled(_ frame: [UInt8]) -> Bool
   ; static func inEarEnabled(_ frame: [UInt8]) -> Bool }`
  — offsets/masks identical to current `readBattery`/`readLatencyMode`/`readInEarDetection`.

- [ ] **Step 1: Add failing checks** with golden frames built to mirror current
  parsing: e.g. battery frame with device `0x02`/level `0x55`(=85,no charge) and
  `0x03`/`0xC8`(=72,charging); latency `[...,8:0x01]` → true, `0x00` → false; in-ear likewise.
- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Implement** the three decoders, offsets matching the originals exactly.
- [ ] **Step 4: Run** → PASS.
- [ ] **Step 5: Commit** `feat(protocol): battery/latency/in-ear decoders`.

---

### Task 6: Typed decoders — ANC, EQ, firmware, serial, ear-tip, gestures, custom/advanced EQ, enhanced bass, personalized ANC, case LED

**Files:**
- Modify: `Models.swift`, `Decoders.swift`, `Checks.swift`

**Interfaces:**
- Produces (added to `PayloadDecoder`): `anc(_:) -> ANCState?`, `eq(_:) -> EQProfile?`,
  `firmware(_:) -> String`, `serial(_:) -> String`, `earTipResult(_:) -> EarTipResult?`,
  and the remaining `read*` ports, each value-identical to the originals.

- [ ] **Step 1–4 (repeat TDD per decoder):** for each, add a golden-frame check mirroring
  the current `read*` offsets, run → FAIL, port the logic, run → PASS. Group commits
  logically (e.g. one commit per 2–3 decoders).
- [ ] **Step 5: Commit(s)** `feat(protocol): <decoder group>`.

---

### Task 7: CI that runs the codec tests

**Files:**
- Modify: `.github/workflows/swift.yml`

**Interfaces:** none (CI only).

- [ ] **Step 1:** Replace the broken `swift build`/`swift test` steps with a `codec`
  job on `macos-latest`:
```yaml
    - name: Build codec
      run: swift build --package-path NothingProtocol
    - name: Verify (executable harness)
      run: swift run --package-path NothingProtocol nothing-protocol-verify
    - name: XCTest
      run: swift test --package-path NothingProtocol
```
- [ ] **Step 2:** Add a best-effort `app-build` job:
```yaml
    - name: Build app
      run: xcodebuild -project "Nothing X MacOS.xcodeproj" -scheme "Nothing X MacOS" -destination 'platform=macOS' build CODE_SIGNING_ALLOWED=NO
```
  If no **shared** scheme exists, leave this job documented as a follow-up (see spec §8 caveat); do not let it block.
- [ ] **Step 3: Commit** `ci: run NothingProtocol codec tests`.

---

## Self-Review

- **Spec coverage:** §5 protocol → Tasks 2–6; §6 structure → Task 1 targets; §7
  tests → checks in every task; §8 CI → Task 7; §9 success criteria → local verify
  gate each task + Task 7 CI. Covered.
- **Placeholders:** golden CRC/byte values use a documented capture-and-freeze
  method (real value frozen on first run); not vague TODOs.
- **Type consistency:** `crc16`, `Command.operationID`, `PacketEncoder.encode`,
  `PacketDecoder.decode`, `InboundPacket`, `PayloadDecoder.*`, `CheckResult`,
  `runChecks()` used consistently across tasks.
