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
- **Device identification** (`skuFromSerial`, `skuFromFirmware`,
  `codenameFromDeviceName`, `codenameFromSKU`) and the **capability matrix**
  (`DeviceCapabilities.capabilities(for:)`), keyed by `Codenames`. This is how the
  app derives the model family and decides which features to expose.

Decoders and identification mirror the app's logic exactly (extraction, not
redesign); the only added behavior is bounds-safety.

### CMF Buds Pro 2 (provisional)

`CMF Buds Pro 2` is recognized by Bluetooth name and mapped **provisionally** to
`ESPEON` (`B172`). Rationale: its internal model has been reported as B172, and
Gadgetbridge drives it with the Nothing Ear 2 profile (same RFCOMM protocol), so the
existing encoders/decoders apply; `ESPEON` already carries a rich capability profile.

**This mapping is unverified** (done without a physical unit). To confirm/correct it:
connect the buds and check the codename/serial the app logs (`NXLogger`,
`.bluetooth`/`.persistence`). If the serial yields a different SKU, or the logged
codename differs, update `codenameFromDeviceName` (and add the serial's SKU code to
`SKU` / `codenameFromSKU`). A test pins the current mapping.

Custom EQ float decoding (`eqFloat` / `customEQ`) and gesture parsing
(`gestures`, with `DeviceType` / `GestureType`) are included.

## Remaining: app integration

The package is feature-complete for the current protocol. What's left is wiring it
into the app (needs Xcode): add `NothingProtocol` as a local package dependency to
the Xcode project, then have `NothingServiceImpl` delegate to it and delete the
duplicated inline parsing / enums.
