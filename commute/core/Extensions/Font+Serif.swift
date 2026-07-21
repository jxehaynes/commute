import SwiftUI

extension Font {
    /// Playfair Display italic when bundled; otherwise SF Pro italic.
    static func playfairItalic(size: CGFloat) -> Font {
        if UIFont(name: "PlayfairDisplay-Italic", size: size) != nil {
            Font.custom("PlayfairDisplay-Italic", size: size)
        } else {
            Font.system(size: size, weight: .regular, design: .serif).italic()
        }
    }
}
