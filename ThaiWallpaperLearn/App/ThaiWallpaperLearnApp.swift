import SwiftUI
import CoreText

@main
struct ThaiWallpaperLearnApp: App {
    init() {
        Self.registerBundledFonts()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }

    /// Caladea ships as a bundled resource; the Info.plist is generated from
    /// build settings (no UIAppFonts key), so register the faces by hand.
    private static func registerBundledFonts() {
        for name in ["Caladea-Regular", "Caladea-Bold"] {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else {
                NSLog("Fonts: %@ missing from bundle", name)
                continue
            }
            var error: Unmanaged<CFError>?
            if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
                NSLog("Fonts: failed to register %@: %@", name,
                      String(describing: error?.takeRetainedValue()))
            }
        }
    }
}
