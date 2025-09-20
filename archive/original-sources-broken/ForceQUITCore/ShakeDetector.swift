import Foundation
import CoreMotion

public class ShakeDetector: ObservableObject {
    public enum ShakePattern {
        case singleShake
        case doubleShake
        case tripleShake
    }
    
    public struct Configuration {
        public init() {}
    }
    
    public init(configuration: Configuration = Configuration()) {
        
    }
}