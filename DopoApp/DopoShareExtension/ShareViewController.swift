import UIKit
import UniformTypeIdentifiers
import Security

/// Dopo Share Extension — allows saving URLs from any app's share sheet.
/// Receives a shared URL, sends it to the ingest edge function, shows a brief
/// confirmation, and (Option A) offers the user's collections as optional
/// one-tap chips to file the save into — the save itself happens instantly so
/// the fast capture path is never blocked.
///
/// REQUIREMENTS:
///   - App Group: group.app.dopo.shared (for shared Keychain access)
///   - The main app's KeychainManager must use the shared access group
///   - See SHARE_EXTENSION_SETUP.md for full Xcode configuration steps

class ShareViewController: UIViewController {

    // MARK: - UI Elements

    private let containerView = UIView()
    private let iconLabel = UILabel()
    private let titleLabel = UILabel()
    private let statusLabel = UILabel()
    private let spinner = UIActivityIndicatorView(style: .medium)
    private let closeButton = UIButton(type: .system)

    // Collections ("Add to a collection") — hidden until a successful save.
    private let collectionsLabel = UILabel()
    private let collectionsScroll = UIScrollView()
    private let collectionsStack = UIStackView()

    private var containerHeightConstraint: NSLayoutConstraint!
    private var collectionsConstraints: [NSLayoutConstraint] = []

    // MARK: - State

    private var authToken: String?
    private var savedId: String?
    private var collections: [(id: String, name: String, emoji: String)] = []

    // MARK: - Config (mirrors DopoConfig)

    private let supabaseURL = "https://adyqktvkxwohzxzjqpjt.supabase.co"
    private let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFkeXFrdHZreHdvaHp4empxcGp0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA5MDY1OTcsImV4cCI6MjA4NjQ4MjU5N30.H5V7HHpIl5o5steAc760Lm1SqjmAYnWiBNrTlrmQHiI"

    // MARK: - Brand colors

