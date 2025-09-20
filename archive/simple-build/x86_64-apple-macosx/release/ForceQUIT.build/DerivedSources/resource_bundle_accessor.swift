import Foundation

extension Foundation.Bundle {
    static let module: Bundle = {
        let mainPath = Bundle.main.bundleURL.appendingPathComponent("ForceQUIT_ForceQUIT.bundle").path
        let buildPath = "/Volumes/apfsRAID/Development/Projects/01_High_Completion/02-ForceQUIT/simple-build/x86_64-apple-macosx/release/ForceQUIT_ForceQUIT.bundle"

        let preferredBundle = Bundle(path: mainPath)

        guard let bundle = preferredBundle ?? Bundle(path: buildPath) else {
            // Users can write a function called fatalError themselves, we should be resilient against that.
            Swift.fatalError("could not load resource bundle: from \(mainPath) or \(buildPath)")
        }

        return bundle
    }()
}