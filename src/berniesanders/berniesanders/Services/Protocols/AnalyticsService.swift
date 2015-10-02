import Foundation

public protocol AnalyticsService {
    func trackCustomEventWithName(name: String)
    func trackContentViewWithName(name: String, type: AnalyticsServiceContentType, id: String)
}

public enum AnalyticsServiceContentType : String, Printable {
    case NewsItem = "News Item"
    
    public var description: String {
        return self.rawValue
    }
}

