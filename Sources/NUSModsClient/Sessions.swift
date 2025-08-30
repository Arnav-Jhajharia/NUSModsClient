import Foundation

public struct DatedSession: Hashable, Identifiable, Sendable {
    public let moduleCode: String
    public let kind: String  // Use raw string instead of enum
    public let classNo: String
    public let start: Date
    public let end: Date
    public let location: String?
    
    public var id: String { "\(moduleCode)-\(kind)-\(classNo)-\(start.timeIntervalSince1970)" }
    
    public init(moduleCode: String, kind: String, classNo: String, start: Date, end: Date, location: String?) {
        self.moduleCode = moduleCode
        self.kind = kind
        self.classNo = classNo
        self.start = start
        self.end = end
        self.location = location
    }
}