# Wiring `NothingProtocol` into the app (Xcode hand-off)

The `NothingProtocol` package on `main` is feature-complete and tested (51 checks,
green on CI). What remains can only be done/verified in Xcode: link the package and
have `NothingServiceImpl` delegate to it instead of parsing bytes inline.

This guide is **phased**. Phase 1 is a small, low-risk change that routes the actual
byte work through the tested codec without touching the rest of the app. Phase 2
(optional, later) removes the now-duplicated types.

> None of the code below has been compiled (no Xcode in the authoring env). Apply it
> in Xcode and use the verification checklist at the end.

---

## 0. Prerequisites & repo hygiene (do these first in Xcode)

1. **Open** `Nothing X MacOS.xcodeproj`. If Xcode shows `Nothing_X_MacOSApp.swift`
   in **red** (missing), it's because the project references it at the project root
   but the file actually lives in `presentation/`. Right-click → *Delete* the red
   reference (Remove Reference, not Move to Trash), then drag the real
   `Nothing X MacOS/presentation/Nothing_X_MacOSApp.swift` back into the group.
2. **Share a scheme** (also greens the CI `app-build` job): *Product → Scheme →
   Manage Schemes…* → tick **Shared** for the "Nothing X MacOS" scheme → commit the
   new file under `Nothing X MacOS.xcodeproj/xcshareddata/xcschemes/`.
3. Add `xcuserdata/` to `.gitignore` (currently only `*.xcuserstate` is ignored).

---

## 1. Add `NothingProtocol` as a local package dependency

1. *File → Add Package Dependencies…* → **Add Local…**
2. Select the `NothingProtocol/` folder in the repo root → **Add Package**.
3. In the target sheet, add the **`NothingProtocol`** library product to the
   **"Nothing X MacOS"** app target → **Add Package**.
4. Confirm it appears under the project's **Package Dependencies** and in the target's
   **Frameworks, Libraries, and Embedded Content**.

Build once (⌘B) — nothing uses it yet, so it should still compile.

---

## 2. Phase 1 — delegate byte work in `NothingServiceImpl`

At the top of `Nothing X MacOS/framework/NothingServiceImpl.swift`:

```swift
import NothingProtocol
```

### Name-clash note

The package deliberately mirrors several app types. Some names are identical, some
differ:

| Concept            | App type        | Package type      |
|--------------------|-----------------|-------------------|
| Command codes      | `Commands`      | `Command`         |
| ANC mode           | `ANC`           | `ANCMode`         |
| EQ preset          | `EQProfiles`    | `EQProfile`       |
| SKU                | `SKU`           | `SKU` (clash)     |
| Codename           | `Codenames`     | `Codenames` (clash)|
| Device side        | `DeviceType`    | `DeviceType` (clash)|
| Gesture            | `GestureType`   | `GestureType` (clash)|
| Capabilities       | `DeviceCapabilities` | `DeviceCapabilities` (clash)|

In Phase 1 we only touch byte parsing/encoding, which uses the **non-clashing**
package API (`PacketEncoder`, `PacketDecoder`, `PayloadDecoder`, `crc16`). Where the
package returns `ANCMode`/`EQProfile`, map them to the app's `ANC`/`EQProfiles` by raw
value (identical raw values). Leave the clashing types alone until Phase 2.

### 2a. Encoding — replace `send(...)`

Before:
```swift
private func send(command: UInt16, operationID: UInt8, payload: [UInt8] = []) {
    var header: [UInt8] = [0x55, 0x60, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00]
    header[7] = UInt8(operationID)
    let commandBytes = withUnsafeBytes(of: command.bigEndian) { Array($0) }
    header[3] = commandBytes[0]; header[4] = commandBytes[1]
    header[5] = UInt8(clamping: payload.count)
    header.append(contentsOf: payload)
    let crc = CRC16.crc16(buffer: header)
    header.append(UInt8(crc & 0xFF)); header.append(UInt8((crc >> 8) & 0xFF))
    bluetoothManager.send(data: &header, length: UInt16(header.count))
}
```

