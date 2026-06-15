import Foundation
#if canImport(FirebaseAuth)
import FirebaseAuth
#endif
#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif
#if canImport(FirebaseStorage)
import FirebaseStorage
#endif

enum ServiceError: LocalizedError {
    case emailAlreadyRegistered
    case invalidCredentials
    case userNotFound
    case eventNotFound
    case hanfuNotFound
    case costumeNotFound
    case postNotFound
    case announcementNotFound
    case rentalNotFound
    case noCurrentUser
    case quotaFull
    case alreadyRegistered
    case costumeUnavailable
    case missingImageData

    var errorDescription: String? {
        switch self {
        case .emailAlreadyRegistered: return "此 Email 已註冊"
        case .invalidCredentials: return "帳號或密碼錯誤"
        case .userNotFound: return "找不到使用者"
        case .eventNotFound: return "找不到活動"
        case .hanfuNotFound: return "找不到漢服資料"
        case .costumeNotFound: return "找不到漢服租借資料"
        case .postNotFound: return "找不到貼文"
        case .announcementNotFound: return "找不到公告"
        case .rentalNotFound: return "找不到借閱紀錄"
        case .noCurrentUser: return "請先登入"
        case .quotaFull: return "活動名額已滿"
        case .alreadyRegistered: return "已報名此活動"
        case .costumeUnavailable: return "此漢服目前不可借用"
        case .missingImageData: return "找不到圖片資料"
        }
    }
}

