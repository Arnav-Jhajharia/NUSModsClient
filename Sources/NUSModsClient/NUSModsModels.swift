import Foundation

public struct ModuleListItem: Codable, Hashable, Sendable {
    public let moduleCode: String
    public let title: String
}

public struct ModuleInfo: Codable, Hashable, Sendable {
    public let moduleCode: String
    public let title: String
    public let description: String?
    public let moduleCredit: String?
    public let semesters: [Int]?
}

public struct SemesterData: Codable, Hashable, Sendable {
    public let semester: Int
    public let examDate: String?
    public let examDuration: Int?
}

// Weekly slot (not dated yet)
public struct Lesson: Codable, Hashable, Sendable {
    public let classNo: String
    public let day: String           // "Monday"
    public let startTime: String     // "HHmm"
    public let endTime: String       // "HHmm"
    public let lessonType: String    // "Lecture", "Tutorial", etc.
    public let venue: String?
    public let weeks: Weeks
}

// Weeks can be [Int] or array of objects with ranges and intervals.
public enum Weeks: Codable, Hashable, Sendable {
    case ints([Int])
    case objects([WeekObject])
    
    public struct WeekObject: Codable, Hashable, Sendable {
        public let start: Int
        public let end: Int
        public let weekInterval: Int?
        public let weeks: [Int]?
    }
    
    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let ints = try? c.decode([Int].self) { self = .ints(ints); return }
        if let objs = try? c.decode([WeekObject].self) { self = .objects(objs); return }
        throw DecodingError.typeMismatch(Weeks.self, .init(codingPath: decoder.codingPath, debugDescription: "Unsupported weeks format"))
    }
    
    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .ints(let arr): try c.encode(arr)
        case .objects(let arr): try c.encode(arr)
        }
    }
    
    public var flattenedWeeks: [Int] {
        switch self {
        case .ints(let arr):
            return Array(Set(arr)).sorted()
        case .objects(let arr):
            var out = Set<Int>()
            for o in arr {
                if let ws = o.weeks {
                    for w in ws { out.insert(w) }
                } else {
                    let step = o.weekInterval ?? 1
                    for w in stride(from: o.start, through: o.end, by: step) { out.insert(w) }
                }
            }
            return Array(out).sorted()
        }
    }
}