After (delegates to the tested encoder; `command` is the raw UInt16 already):
```swift
private func send(command: UInt16, operationID: UInt8, payload: [UInt8] = []) {
    guard let cmd = NothingProtocol.Command(rawValue: command) else {
        log.error("Unknown command 0x\(String(command, radix: 16))")
        return
    }
    var frame = PacketEncoder.encode(command: cmd, operationID: operationID, payload: payload)
    bluetoothManager.send(data: &frame, length: UInt16(frame.count))
}
```

### 2b. Decoding — route `read*` through `PayloadDecoder`

The decoders take the full received `rawData` (same absolute offsets). Map the typed
result into the existing `nothingDevice` model. Examples:

```swift
// readLatencyMode(hexArray:)  →
let latencyOn = PayloadDecoder.latencyEnabled(rawData)

// readInEarDetection(hexArray:)  →
let inEarOn = PayloadDecoder.inEarEnabled(rawData)

// readBattery(hexString:)  →
let b = PayloadDecoder.battery(rawData)
nothingDevice?.isLeftConnected  = b.left  != nil
nothingDevice?.isRightConnected = b.right != nil
nothingDevice?.isCaseConnected  = b.caseLevel != nil
if let l = b.left  { nothingDevice?.leftBattery  = l; nothingDevice?.isLeftCharging  = b.leftCharging }
if let r = b.right { nothingDevice?.rightBattery = r; nothingDevice?.isRightCharging = b.rightCharging }
if let c = b.caseLevel { nothingDevice?.caseBattery = c; nothingDevice?.isCaseCharging = b.caseCharging }

// readEQ(hexArray:) → app EQProfiles via raw value
let eq = EQProfiles(rawValue: PayloadDecoder.eqProfile(rawData).rawValue) ?? .BALANCED

// readANC(hexArray:) → app ANC via raw value
if let m = PayloadDecoder.ancMode(rawData) { nothingDevice?.anc = ANC(rawValue: m.rawValue) ?? nothingDevice?.anc }

// firmware / serial
let firmware = PayloadDecoder.firmware(rawData)
let serial   = PayloadDecoder.serial(rawData)

// earTip / enhancedBass / personalizedANC / advancedEQ / caseLED / customEQ / gestures
// all have direct PayloadDecoder.* equivalents returning the structs in the package.
```

Do this one `read*` at a time, building after each. Keep each function's
model-mapping identical to the original switch logic.

### 2c. Optional — validate frames on receive

In the RFCOMM data handler you can now reject malformed frames cheaply:
```swift
guard PacketDecoder.decode(rawData) != nil else { log.warning("Bad frame"); return }
```
(Only if the device sends complete CRC'd frames per callback — verify against real
traffic before enabling, since the current code tolerates partial reads.)

---

## 3. Verification checklist (in Xcode)

- [ ] ⌘B builds with no errors/warnings from the new code.
- [ ] Run the app, connect your earbuds.
- [ ] Battery L/R/Case shows correctly (exercises `battery`).
- [ ] Toggle ANC / EQ / low-latency / in-ear and confirm they take effect
      (exercises `encode` + the relevant decoders).
- [ ] Device is identified (name/model correct) and the right feature set shows
      (exercises identification + capabilities).
- [ ] CI `app-build` job goes green once a shared scheme is committed.

---

## 4. Phase 2 (optional, later) — remove duplication

Once Phase 1 is verified, delete the app copies whose package equivalents have
**identical names and raw values**, and let references resolve to the package:

- Delete `framework/utils/CRC16.swift`, `framework/utils/SKUUtil.swift`,
  `domain/enums/device/SKU.swift`, `domain/enums/device/Codenames.swift`,
  `domain/enums/device/DeviceCapabilities.swift`, `domain/enums/device/DeviceType.swift`,
  `domain/enums/GestureType.swift`.
- Add `import NothingProtocol` to the files that referenced them (entities, DTOs,
  ViewModels, Views).
- Keep app-only domain types that the package intentionally renamed (`ANC`,
  `EQProfiles`, `Commands`) unless you also migrate every call site.
- Build and re-run the full checklist.

This is a wider, mechanical change — do it as its own PR so the diff is reviewable.
