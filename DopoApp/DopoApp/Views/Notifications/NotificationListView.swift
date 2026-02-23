import SwiftUI

struct NotificationListView: View {
    @EnvironmentObject var notificationManager: NotificationManager
    @Environment(\.dismiss) private var dismiss

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
                                NotificationRow(notification: notif)
                                Divider().background(Color.dopoBorder)
                            }
                        }
                    }
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
        }
    }
}

struct NotificationRow: View {
    let notification: DopoNotification

    var body: some View {
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
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(notification.isRead ? Color.clear : Color.dopoAccent.opacity(0.03))
    }
}