    private let accent = UIColor(red: 1.0, green: 0.42, blue: 0.21, alpha: 1)
    private let text = UIColor(red: 0.91, green: 0.91, blue: 0.94, alpha: 1)
    private let textMuted = UIColor(red: 0.53, green: 0.53, blue: 0.63, alpha: 1)
    private let surface = UIColor(red: 0.08, green: 0.08, blue: 0.12, alpha: 1)
    private let surfaceHover = UIColor(red: 0.11, green: 0.11, blue: 0.18, alpha: 1)
    private let border = UIColor(red: 0.16, green: 0.16, blue: 0.24, alpha: 1)
    private let success = UIColor(red: 0.20, green: 0.83, blue: 0.60, alpha: 1)
    private let errorColor = UIColor(red: 0.97, green: 0.44, blue: 0.44, alpha: 1)

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        extractAndSaveURL()
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)

        containerView.backgroundColor = surface
        containerView.layer.cornerRadius = 20
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = border.cgColor
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)

        iconLabel.text = "d"
        iconLabel.font = UIFont.systemFont(ofSize: 36, weight: .bold)
        iconLabel.textColor = accent
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(iconLabel)

        titleLabel.text = "Saving to dopo..."
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = text
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)

        statusLabel.text = "Extracting metadata..."
        statusLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        statusLabel.textColor = textMuted
        statusLabel.numberOfLines = 2
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(statusLabel)

        spinner.color = accent
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimating()
        containerView.addSubview(spinner)

        closeButton.setTitle("Done", for: .normal)
        closeButton.setTitleColor(accent, for: .normal)
        closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        closeButton.isHidden = true
        closeButton.addTarget(self, action: #selector(dismissExtension), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(closeButton)

        // ─── Collections section (hidden until a successful save) ───
        collectionsLabel.text = "Add to a collection"
        collectionsLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        collectionsLabel.textColor = textMuted
        collectionsLabel.isHidden = true
        collectionsLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(collectionsLabel)

        collectionsScroll.showsHorizontalScrollIndicator = false
        collectionsScroll.isHidden = true
        collectionsScroll.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(collectionsScroll)

        collectionsStack.axis = .horizontal
        collectionsStack.spacing = 8
        collectionsStack.translatesAutoresizingMaskIntoConstraints = false
        collectionsScroll.addSubview(collectionsStack)

        containerHeightConstraint = containerView.heightAnchor.constraint(equalToConstant: 180)

        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 300),
            containerHeightConstraint,

            iconLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 24),
            iconLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),

            titleLabel.centerYAnchor.constraint(equalTo: iconLabel.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: iconLabel.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -24),

            spinner.topAnchor.constraint(equalTo: iconLabel.bottomAnchor, constant: 20),
            spinner.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),

            statusLabel.centerYAnchor.constraint(equalTo: spinner.centerYAnchor),
            statusLabel.leadingAnchor.constraint(equalTo: spinner.trailingAnchor, constant: 10),
            statusLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),

            closeButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
            closeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
        ])

        // Constraints for the collections section — only activated when shown,
        // so they never conflict with the compact 180pt initial layout.
        collectionsConstraints = [
            collectionsLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 16),
            collectionsLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),

            collectionsScroll.topAnchor.constraint(equalTo: collectionsLabel.bottomAnchor, constant: 10),
            collectionsScroll.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            collectionsScroll.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            collectionsScroll.heightAnchor.constraint(equalToConstant: 40),

            collectionsStack.topAnchor.constraint(equalTo: collectionsScroll.contentLayoutGuide.topAnchor),
            collectionsStack.bottomAnchor.constraint(equalTo: collectionsScroll.contentLayoutGuide.bottomAnchor),
            collectionsStack.leadingAnchor.constraint(equalTo: collectionsScroll.contentLayoutGuide.leadingAnchor),
            collectionsStack.trailingAnchor.constraint(equalTo: collectionsScroll.contentLayoutGuide.trailingAnchor),
            collectionsStack.heightAnchor.constraint(equalTo: collectionsScroll.frameLayoutGuide.heightAnchor),

            closeButton.topAnchor.constraint(greaterThanOrEqualTo: collectionsScroll.bottomAnchor, constant: 12),
        ]
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
        guard let token = SharedKeychainManager.retrieve(key: DopoKeychain.accessTokenKey) else {
            showError("Not signed in — open dopo first")
            return
        }
        authToken = token

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
                    var title = "Link"
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let save = json["save"] as? [String: Any] {
                        title = (save["title"] as? String)?.prefix(50).description ?? "Link"
                        self?.savedId = save["id"] as? String
                    }
                    self?.showSuccess(title)
                } else if httpResponse.statusCode == 409 {
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let existingId = json["existing_id"] as? String {
                        self?.savedId = existingId
                    }
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
        statusLabel.textColor = success
        closeButton.isHidden = false
        offerCollectionsOrDismiss()
    }

    private func showAlreadySaved() {
        spinner.stopAnimating()
        titleLabel.text = "Already saved"
        statusLabel.text = "This link is already in your library"
        statusLabel.textColor = accent
        closeButton.isHidden = false
        offerCollectionsOrDismiss()
    }

    private func showError(_ message: String) {
        spinner.stopAnimating()
        titleLabel.text = "Oops"
        statusLabel.text = message
        statusLabel.textColor = errorColor
        closeButton.isHidden = false
    }

    // MARK: - Collections (Option A: optional one-tap filing)

    /// The save already happened. If the user has collections they can add to,
    /// show them as chips and let the screen stay open. Otherwise keep the fast
    /// path and auto-dismiss.
    private func offerCollectionsOrDismiss() {
        guard let token = authToken, savedId != nil else {
            autoDismiss()
            return
        }
        fetchCollections(token: token) { [weak self] colls in
            guard let self = self else { return }
            if colls.isEmpty {
                self.autoDismiss()
            } else {
                self.collections = colls
                self.showCollections(colls)
            }
        }
    }

    private func autoDismiss() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.dismissExtension()
        }
    }

    private func fetchCollections(token: String, completion: @escaping ([(id: String, name: String, emoji: String)]) -> Void) {
        guard let url = URL(string: "\(supabaseURL)/functions/v1/library/collections") else {
            completion([]); return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.timeoutInterval = 15

        URLSession.shared.dataTask(with: request) { data, _, _ in
            var result: [(id: String, name: String, emoji: String)] = []
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let colls = json["collections"] as? [[String: Any]] {
                for c in colls {
                    // Only collections the user can actually add saves to.
                    let isOwner = (c["is_owner"] as? Bool) ?? true
                    let role = c["role"] as? String
                    guard isOwner || role == "editor" else { continue }
                    if let id = c["id"] as? String, let name = c["name"] as? String {
                        let emoji = (c["emoji"] as? String) ?? "\u{1F4C1}" // 📁
                        result.append((id: id, name: name, emoji: emoji))
                    }
                }
            }
            DispatchQueue.main.async { completion(result) }
        }.resume()
    }

    private func showCollections(_ colls: [(id: String, name: String, emoji: String)]) {
        collectionsLabel.isHidden = false
        collectionsScroll.isHidden = false

        for (i, c) in colls.enumerated() {
            collectionsStack.addArrangedSubview(makeChip(index: i, name: c.name, emoji: c.emoji))
        }

        containerHeightConstraint.constant = 300
        NSLayoutConstraint.activate(collectionsConstraints)
        UIView.animate(withDuration: 0.25) { self.view.layoutIfNeeded() }
    }

    private func makeChip(index: Int, name: String, emoji: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle("\(emoji) \(name)", for: .normal)
        button.setTitleColor(text, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        button.backgroundColor = surfaceHover
        button.layer.cornerRadius = 16
        button.layer.borderWidth = 1
        button.layer.borderColor = border.cgColor
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 14, bottom: 8, right: 14)
        button.tag = index
        button.addTarget(self, action: #selector(chipTapped(_:)), for: .touchUpInside)
        return button
    }

    @objc private func chipTapped(_ sender: UIButton) {
        let idx = sender.tag
        guard idx >= 0, idx < collections.count,
              let saveId = savedId, let token = authToken else { return }
        let coll = collections[idx]
        sender.isEnabled = false

        addSaveToCollection(collectionId: coll.id, saveId: saveId, token: token) { [weak self] ok in
            guard let self = self else { return }
            if ok {
                self.markChipAdded(sender, name: coll.name)
            } else {
                sender.isEnabled = true
            }
        }
    }

    private func markChipAdded(_ button: UIButton, name: String) {
        button.setTitle("\u{2713} \(name)", for: .normal) // ✓
        button.setTitleColor(.white, for: .normal)
        button.setTitleColor(.white, for: .disabled)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        button.backgroundColor = accent
        button.isEnabled = false
    }

    private func addSaveToCollection(collectionId: String, saveId: String, token: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(supabaseURL)/functions/v1/library/collections") else {
            completion(false); return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        let body: [String: Any] = ["action": "add_save", "collection_id": collectionId, "save_id": saveId]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 20

        URLSession.shared.dataTask(with: request) { _, response, _ in
            let ok = (response as? HTTPURLResponse).map { $0.statusCode == 200 || $0.statusCode == 201 } ?? false
            DispatchQueue.main.async { completion(ok) }
        }.resume()
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
/// The service + access group come from `DopoKeychain` (Shared/DopoKeychain.swift,
/// compiled into both targets), so they are guaranteed to match the values the
/// main app's KeychainManager writes with. See SHARE_EXTENSION_SETUP.md.
enum SharedKeychainManager {

    static func retrieve(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: DopoKeychain.service,
            kSecAttrAccessGroup as String: DopoKeychain.accessGroup,
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
