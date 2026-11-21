import AppKit

// Check for updates asks GitHub for the newest release, only when the user clicks it, and tells whether this copy
// is current. It is the only network request Pane ever makes. A newer version is downloaded from the website.
enum UpdateChecker {
    private struct Release: Decodable {
        let tagName: String
        enum CodingKeys: String, CodingKey { case tagName = "tag_name" }
    }

    @MainActor
    static func check() {
        let current = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
        Task { @MainActor in
            do {
                var request = URLRequest(url: Config.latestReleaseAPI, timeoutInterval: 10)
                request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
                let (data, response) = try await URLSession.shared.data(for: request)
                guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
                var latest = try JSONDecoder().decode(Release.self, from: data).tagName
                if latest.hasPrefix("v") { latest.removeFirst() }
                if latest.compare(current, options: .numeric) == .orderedDescending {
                    let open = alert(
                        "Pane \(latest) is available",
                        "You have \(current). Download the new version, quit Pane and drag the new one into Applications.",
                        buttons: ["Download", "Later"])
                    if open { NSWorkspace.shared.open(Config.updateDownload) }
                } else {
                    _ = alert("You're up to date", "Pane \(current) is the newest version.", buttons: ["OK"])
                }
            } catch {
                let open = alert(
                    "Couldn't check for updates",
                    "Check your internet connection, or see the newest version on GitHub.",
                    buttons: ["Open GitHub", "Cancel"])
                if open { NSWorkspace.shared.open(Config.latestRelease) }
            }
        }
    }

    // Shows a dialog in front of other apps (Pane lives in the menu bar) and says whether the first button was chosen
    @MainActor
    private static func alert(_ title: String, _ text: String, buttons: [String]) -> Bool {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = text
        buttons.forEach { alert.addButton(withTitle: $0) }
        NSApp.activate(ignoringOtherApps: true)
        return alert.runModal() == .alertFirstButtonReturn
    }
}
