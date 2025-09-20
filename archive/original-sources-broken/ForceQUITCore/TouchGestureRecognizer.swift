import Foundation
import AppKit

public class TouchGestureRecognizer: ObservableObject {
    public enum GestureType {
        case threeFingerSwipe
        case fourFingerTap
        
        var systemAction: SystemAction {
            switch self {
            case .threeFingerSwipe: return .showOverview
            case .fourFingerTap: return .forceQuit
            }
        }
    }
    
    public enum SystemAction {
        case showOverview
        case forceQuit
    }
    
    public struct Configuration {
        public init() {}
    }
    
    public init(configuration: Configuration = Configuration()) {
        
    }
}