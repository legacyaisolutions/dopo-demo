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
}
