import Foundation
import SwiftUI
import Combine

@MainActor
final class AppViewModel: ObservableObject {
    @Published private(set) var snapshot: AppSnapshot
    private let service: FirebaseService

    init(service: FirebaseService = FirebaseService()) {
        self.service = service
        self.snapshot = AppSnapshot.sample()
        Task {
            await refresh()
        }
    }

    func refresh() async {
        snapshot = await service.snapshot()
    }

    var currentUser: AppUser? {
        snapshot.currentUser
    }

    var isAdmin: Bool {
        currentUser?.role == .admin
    }

    var registeredEvents: [Event] {
        guard let userID = currentUser?.uid else { return [] }
        return snapshot.events.filter { $0.registeredUserIDs.contains(userID) }
    }

    var myRentals: [Rental] {
        guard let userID = currentUser?.uid else { return [] }
        return snapshot.rentals.filter { $0.userID == userID }
    }

    var myPosts: [Post] {
        guard let userID = currentUser?.uid else { return [] }
        return snapshot.posts.filter { $0.userID == userID }
    }

    var myComments: [Comment] {
        guard let userID = currentUser?.uid else { return [] }
        return snapshot.comments.filter { $0.userID == userID }
    }

    var commentsByPostID: [String: [Comment]] {
        Dictionary(grouping: snapshot.comments, by: { $0.postID })
    }

    func register(name: String, studentID: String, email: String, password: String, role: AppRole = .member) async throws -> AppUser {
        let user = try await service.register(name: name, studentID: studentID, email: email, password: password, role: role)
        await refresh()
        return user
    }

    func login(email: String, password: String) async throws -> AppUser {
        let user = try await service.login(email: email, password: password)
        await refresh()
        return user
    }

    func sendPasswordReset(email: String) async throws -> String {
        try await service.sendPasswordReset(email: email)
    }

    func logout() async {
        await service.logout()
        await refresh()
    }

    func updateProfile(name: String, studentID: String, email: String) async throws -> AppUser {
        let user = try await service.updateProfile(name: name, studentID: studentID, email: email)
        await refresh()
        return user
    }

    func createEvent(title: String, description: String, date: Date, location: String, quota: Int, imageURL: String) async throws -> Event {
        let event = try await service.createEvent(title: title, description: description, date: date, location: location, quota: quota, imageURL: imageURL)
        await refresh()
        return event
    }

    func updateEvent(_ event: Event) async throws -> Event {
        let updated = try await service.updateEvent(event)
        await refresh()
        return updated
    }

    func deleteEvent(eventID: String) async throws {
        try await service.deleteEvent(eventID: eventID)
        await refresh()
    }

    func registerForEvent(eventID: String) async throws -> Event {
        let event = try await service.registerForEvent(eventID: eventID)
        await refresh()
        return event
    }

    func cancelEventRegistration(eventID: String) async throws -> Event {
        let event = try await service.cancelEventRegistration(eventID: eventID)
        await refresh()
        return event
    }

    func createHanfu(name: String, dynasty: HanfuDynasty, detail: String, imageURL: String) async throws -> Hanfu {
        let hanfu = try await service.createHanfu(name: name, dynasty: dynasty, detail: detail, imageURL: imageURL)
        await refresh()
        return hanfu
    }

    func updateHanfu(_ hanfu: Hanfu) async throws -> Hanfu {
        let updated = try await service.updateHanfu(hanfu)
        await refresh()
        return updated
    }

    func deleteHanfu(hanfuID: String) async throws {
        try await service.deleteHanfu(hanfuID: hanfuID)
        await refresh()
    }

    func createCostume(name: String, size: String, dynasty: HanfuDynasty, imageURL: String, available: Bool) async throws -> Costume {
        let costume = try await service.createCostume(name: name, size: size, dynasty: dynasty, imageURL: imageURL, available: available)
        await refresh()
        return costume
    }

    func updateCostume(_ costume: Costume) async throws -> Costume {
        let updated = try await service.updateCostume(costume)
        await refresh()
        return updated
    }

    func deleteCostume(costumeID: String) async throws {
        try await service.deleteCostume(costumeID: costumeID)
        await refresh()
    }

    func borrowCostume(costumeID: String) async throws -> Rental {
        let rental = try await service.borrowCostume(costumeID: costumeID)
        await refresh()
        return rental
    }

    func returnCostume(rentalID: String) async throws -> Rental {
        let rental = try await service.returnCostume(rentalID: rentalID)
        await refresh()
        return rental
    }

    func createPost(content: String, imageURL: String?) async throws -> Post {
        let post = try await service.createPost(content: content, imageURL: imageURL)
        await refresh()
        return post
    }

    func likePost(postID: String) async throws -> Post {
        let post = try await service.toggleLike(postID: postID)
        await refresh()
        return post
    }

    func hasLiked(postID: String) -> Bool {
        guard let userID = currentUser?.uid else { return false }
        return snapshot.posts.first(where: { $0.postID == postID })?.likedByUserIDs.contains(userID) == true
    }

    func addComment(postID: String, text: String) async throws -> Comment {
        let comment = try await service.addComment(postID: postID, text: text)
        await refresh()
        return comment
    }

    func createAnnouncement(title: String, content: String) async throws -> Announcement {
        let announcement = try await service.createAnnouncement(title: title, content: content)
        await refresh()
        return announcement
    }

    func updateAnnouncement(_ announcement: Announcement) async throws -> Announcement {
        let updated = try await service.updateAnnouncement(announcement)
        await refresh()
        return updated
    }

    func deleteAnnouncement(announcementID: String) async throws {
        try await service.deleteAnnouncement(announcementID: announcementID)
        await refresh()
    }

    func uploadImageData(_ data: Data) async throws -> String {
        try await service.uploadImage(data: data)
    }
}
