import Foundation

public struct NUSModsClient: Sendable {
    public enum Semester: Int, Codable, CaseIterable, Sendable { case sem1 = 1, sem2 = 2, specialTerm1 = 3, specialTerm2 = 4 }
    
    public struct Config: Sendable {
        public let academicYear: String               // e.g., "2025-2026"
        public var baseURL: URL = URL(string: "https://api.nusmods.com/v2/")!
        public init(academicYear: String) { self.academicYear = academicYear }
    }
    
    public let config: Config
    private let http = HTTP()
    private let cache = FileCache(folder: "NUSModsCache")
    
    public init(config: Config) { self.config = config }
    
    // MARK: Lists & lookups
    
    public func fetchModuleList() async throws -> [ModuleListItem] {
        let url = config.baseURL.appendingPathComponent("\(config.academicYear)/moduleList.json")
        return try await getCachedJSON([ModuleListItem].self, url: url, cacheKey: "list-\(config.academicYear)")
    }
    
    public func fetchModuleInfo(moduleCode: String) async throws -> ModuleInfo {
        let url = config.baseURL.appendingPathComponent("\(config.academicYear)/modules/\(moduleCode.uppercased()).json")
        return try await getCachedJSON(ModuleInfo.self, url: url, cacheKey: "info-\(config.academicYear)-\(moduleCode.uppercased())")
    }
    
    public func fetchTimetable(moduleCode: String, semester: Semester) async throws -> [Lesson] {
        let url = config.baseURL.appendingPathComponent("\(config.academicYear)/semesters/\(semester.rawValue)/\(moduleCode.uppercased())/timetable.json")
        return try await getCachedJSON([Lesson].self, url: url, cacheKey: "tt-\(config.academicYear)-S\(semester.rawValue)-\(moduleCode.uppercased())")
    }
    
    public func fetchSemesterData(moduleCode: String, semester: Semester) async throws -> SemesterData {
        let url = config.baseURL.appendingPathComponent("\(config.academicYear)/semesters/\(semester.rawValue)/\(moduleCode.uppercased())/semesterData.json")
        return try await getCachedJSON(SemesterData.self, url: url, cacheKey: "sd-\(config.academicYear)-S\(semester.rawValue)-\(moduleCode.uppercased())")
    }
    
    // MARK: Expansion from weekly slots -> dated sessions
    
    public func expandLessonsToSessions(moduleCode: String,
                                        semester: Semester,
                                        lessons: [Lesson],
                                        calendar: AcademicCalendar) -> [DatedSession] {
        var out: [DatedSession] = []
        for l in lessons {
            let weekday = calendar.weekdayIndex(from: l.day)
            let sh = Int(l.startTime.prefix(2)) ?? 0
            let sm = Int(l.startTime.suffix(2)) ?? 0
            let eh = Int(l.endTime.prefix(2)) ?? 0
            let em = Int(l.endTime.suffix(2)) ?? 0
            
            for w in l.weeks.flattenedWeeks {
                guard let start = calendar.dateFor(week: w, weekday: weekday, hour: sh, minute: sm, semester: semester),
                      let end   = calendar.dateFor(week: w, weekday: weekday, hour: eh, minute: em, semester: semester)
                else { continue }
                out.append(DatedSession(
                    moduleCode: moduleCode.uppercased(),
                    kind: l.lessonType,
                    classNo: l.classNo,
                    start: start,
                    end: end,
                    location: l.venue
                ))
            }
        }
        // De-dupe & sort
        return Array(Set(out)).sorted(by: { $0.start < $1.start })
    }
    
    // MARK: - Helpers
    
    private func getCachedJSON<T: Decodable>(_ type: T.Type, url: URL, cacheKey: String) async throws -> T {
        if let data = cache.read(key: cacheKey), let decoded = try? JSONDecoder().decode(T.self, from: data) {
            return decoded
        }
        let data = try await http.get(url: url)
        cache.write(key: cacheKey, data: data)
        return try JSONDecoder().decode(T.self, from: data)
    }
}

// MARK: - Minimal HTTP + File cache

fileprivate struct HTTP: Sendable {
    func get(url: URL) async throws -> Data {
        let (data, resp) = try await URLSession.shared.data(from: url)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
        return data
    }
}

fileprivate struct FileCache: Sendable {
    let folder: String
    private var dir: URL {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let d = base.appendingPathComponent(folder, isDirectory: true)
        try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        return d
    }
    func write(key: String, data: Data) { try? data.write(to: dir.appendingPathComponent(key)) }
    func read(key: String) -> Data? { try? Data(contentsOf: dir.appendingPathComponent(key)) }
}