import Foundation

/// Maps an exact SKU to its model family. Ported verbatim from the app's
/// `SKUUtil.codenameFromSKU`.
public func codenameFromSKU(sku: SKU) -> Codenames {
    switch sku {
    case .EAR_1_WHITE, .EAR_1_BLACK, .EAR_1_WHITE_DUPLICATE, .EAR_1_BLACK_DUPLICATE,
         .EAR_1_BLACK_ALTERNATE, .EAR_1_WHITE_ALTERNATE, .EAR_1_BLACK_ANOTHER, .EAR_1_BLACK_FINAL:
        return .ONE
    case .EAR_STICK_1, .EAR_STICK_2, .EAR_STICK_3:
        return .STICKS
    case .EAR_2_WHITE_1, .EAR_2_WHITE_2, .EAR_2_WHITE_3, .EAR_2_BLACK_1, .EAR_2_BLACK_2, .EAR_2_BLACK_3:
        return .TWO
    case .CORSOLA_BLACK_1, .CORSOLA_BLACK_2, .CORSOLA_WHITE_1, .CORSOLA_WHITE_2, .CORSOLA_ORANGE_1, .CORSOLA_ORANGE_2:
        return .CORSOLA
    case .DONPHAN_BLACK_1, .DONPHAN_BLACK_2, .DONPHAN_WHITE_1, .DONPHAN_WHITE_2, .DONPHAN_ORANGE_1, .DONPHAN_ORANGE_2:
        return .DONPHAN
    case .ESPEON_BLACK_1, .ESPEON_WHITE_1, .ESPEON_ORANGE_1, .ESPEON_BLUE_1, .ESPEON_BLUE_2,
         .ESPEON_ORANGE_2, .ESPEON_WHITE_2, .ESPEON_BLACK_3:
        return .ESPEON
    case .FLAFFY_WHITE:
        return .FLAFFY
    case .CROBAT_ORANGE, .CROBAT_WHITE, .CROBAT_BLACK_1, .CROBAT_BLACK_2, .CROBAT_WHITE_2, .CROBAT_ORANGE_2:
        return .CROBAT
    case .CLEFFA_BLACK_1, .CLEFFA_WHITE_1, .CLEFFA_YELLOW_1, .CLEFFA_BLACK_2, .CLEFFA_WHITE_2,
         .CLEFFA_YELLOW_2, .CLEFFA_BLACK_3, .CLEFFA_WHITE_3, .CLEFFA_YELLOW_3:
        return .CLEFFA
    case .ENTEI_BLACK_1, .ENTEI_WHITE_1, .ENTEI_BLACK_2, .ENTEI_WHITE_2, .ENTEI_BLACK_3, .ENTEI_WHITE_3:
        return .TWOS
    case .EAR3_1, .EAR3_2:
        return .EAR3
    case .GIRAFARIG_BLACK, .GIRAFARIG_GREEN, .GIRAFARIG_ORANGE:
        return .GIRAFARIG
    case .GLIGAR_WHITE, .GLIGAR_BLUE:
        return .GLIGAR
    case .HOOTHOOT_BLACK, .HOOTHOOT_WHITE, .HOOTHOOT_ORANGE:
        return .HOOTHOOT
    case .ELEKID_BLACK, .ELEKID_GREY:
        return .ELEKID
    case .UNKNOWN:
        return .UNKNOWN
    }
}

/// Ported verbatim from `SKUUtil.skuFromFirmware`.
public func skuFromFirmware(firmware: String) -> SKU {
    let parts = firmware.split(separator: ".")
    if parts.count > 1 && parts[1] == "6700" {
        return SKU.EAR_1_WHITE
    }
    return SKU.UNKNOWN
}

/// Ported verbatim from `SKUUtil.skuFromSerial`.
public func skuFromSerial(serial: String) -> SKU {
    if serial.isEmpty {
        return SKU.UNKNOWN
    }

    let headSerial = String(serial.prefix(2)) // first two characters

    if serial == "12345678901234567" {
        return SKU.EAR_1_WHITE
    }

    if headSerial == "MA" {
        let year = String(serial.prefix(8).suffix(2))
        if year == "22" || year == "23" {
            return SKU.EAR_STICK_1            // Ear (stick)
        } else if year == "24" {
            return SKU.FLAFFY_WHITE           // Ear (open) — TODO: distinguish both
        }
    } else if headSerial == "SH" || headSerial == "13" {
        if let sku = SKU(rawValue: String(serial.prefix(6).suffix(2))) {
            return sku
        }
    }

    return SKU.UNKNOWN
}

/// Ported verbatim from `SKUUtil.codenameFromDeviceName`. Order matters: more
/// specific names are matched before more general ones.
public func codenameFromDeviceName(name: String) -> Codenames {
    let lowered = name.lowercased()
    if lowered.contains("ear (1)") {
        return .ONE
    } else if lowered.contains("ear stick") {
        return .STICKS
    } else if lowered.contains("ear (2s)") {
        return .CLEFFA
    } else if lowered.contains("ear (2)") {
        return .TWO
    } else if lowered.contains("ear (a)") {
        return .CORSOLA
    } else if lowered.contains("ear (3)") {
        return .EAR3
    } else if lowered.contains("ear (open)") {
        return .FLAFFY
    } else if lowered.contains("cmf buds pro 2") || lowered.contains("buds pro 2") {
        // CMF Buds Pro 2 — added support (the app currently returns UNKNOWN here).
        // PROVISIONAL mapping to ESPEON (internal model reported as B172; Gadgetbridge
        // drives it with the Nothing Ear 2 profile, i.e. same RFCOMM protocol).
        // Confirm against a real unit's serial/codename — see README.
        return .ESPEON
    } else if lowered.contains("cmf buds 2 plus") || lowered.contains("buds 2 plus") {
        return .GLIGAR
    } else if lowered.contains("cmf buds 2a") || lowered.contains("buds 2a") {
        return .HOOTHOOT
    } else if lowered.contains("cmf buds 2") || lowered.contains("buds 2") {
        return .GIRAFARIG
    } else if lowered.contains("headphone (1)") || lowered.contains("headphone(1)") {
        return .ELEKID
    }
    return .UNKNOWN
}
