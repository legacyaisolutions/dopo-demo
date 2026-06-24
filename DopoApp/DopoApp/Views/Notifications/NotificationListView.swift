import SwiftUI

/// Where a tapped notification leads. A specific save (the exact piece of content that was
/// shared/added) takes priority; a collection is the fallback when no specific save applies.
private enum NotificationTarget: Identifiable {
    case save(Save)
    case collection(DopoCollection)

    var id: String {
        switch self {
        case .save(let save): return "save-\(save.id)"
        case .collection(let coll): return "coll-\(coll.id)"
        }
    }
}

struct NotificationListView: View {
    @EnvironmentObject var notificationManager: NotificationManager
    @Environment(\.dismiss) private var dismiss

    @State private var target: NotificationTarget?
    @State private var resolvingId: String?
    @State private var showUnavailable = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dopoBg.ignoresSafeArea()

                if notificationManager.isLoading && notificationManager.notifications.isEmpty {
                    ProgressView().tint(.dopoAccent)
                } else if notificationManager.notifications.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        Text("🔔")
                            .font(.system(size: 48))
                            .opacity(0.5)
                        Text("No notifications yet")
                            .font(.dopoHeading)
                            .foregroundColor(.dopoTextMuted)
                        Text("You'll see activity from your shared collections here.")
                            .font(.dopoBody)
                            .foregroundColor(.dopoTextDim)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(notificationManager.notifications) { notif in
                                NotificationRow(
                                    notification: notif,
                                    isResolving: resolvingId == notif.id,
                                    onTap: { handleTap(notif) }
                                )
                                Divider().background(Color.dopoBorder)
                            }
                        }
                    }
                }

                if showUnavailable {
                    VStack {
                        Spacer()
                        InlineError(message: "This content is no longer available.")
                            .padding(.bottom, 24)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.dopoAccent)
                }
                ToolbarItem(placement: .primaryAction) {
                    if notificationManager.unreadCount > 0 {
                        Button {
                            HapticManager.notification(.success)
                            Task { await notificationManager.markAllRead() }
                        } label: {
                            Text("Mark all read")
                                .font(.system(size: 13))
                                .foregroundColor(.dopoAccent)
                        }
                    }
                }
            }
            .task { await notificationManager.fetchNotifications() }
            .refreshable { await notificationManager.fetchNotifications() }
            .sheet(item: $target, onDismiss: {
                Task { await notificationManager.fetchNotifications() }
            }) { target in
                switch target {
                case .save(let save):
                    SaveDetailView(save: save)
                case .collection(let coll):
                    CollectionDetailView(collection: coll)
                }
            }
        }
    }

    private func handleTap(_ notif: DopoNotification) {
        guard resolvingId == nil else { return } // ignore taps while one is resolving
        HapticManager.impact(.light)
        resolvingId = notif.id
        Task {
            await notificationManager.markRead(notif)
            let resolved = await resolveTarget(for: notif)
            resolvingId = nil
            if let resolved {
                target = resolved
            } else if notif.saveId != nil || notif.collectionId != nil {
                // Had a target but it couldn't be reached — surface a brief notice.
                withAnimation { showUnavailable = true }
                try? await Task.sleep(nanoseconds: 2_500_000_000)
                withAnimation { showUnavailable = false }
            }
        }
    }

    /// Resolve where a notification leads. A specific shared/added piece of content (`saveId`)
    /// takes priority — open it directly. Otherwise, or if that save can no longer be found,
    /// fall back to the collection. A notification with neither resolves to nil.
    private func resolveTarget(for notif: DopoNotification) async -> NotificationTarget? {
        if notif.saveId != nil, let save = await notificationManager.resolveSave(for: notif) {
            return .save(save)
        }
        if let coll = await notificationManager.resolveCollection(for: notif) {
            return .collection(coll)
        }
        return nil
    }
}

struct NotificationRow: View {
    let notification: DopoNotification
    var isResolving: Bool = false
    let onTap: () -> Void

    /// Whether tapping this notification leads somewhere — a specific save or a collection.
    private var hasTarget: Bool { notification.saveId != nil || notification.collectionId != nil }

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                // Unread dot
                Circle()
                    .fill(notification.isRead ? Color.clear : Color.dopoAccent)
                    .frame(width: 8, height: 8)
                    .padding(.top, 6)

                // Icon
                Text(notification.icon)
                    .font(.system(size: 20))
                    .frame(width: 36, height: 36)
                    .background(Color.dopoAccentGlow)
                    .clipShape(Circle())

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(notification.title)
                        .font(.system(size: 13, weight: notification.isRead ? .regular : .medium))
                        .foregroundColor(.dopoText)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)

                    if let body = notification.body, !body.isEmpty {
                        Text(body)
                            .font(.system(size: 12))
                            .foregroundColor(.dopoTextMuted)
                            .lineLimit(1)
                    }

                    Text(notification.timeAgo)
                        .font(.system(size: 11))
                        .foregroundColor(.dopoTextDim)
                }

                Spacer()

                // Trailing affordance: spinner while resolving, else chevron when tappable
                if isResolving {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.dopoAccent)
                        .padding(.top, 4)
                } else if hasTarget {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.dopoTextDim)
                        .padding(.top, 4)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(notification.isRead ? Color.clear : Color.dopoAccent.opacity(0.03))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isResolving)
    }
}