actor FirebaseService {
    private var database: AppSnapshot
    private var credentials: [String: String]

    init() {
        database = AppSnapshot.sample()
        credentials = [
            "admin@hanfu.com": "Admin1234!",
            "member@hanfu.com": "Member1234!"
        ]
    }

    func snapshot() -> AppSnapshot {
        database
    }

    // MARK: - Authentication

    func register(name: String, studentID: String, email: String, password: String, role: AppRole = .member) async throws -> AppUser {
        let normalizedEmail = clean(email).lowercased()
        guard credentials[normalizedEmail] == nil else { throw ServiceError.emailAlreadyRegistered }

        let user = AppUser(uid: UUID().uuidString, name: clean(name), email: normalizedEmail, studentID: clean(studentID), role: role)
        credentials[normalizedEmail] = password
        database.users.append(user)
        database.currentUser = user
        return user
    }

    func login(email: String, password: String) async throws -> AppUser {
        let normalizedEmail = clean(email).lowercased()
        guard let storedPassword = credentials[normalizedEmail], storedPassword == password else {
            throw ServiceError.invalidCredentials
        }
        guard let user = database.users.first(where: { $0.email == normalizedEmail }) else {
            throw ServiceError.userNotFound
        }
        database.currentUser = user
        return user
    }

    func sendPasswordReset(email: String) async throws -> String {
        let normalizedEmail = clean(email).lowercased()
        guard credentials[normalizedEmail] != nil else { throw ServiceError.userNotFound }
        return "已將密碼重設流程寄送至 \(normalizedEmail)"
    }

    func logout() async {
        database.currentUser = nil
    }

    func updateProfile(name: String, studentID: String, email: String) async throws -> AppUser {
        guard let current = database.currentUser else { throw ServiceError.noCurrentUser }

        let newEmail = clean(email).lowercased()
        guard let index = database.users.firstIndex(where: { $0.uid == current.uid }) else { throw ServiceError.userNotFound }

        if current.email != newEmail {
            if let password = credentials[current.email] {
                credentials[current.email] = nil
                credentials[newEmail] = password
            }
        }

        database.users[index].name = clean(name)
        database.users[index].studentID = clean(studentID)
        database.users[index].email = newEmail

        database.currentUser = database.users[index]
        return database.users[index]
    }

    // MARK: - Events

    func createEvent(title: String, description: String, date: Date, location: String, quota: Int, imageURL: String) async throws -> Event {
        let event = Event(eventID: UUID().uuidString, title: clean(title), description: clean(description), date: date, location: clean(location), quota: quota, imageURL: clean(imageURL), registeredUserIDs: [])
        database.events.insert(event, at: 0)
        return event
    }

    func updateEvent(_ event: Event) async throws -> Event {
        guard let index = database.events.firstIndex(where: { $0.eventID == event.eventID }) else { throw ServiceError.eventNotFound }
        database.events[index] = event
        return event
    }

    func deleteEvent(eventID: String) async throws {
        guard let index = database.events.firstIndex(where: { $0.eventID == eventID }) else { throw ServiceError.eventNotFound }
        database.events.remove(at: index)
    }

    func registerForEvent(eventID: String) async throws -> Event {
        guard let currentUser = database.currentUser else { throw ServiceError.noCurrentUser }
        guard let index = database.events.firstIndex(where: { $0.eventID == eventID }) else { throw ServiceError.eventNotFound }

        var event = database.events[index]
        if event.registeredUserIDs.contains(currentUser.uid) { throw ServiceError.alreadyRegistered }
        guard event.remainingSlots > 0 else { throw ServiceError.quotaFull }

        event.registeredUserIDs.append(currentUser.uid)
        database.events[index] = event
        return event
    }

    func cancelEventRegistration(eventID: String) async throws -> Event {
        guard let currentUser = database.currentUser else { throw ServiceError.noCurrentUser }
        guard let index = database.events.firstIndex(where: { $0.eventID == eventID }) else { throw ServiceError.eventNotFound }

        var event = database.events[index]
        event.registeredUserIDs.removeAll { $0 == currentUser.uid }
        database.events[index] = event
        return event
    }

    // MARK: - Hanfu

    func createHanfu(name: String, dynasty: HanfuDynasty, detail: String, imageURL: String) async throws -> Hanfu {
        let hanfu = Hanfu(hanfuID: UUID().uuidString, name: clean(name), dynasty: dynasty, imageURL: clean(imageURL), detail: clean(detail))
        database.hanfus.insert(hanfu, at: 0)
        return hanfu
    }

    func updateHanfu(_ hanfu: Hanfu) async throws -> Hanfu {
        guard let index = database.hanfus.firstIndex(where: { $0.hanfuID == hanfu.hanfuID }) else { throw ServiceError.hanfuNotFound }
        database.hanfus[index] = hanfu
        return hanfu
    }

    func deleteHanfu(hanfuID: String) async throws {
        guard let index = database.hanfus.firstIndex(where: { $0.hanfuID == hanfuID }) else { throw ServiceError.hanfuNotFound }
        database.hanfus.remove(at: index)
    }

    // MARK: - Costumes

    func createCostume(name: String, size: String, dynasty: HanfuDynasty, imageURL: String, available: Bool) async throws -> Costume {
        let costume = Costume(costumeID: UUID().uuidString, name: clean(name), size: clean(size), dynasty: dynasty, imageURL: clean(imageURL), available: available)
        database.costumes.insert(costume, at: 0)
        return costume
    }

    func updateCostume(_ costume: Costume) async throws -> Costume {
        guard let index = database.costumes.firstIndex(where: { $0.costumeID == costume.costumeID }) else { throw ServiceError.costumeNotFound }
        database.costumes[index] = costume
        return costume
    }

    func deleteCostume(costumeID: String) async throws {
        guard let index = database.costumes.firstIndex(where: { $0.costumeID == costumeID }) else { throw ServiceError.costumeNotFound }
        database.costumes.remove(at: index)
    }

    func borrowCostume(costumeID: String) async throws -> Rental {
        guard let currentUser = database.currentUser else { throw ServiceError.noCurrentUser }
        guard let index = database.costumes.firstIndex(where: { $0.costumeID == costumeID }) else { throw ServiceError.costumeNotFound }
        guard database.costumes[index].available else { throw ServiceError.costumeUnavailable }

        database.costumes[index].available = false
        let rental = Rental(rentalID: UUID().uuidString, userID: currentUser.uid, costumeID: costumeID, rentDate: Date(), returnDate: nil, returned: false)
        database.rentals.insert(rental, at: 0)
        return rental
    }

    func returnCostume(rentalID: String) async throws -> Rental {
        guard let rentalIndex = database.rentals.firstIndex(where: { $0.rentalID == rentalID }) else { throw ServiceError.rentalNotFound }
        guard !database.rentals[rentalIndex].returned else { return database.rentals[rentalIndex] }

        let costumeID = database.rentals[rentalIndex].costumeID
        if let costumeIndex = database.costumes.firstIndex(where: { $0.costumeID == costumeID }) {
            database.costumes[costumeIndex].available = true
        }

        database.rentals[rentalIndex].returned = true
        database.rentals[rentalIndex].returnDate = Date()
        return database.rentals[rentalIndex]
    }

    // MARK: - Posts

    func createPost(content: String, imageURL: String?) async throws -> Post {
        guard let currentUser = database.currentUser else { throw ServiceError.noCurrentUser }
        let post = Post(postID: UUID().uuidString, userID: currentUser.uid, content: clean(content), imageURL: imageURL, likes: 0, likedByUserIDs: [], createdAt: Date())
        database.posts.insert(post, at: 0)
        return post
    }

    func toggleLike(postID: String) async throws -> Post {
        guard let currentUser = database.currentUser else { throw ServiceError.noCurrentUser }
        guard let index = database.posts.firstIndex(where: { $0.postID == postID }) else { throw ServiceError.postNotFound }
        if let likedIndex = database.posts[index].likedByUserIDs.firstIndex(of: currentUser.uid) {
            database.posts[index].likedByUserIDs.remove(at: likedIndex)
        } else {
            database.posts[index].likedByUserIDs.append(currentUser.uid)
        }
        database.posts[index].likes = database.posts[index].likedByUserIDs.count
        return database.posts[index]
    }

    func addComment(postID: String, text: String) async throws -> Comment {
        guard let currentUser = database.currentUser else { throw ServiceError.noCurrentUser }
        guard let post = database.posts.first(where: { $0.postID == postID }) else { throw ServiceError.postNotFound }
        let comment = Comment(commentID: UUID().uuidString, postID: post.postID, userID: currentUser.uid, authorName: currentUser.name, text: clean(text), createdAt: Date())
        database.comments.insert(comment, at: 0)
        return comment
    }

    // MARK: - Announcements

    func createAnnouncement(title: String, content: String) async throws -> Announcement {
        let announcement = Announcement(announcementID: UUID().uuidString, title: clean(title), content: clean(content), createdAt: Date())
        database.announcements.insert(announcement, at: 0)
        return announcement
    }

    func updateAnnouncement(_ announcement: Announcement) async throws -> Announcement {
        guard let index = database.announcements.firstIndex(where: { $0.announcementID == announcement.announcementID }) else { throw ServiceError.announcementNotFound }
        database.announcements[index] = announcement
        return announcement
    }

    func deleteAnnouncement(announcementID: String) async throws {
        guard let index = database.announcements.firstIndex(where: { $0.announcementID == announcementID }) else { throw ServiceError.announcementNotFound }
        database.announcements.remove(at: index)
    }

    // MARK: - Storage

    func uploadImage(data: Data) async throws -> String {
        guard !data.isEmpty else { throw ServiceError.missingImageData }

        #if canImport(FirebaseStorage)
        // Replace this fallback with the real Firebase Storage upload when the package is added.
        #endif

        let fileName = UUID().uuidString + ".jpg"
        return "https://storage.local/\(fileName)"
    }

    // MARK: - Helpers

    private func clean(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func extractEventID(from payload: String) -> String {
        let value = clean(payload)
        if value.lowercased().hasPrefix("event:") {
            return String(value.dropFirst(6))
        }
        return value
    }
}
