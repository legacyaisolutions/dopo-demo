import Foundation
import Combine

@MainActor
class NotificationManager: ObservableObject {
    @Published var notifications: [DopoNotification] = []
    @Published var unreadCount: Int = 0
    @Published var isLoading = false

    private var pollTimer: Timer?
    private var token: String?

    func start(token: String) {
        self.token = token
        Task { await fetchNotifications() }
        startPolling()
    }

    func stop() {
        pollTimer?.invalidate()
        pollTimer = nil
        token = nil
        notifications = []
        unreadCount = 0
    }

    // MARK: - Polling

    private func startPolling() {
        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.pollUnreadCount()
            }
        }
    }

    private func pollUnreadCount() async {
        guard let token else { return }
        do {
            let response = try await APIClient.shared.fetchNotifications(token: token, limit: 1)
            unreadCount = response.unreadCount
        } catch {
            // Silent failure for background polling
        }
    }

    // MARK: - Full fetch

    func fetchNotifications() async {
        guard let token else { return }
        isLoading = true
        do {
            let response = try await APIClient.shared.fetchNotifications(token: token, limit: 20)
            notifications = response.notifications
            unreadCount = response.unreadCount
        } catch {
            // Keep existing data on failure
        }
        isLoading = false
    }

    // MARK: - Mark read

    func markAllRead() async {
        guard let token else { return }
        do {
            try await APIClient.shared.markNotificationsRead(token: token)
            // Optimistic update
            for i in notifications.indices {
                // Can't mutate let properties, so just re-fetch
            }
            await fetchNotifications()
        } catch {
            // Silent
        }
    }

    /// Mark a single notification read (used when the user taps it).
    func markRead(_ notification: DopoNotification) async {
        guard let token, !notification.isRead else { return }
        do {
            try await APIClient.shared.markNotificationsRead(token: token, ids: [notification.id])
            await fetchNotifications()
        } catch {
            // Silent
        }
    }

    // MARK: - Navigation target

    /// Resolve a notification's `collectionId` to a full collection the user can access.
    /// Returns nil if the notification references no collection, or it can no longer be
    /// reached (deleted, or access revoked).
    func resolveCollection(for notification: DopoNotification) async -> DopoCollection? {
        guard let token, let collectionId = notification.collectionId else { return nil }
        do {
            let response = try await APIClient.shared.fetchCollections(token: token)
            return response.collections.first { $0.id == collectionId }
        } catch {
            return nil
        }
    }

    /// Resolve a notification's `saveId` to the full save — the specific piece of content
    /// that was shared or added. Scoped to the notification's collection (there is no
    /// fetch-by-id endpoint). Returns nil if the notification references no specific save,
    /// or it can no longer be found (deleted).
    func resolveSave(for notification: DopoNotification) async -> Save? {
        guard let token,
              let saveId = notification.saveId,
              let collectionId = notification.collectionId else { return nil }
        do {
            let response = try await APIClient.shared.fetchLibrary(token: token, collectionId: collectionId, limit: 100)
            return response.saves.first { $0.id == saveId }
        } catch {
            return nil
        }
    }
}
