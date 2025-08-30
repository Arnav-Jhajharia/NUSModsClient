import Foundation

public struct AcademicCalendar: Sendable {
    public struct SemesterWindow: Sendable {
        public let week1Start: Date   // Monday of Week 1
        public let recessWeek: Int?   // e.g., 7
        public let readingWeek: Int?  // e.g., 13
        public let holidayDates: Set<Date> // dates at start-of-day
        
        public init(week1Start: Date, recessWeek: Int?, readingWeek: Int?, holidayDates: Set<Date> = []) {
            func sod(_ d: Date) -> Date { Calendar(identifier: .gregorian).startOfDay(for: d) }
            self.week1Start = week1Start
            self.recessWeek = recessWeek
            self.readingWeek = readingWeek
            self.holidayDates = Set(holidayDates.map(sod))
        }
    }
    
    public let sem1: SemesterWindow
    public let sem2: SemesterWindow
    public let st1: SemesterWindow?
    public let st2: SemesterWindow?
    
    private let cal = Calendar(identifier: .gregorian)
    
    public init(sem1: SemesterWindow, sem2: SemesterWindow, st1: SemesterWindow? = nil, st2: SemesterWindow? = nil) {
        self.sem1 = sem1; self.sem2 = sem2; self.st1 = st1; self.st2 = st2
    }
    
    public func dateFor(week: Int, weekday: Int, hour: Int, minute: Int, semester: NUSModsClient.Semester) -> Date? {
        let w = windowFor(semester: semester)
        if week == w.recessWeek || week == w.readingWeek { return nil }
        guard week >= 1 else { return nil }
        let daysOffset = (week - 1) * 7 + (weekday - 2) // Mon=2
        guard let date = cal.date(byAdding: .day, value: daysOffset, to: w.week1Start) else { return nil }
        let withTime = cal.date(bySettingHour: hour, minute: minute, second: 0, of: date)!
        if w.holidayDates.contains(cal.startOfDay(for: withTime)) { return nil }
        return withTime
    }
    
    public func weekdayIndex(from dayString: String) -> Int {
        switch dayString.lowercased() {
        case "monday": return 2
        case "tuesday": return 3
        case "wednesday": return 4
        case "thursday": return 5
        case "friday": return 6
        case "saturday": return 7
        case "sunday": return 1
        default: return 2
        }
    }
    
    private func windowFor(semester: NUSModsClient.Semester) -> SemesterWindow {
        switch semester {
        case .sem1: return sem1
        case .sem2: return sem2
        case .specialTerm1: return st1 ?? sem1
        case .specialTerm2: return st2 ?? sem2
        }
    }
}