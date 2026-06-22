# NothingProtocol

A standalone, pure-Foundation Swift package implementing the Nothing / CMF earbud
RFCOMM protocol codec, extracted from the app's `NothingServiceImpl` so it can be
tested in isolation.

No external dependencies. No SwiftUI / IOBluetooth / AppKit. Builds and tests on
any Swift 5.7+ toolchain (including Command Line Tools, for the executable
harness).

## Run the tests

```bash
# Toolchain-agnostic harness (works without Xcode):
swift run --package-path NothingProtocol nothing-protocol-verify

# Idiomatic XCTest (requires the Xcode toolchain):
swift test --package-path NothingProtocol
```

Both runners consume the same single source of test cases,
`NothingProtocolTestKit.runChecks()`.

## What it covers

- **CRC-16/MODBUS** (`crc16`).
- **Framing:** `PacketEncoder.encode` (byte-identical to the app's `send`) and
  `PacketDecoder.decode` (validates magic / length / CRC; returns `nil` on
  malformed input instead of crashing).
- **Typed decoders** (`PayloadDecoder`): battery, latency, in-ear, ANC, EQ,
  firmware, serial, ear-tip result, advanced EQ, enhanced bass, personalized ANC,
  case LED.

Decoders mirror the app's `read*` offsets exactly (extraction, not redesign); the
only added behavior is bounds-safety.

## Deferred to the app-integration step

These are intentionally **not** ported yet (higher coupling, lower ROI for a
standalone codec):

- **Custom EQ** float decoding (`readCustomEQ` / `decodeFloatFromEQ`) — 4-byte
  float fields at offsets 14/27/40.
- **Gesture parsing** (`readGestures`) — depends on the app's `DeviceType` and
  `GestureType` enums.

They will be added (with the same golden-vector test approach) when the package is
wired into `NothingServiceImpl`.
