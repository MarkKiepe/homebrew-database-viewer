cask "database-viewer" do
  version "0.1.4"
  sha256 "a531edc709a989e8796ac885caeaf834a3fc7fce1663bdb3afc9e5be774993db"

  url "https://github.com/MarkKiepe/database-viewer/releases/download/v#{version}/Database-Viewer-#{version}-arm64.dmg"
  name "Database Viewer"
  desc "Local-first desktop SQL client"
  homepage "https://database-viewer-website.markkiepe-ai.workers.dev/"

  livecheck do
    url :url
    strategy :github_latest
  end

  auto_updates true
  depends_on macos: ">= :ventura"
  depends_on arch: :arm64

  app "Database Viewer.app"

  zap trash: [
    "~/Library/Application Support/Database Viewer",
    "~/Library/Application Support/database-viewer",
    "~/Library/Application Support/databae-viewer",
    "~/Library/Caches/Database Viewer",
    "~/Library/Caches/database-viewer-updater",
    "~/Library/Logs/Database Viewer",
    "~/Library/Preferences/com.databaseviewer.viewer.plist",
    "~/Library/Saved Application State/com.databaseviewer.viewer.savedState",
  ]
end
