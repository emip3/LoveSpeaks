import SwiftUI

// MARK: - LoveSpeaks Brand Colors

extension Color {
    static let lsMint    = Color ("Mint")//Color(red: 0.722, green: 0.949, blue: 0.902) // #B8F2E6
    static let lsSky     = Color ("Sky")//Color(red: 0.682, green: 0.851, blue: 0.878) // #AED9E0
    static let lsSalmon  = Color ("Salmon")//(red: 1.000, green: 0.651, blue: 0.620) // #FFA69E
    static let lsCream   = Color ("Cream") //(red: 0.980, green: 0.953, blue: 0.867) // #FAF3DD
    static let lsSlate   = Color ("Slate")//(red: 0.369, green: 0.392, blue: 0.447) // #5E6472

    // Sound Category Colors
    static let lsHungry     = Color ("Hungry")//(red: 1.000, green: 0.612, blue: 0.400) // #FF9C66
    static let lsTired      = Color ("Tired")//(red: 0.784, green: 0.714, blue: 1.000) // #C8B6FF
    static let lsDiscomfort = Color ("Discomfort")//(red: 0.753, green: 0.408, blue: 0.416) // #C0686A
    static let lsBabbling   = Color ("Babbling")//(red: 0.961, green: 0.620, blue: 0.878) // #F59EE0
    static let lsLaughter   = Color ("Laughter")//(red: 0.910, green: 0.816, blue: 0.000) // #E8D000
    static let lsCry        = Color ("Cry")//(red: 0.635, green: 0.824, blue: 1.000) // #A2D2FF
    
    // MARK: - Hex Initializer
    /// Crea un Color desde un string hexadecimal (ej: "FF5733" o "#FF5733")
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}


