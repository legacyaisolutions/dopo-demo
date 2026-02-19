import UIKit
import UniformTypeIdentifiers

/// Dopo Share Extension — allows saving URLs from any app's share sheet.
/// Receives a shared URL, sends it to the ingest edge function, and displays
/// a brief confirmation before dismissing.
///
/// REQUIREMENTS:
///   - App Group: group.app.dopo.shared (for shared Keychain access)
///   - The main app's KeychainManager must be updated to use the shared access group
///   - See SHARE_EXTENSION_SETUP.md for full Xcode configuration steps

class ShareViewController: UIViewController {

    // MARK: - UI Elements

    private let containerView = UIView()
    private let iconLabel = UILabel()
    private let titleLabel = UILabel()
    private let statusLabel = UILabel()
    private let spinner = UIActivityIndicatorView(style: .medium)
    private let closeButton = UIButton(type: .system)

    // MARK: - Config (mirrors DopoConfig)

    private let supabaseURL = "https://adyqktvkxwohzxzjqpjt.supabase.co"
    private let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFkeXFrdHZreHdvaHp4empxcGp0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA5MDY1OTcsImV4cCI6MjA4NjQ4MjU5N30.H5V7HHpIl5o5steAc760Lm1SqjmAYnWiBNrTlrmQHiI"

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        extractAndSaveURL()
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)

        // Container card
        containerView.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.12, alpha: 1) // --surface
        containerView.layer.cornerRadius = 20
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor(red: 0.16, green: 0.16, blue: 0.24, alpha: 1).cgColor // --border
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)

        // dopo icon/text
        iconLabel.text = "d"
        iconLabel.font = UIFont.systemFont(ofSize: 36, weight: .bold)
        iconLabel.textColor = UIColor(red: 1.0, green: 0.42, blue: 0.21, alpha: 1) // --accent
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(iconLabel)

        // Title
        titleLabel.text = "Saving to dopo..."
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = UIColor(red: 0.91, green: 0.91, blue: 0.94, alpha: 1) // --text
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)

        // Status
        statusLabel.text = "Extracting metadata..."
        statusLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        statusLabel.textColor = UIColor(red: 0.53, green: 0.53, blue: 0.63, alpha: 1) // --text-muted
        statusLabel.numberOfLines = 2
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(statusLabel)

        // Spinner
        spinner.color = UIColor(red: 1.0, green: 0.42, blue: 0.21, alpha: 1)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimating()
        containerView.addSubview(spinner)

        // Close button (hidden initially, shown on completion)
        closeButton.setTitle("Done", for: .normal)
        closeButton.setTitleColor(UIColor(red: 1.0, green: 0.42, blue: 0.21, alpha: 1), for: .normal)
        closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        closeButton.isHidden = true
        closeButton.addTarget(self, action: #selector(dismissExtension), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(closeButton)

        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 300),
            containerView.heightAnchor.constraint(equalToConstant: 180),

            iconLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 24),
            iconLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),

            titleLabel.centerYAnchor.constraint(equalTo: iconLabel.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: iconLabel.trailingAnchor, constant: 12),

            spinner.topAnchor.constraint(equalTo: iconLabel.bottomAnchor, constant: 20),
            spinner.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),

            statusLabel.centerYAnchor.constraint(equalTo: spinner.centerYAnchor),
            statusLabel.leadingAnchor.constraint(equalTo: spinner.trailingAnchor, constant: 10),
            statusLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),

            closeButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
            closeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
        ])
    }

    // MARK: - URL Extraction & Ingest

    private func extractAndSaveURL() {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else {
            showError("No content to save")
            return
        }

        for item in items {
            guard let attachments = item.attachments else { continue }
            for provider in attachments {
                // Try URL type first
                if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] data, error in
                        DispatchQueue.main.async {
                            if let url = data as? URL {
                                self?.ingestURL(url.absoluteString)
                            } else if let urlData = data as? Data, let url = URL(dataRepresentation: urlData, relativeTo: nil) {
                                self?.ingestURL(url.absoluteString)
                            } else {
                                self?.showError("Couldn't read shared URL")
                            }
                        }
                    }
                    return
                }
                // Fallback: try plain text (might contain a URL)
                if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] data, error in
                        DispatchQueue.main.async {
                            if let text = data as? String, text.hasPrefix("http") {
                                self?.ingestURL(text.trimmingCharacters(in: .whitespacesAndNewlines))
                            } else {
                                self?.showError("No URL found in shared content")
                            }
                        }
                    }
                    return
                }
            }
        }

        showError("No URL found in shared content")
    }

    private func ingestURL(_ urlString: String) {
        // Get auth token from shared Keychain
        guard let token = SharedKeychainManager.retrieve(key: "dopo_access_token") else {
            showError("Not signed in — open dopo first")
            return
        }

        statusLabel.text = "Saving \(shortenURL(urlString))..."

        let endpoint = "\(supabaseURL)/functions/v1/ingest"
        guard let url = URL(string: endpoint) else {
            showError("Invalid endpoint")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")

        let body: [String: Any] = ["url": urlString]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 30

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.showError("Network error: \(error.localizedDescription)")
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse, let data = data else {
                    self?.showError("No response from server")
                    return
                }

                if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                    // Parse the save title for display
                    var title = "Link"
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let save = json["save"] as? [String: Any] {
                        title = (save["title"] as? String)?.prefix(50).description ?? "Link"
                    }
                    self?.showSuccess(title)
                } else if httpResponse.statusCode == 409 {
                    self?.showAlreadySaved()
                } else {
                    var errorMsg = "Save failed"
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let msg = json["error"] as? String {
                        errorMsg = msg == "Already saved" ? "Already in your library!" : msg
                    }
                    self?.showError(errorMsg)
                }
            }
        }.resume()
    }

    // MARK: - Status Display

    private func showSuccess(_ title: String) {
        spinner.stopAnimating()
        titleLabel.text = "Saved!"
        statusLabel.text = title
        statusLabel.textColor = UIColor(red: 0.20, green: 0.83, blue: 0.60, alpha: 1) // --success
        closeButton.isHidden = false

        // Auto-dismiss after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.dismissExtension()
        }
    }

    private func showAlreadySaved() {
        spinner.stopAnimating()
        titleLabel.text = "Already saved"
        statusLabel.text = "This link is already in your library"
        statusLabel.textColor = UIColor(red: 1.0, green: 0.42, blue: 0.21, alpha: 1)
        closeButton.isHidden = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.dismissExtension()
        }
    }

    private func showError(_ message: String) {
        spinner.stopAnimating()
        titleLabel.text = "Oops"
        statusLabel.text = message
        statusLabel.textColor = UIColor(red: 0.97, green: 0.44, blue: 0.44, alpha: 1) // --error
        closeButton.isHidden = false
    }

    // MARK: - Helpers

    private func shortenURL(_ url: String) -> String {
        guard let parsed = URL(string: url) else { return url }
        return parsed.host ?? url
    }

    @objc private func dismissExtension() {
        extensionContext?.completeRequest(returningItems: nil)
    }
}

// MARK: - Shared Keychain (App Group)

/// Reads tokens from the shared Keychain access group so the share extension
/// can authenticate with the same user session as the main app.
///
/// IMPORTANT: The main app's KeychainManager must be updated to write tokens
/// using the same kSecAttrAccessGroup. See SHARE_EXTENSION_SETUP.md.
enum SharedKeychainManager {

    private static let accessGroup = "group.app.dopo.shared"
    private static let service = "app.dopo.DopoApp"

    static func retrieve(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: service,
            kSecAttrAccessGroup as String: accessGroup,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }
}
