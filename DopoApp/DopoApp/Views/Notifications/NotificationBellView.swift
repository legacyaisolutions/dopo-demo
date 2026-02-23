import SwiftUI

struct NotificationBellView: View {
    @EnvironmentObject var notificationManager: NotificationManager
    @State private var showNotifications = false

    var body: some View {
        Button {
            HapticManager.impact(.light)
            showNotifications = true
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 17))
                    .foregroundColor(.dopoTextMuted)

                if notificationManager.unreadCount > 0 {
                    Text(notificationManager.unreadCount > 9 ? "9+" : "\(notificationManager.unreadCount)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .frame(minWidth: 16, minHeight: 16)
                        .background(Color.dopoAccent)
                        .clipShape(Circle())
                        .offset(x: 6, y: -6)
                }
            }
        }
        .sheet(isPresented: $showNotifications) {
            NotificationListView()
        }
    }
}
