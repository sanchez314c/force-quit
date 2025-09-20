import Foundation
import Speech

public class VoiceCommandHandler: ObservableObject {
    public enum VoiceCommand {
        case forceQuit
        case cancel
    }
    
    public struct Configuration {
        public init() {}
    }
    
    public init(configuration: Configuration = Configuration()) {
        
    }
}