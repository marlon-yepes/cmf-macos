/// Model family ("codename" — Nothing's internal B-codes). Many SKUs collapse to
/// one codename. Ported verbatim from the app's `domain/enums/device/Codenames.swift`.
public enum Codenames: String, Codable {
    case UNKNOWN = "0000"
    case ONE = "B181"        // Ear (1)
    case STICKS = "B157"     // Ear (stick)
    case TWO = "B155"        // Ear (2)
    case CORSOLA = "B163"    // Ear (a)
    case TWOS = "B171"       // Ear (2024)
    case ESPEON = "B172"
    case DONPHAN = "B168"
    case FLAFFY = "B174"     // Ear (open)
    case CLEFFA = "B162"     // Ear (2s)
    case CROBAT = "B164"
    case EAR3 = "B173"       // Ear (3)
    case GIRAFARIG = "B179"  // CMF Buds 2
    case GLIGAR = "B184"     // CMF Buds 2 Plus
    case HOOTHOOT = "B185"   // CMF Buds 2a
    case ELEKID = "B170"     // Nothing Headphone (1)
}
