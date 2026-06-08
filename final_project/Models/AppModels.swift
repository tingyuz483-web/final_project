import Foundation

enum AppRole: String, Codable, CaseIterable, Identifiable {
    case member = "member"
    case admin = "admin"

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .member: return "會員"
        case .admin: return "管理員"
        }
    }
}

enum HanfuDynasty: String, Codable, CaseIterable, Identifiable {
    case han = "漢朝"
    case tang = "唐朝"
    case song = "宋朝"
    case ming = "明朝"

    var id: String { rawValue }
}

struct AppUser: Identifiable, Codable, Hashable {
    let uid: String
    var name: String
    var email: String
    var studentID: String
    var role: AppRole

    var id: String { uid }
}

struct Event: Identifiable, Codable, Hashable {
    let eventID: String
    var title: String
    var description: String
    var date: Date
    var location: String
    var quota: Int
    var imageURL: String
    var registeredUserIDs: [String]

    var id: String { eventID }
    var remainingSlots: Int { max(quota - registeredUserIDs.count, 0) }
}

struct Hanfu: Identifiable, Codable, Hashable {
    let hanfuID: String
    var name: String
    var dynasty: HanfuDynasty
    var imageURL: String
    var detail: String

    var id: String { hanfuID }
}

struct Costume: Identifiable, Codable, Hashable {
    let costumeID: String
    var name: String
    var size: String
    var dynasty: HanfuDynasty
    var imageURL: String
    var available: Bool

    var id: String { costumeID }
}

struct Post: Identifiable, Codable, Hashable {
    let postID: String
    var userID: String
    var content: String
    var imageURL: String?
    var likes: Int
    var likedByUserIDs: [String]
    var createdAt: Date

    var id: String { postID }
}

struct Comment: Identifiable, Codable, Hashable {
    let commentID: String
    var postID: String
    var userID: String
    var authorName: String
    var text: String
    var createdAt: Date

    var id: String { commentID }
}

struct Rental: Identifiable, Codable, Hashable {
    let rentalID: String
    var userID: String
    var costumeID: String
    var rentDate: Date
    var returnDate: Date?
    var returned: Bool

    var id: String { rentalID }
}

struct Announcement: Identifiable, Codable, Hashable {
    let announcementID: String
    var title: String
    var content: String
    var createdAt: Date

    var id: String { announcementID }
}

struct AppSnapshot: Codable {
    var users: [AppUser]
    var events: [Event]
    var hanfus: [Hanfu]
    var costumes: [Costume]
    var posts: [Post]
    var comments: [Comment]
    var rentals: [Rental]
    var announcements: [Announcement]
    var currentUser: AppUser?

    static func sample() -> AppSnapshot {
        let admin = AppUser(uid: "admin-001", name: "系統管理員", email: "admin@hanfu.com", studentID: "A0000001", role: .admin)
        let user = AppUser(uid: "user-001", name: "王小明", email: "member@hanfu.com", studentID: "B1234567", role: .member)

        let events = [
            Event(
                eventID: UUID().uuidString,
                title: "漢服文化體驗日",
                description: "認識漢服歷史、穿搭與禮儀，並提供現場體驗與拍照區。",
                date: Date().addingTimeInterval(60 * 60 * 24 * 7),
                location: "文化中心 3F",
                quota: 30,
                imageURL: "https://picsum.photos/600/400?event=1",
                registeredUserIDs: [user.uid]
            ),
            Event(
                eventID: UUID().uuidString,
                title: "唐風拍攝工作坊",
                description: "教你如何搭配唐制服飾與攝影構圖，拍出主題感作品。",
                date: Date().addingTimeInterval(60 * 60 * 24 * 14),
                location: "攝影棚 B",
                quota: 20,
                imageURL: "https://picsum.photos/600/400?event=2",
                registeredUserIDs: []
            )
        ]

        let hanfus = [
            Hanfu(hanfuID: UUID().uuidString, name: "曲裾深衣", dynasty: .han, imageURL: "https://picsum.photos/600/600?hanfu=1", detail: "漢代常見深衣樣式，線條簡潔，強調禮制與端莊。"),
            Hanfu(hanfuID: UUID().uuidString, name: "齊胸襦裙", dynasty: .tang, imageURL: "https://picsum.photos/600/600?hanfu=2", detail: "唐代代表性女裝，腰線高、裙襬飄逸，色彩明豔。"),
            Hanfu(hanfuID: UUID().uuidString, name: "褙子襦裙", dynasty: .song, imageURL: "https://picsum.photos/600/600?hanfu=3", detail: "宋代服飾重視素雅與層次，常見褙子與襦裙搭配。"),
            Hanfu(hanfuID: UUID().uuidString, name: "馬面裙", dynasty: .ming, imageURL: "https://picsum.photos/600/600?hanfu=4", detail: "明代高辨識度裙裝，結構清楚，適合搭配立領衫。")
        ]

        let costumes = [
            Costume(costumeID: UUID().uuidString, name: "漢制深衣", size: "M", dynasty: .han, imageURL: "https://picsum.photos/600/600?costume=1", available: true),
            Costume(costumeID: UUID().uuidString, name: "唐風襦裙", size: "L", dynasty: .tang, imageURL: "https://picsum.photos/600/600?costume=2", available: false),
            Costume(costumeID: UUID().uuidString, name: "宋制褙子", size: "S", dynasty: .song, imageURL: "https://picsum.photos/600/600?costume=3", available: true)
        ]

        let posts = [
            Post(postID: UUID().uuidString, userID: user.uid, content: "今天試穿了唐風襦裙，質感很好。", imageURL: "https://picsum.photos/700/500?post=1", likes: 12, likedByUserIDs: [admin.uid, "user-002"], createdAt: Date().addingTimeInterval(-3600 * 3)),
            Post(postID: UUID().uuidString, userID: admin.uid, content: "社團新公告：本週五有漢服講座。", imageURL: nil, likes: 5, likedByUserIDs: [user.uid], createdAt: Date().addingTimeInterval(-3600 * 8))
        ]

        let comments = [
            Comment(commentID: UUID().uuidString, postID: posts[0].postID, userID: admin.uid, authorName: admin.name, text: "很適合你。", createdAt: Date().addingTimeInterval(-3600 * 2))
        ]

        let rentals = [
            Rental(rentalID: UUID().uuidString, userID: user.uid, costumeID: costumes[1].costumeID, rentDate: Date().addingTimeInterval(-3600 * 48), returnDate: nil, returned: false)
        ]

        let announcements = [
            Announcement(announcementID: UUID().uuidString, title: "迎新活動", content: "下週將舉辦新生迎新與漢服體驗。", createdAt: Date().addingTimeInterval(-3600 * 24 * 2))
        ]

        return AppSnapshot(
            users: [admin, user],
            events: events,
            hanfus: hanfus,
            costumes: costumes,
            posts: posts,
            comments: comments,
            rentals: rentals,
            announcements: announcements,
            currentUser: nil
        )
    }
}

extension Date {
    static let appShortFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_TW")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    static let appDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_TW")
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter
    }()

    var appShortString: String {
        Date.appShortFormatter.string(from: self)
    }

    var appDateString: String {
        Date.appDateFormatter.string(from: self)
    }
}

extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
