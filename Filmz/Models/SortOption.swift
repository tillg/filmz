enum SortOption {
    case title, year, dateAdded
    
    var title: String {
        switch self {
        case .title: return "Title"
        case .year: return "Year"
        case .dateAdded: return "Date Added"
        }
    }
    
    static func sort(_ myFilms: [MyFilm], by option: SortOption) -> [MyFilm] {
        myFilms.sorted { (first: MyFilm, second:MyFilm) -> Bool in
            return true
//            switch option {
//            case .title:
//                return first.title.lowercased() < second.title.lowercased()
//            case .year:
//                return first.year > second.year // Newest first
//            case .dateAdded:
//                // If both have valid dates (more than 5 seconds old)
//                if abs(first.dateAdded.timeIntervalSinceNow) > 5 && abs(second.dateAdded.timeIntervalSinceNow) > 5 {
//                    return first.dateAdded > second.dateAdded // Most recent first
//                }
//                // If only first has valid date, it goes first
//                if abs(first.dateAdded.timeIntervalSinceNow) > 5 {
//                    return true
//                }
//                // If only second has valid date, it goes first
//                if abs(second.dateAdded.timeIntervalSinceNow) > 5 {
//                    return false
//                }
//                // If neither has valid date, sort by title
//                return first.title.lowercased() < second.title.lowercased()
//            }
        }
    }
} 
