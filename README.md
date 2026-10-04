# Database Viewer

Homebrew cask for [Database Viewer](https://github.com/MarkKiepe/database-viewer), a local-first desktop SQL client.

The cask installs `Database Viewer.app` from the Apple Silicon disk image on GitHub Releases (`Database-Viewer-<version>-arm64.dmg`). It does not download the website `.pkg`.

## Install

```bash
brew tap MarkKiepe/database-viewer
brew install --cask database-viewer
```

This cask is Apple Silicon (`arm64`) only. An Intel (`x64`) disk image is not published yet, so `brew install` stops on Intel Macs.

## Upgrade

```bash
brew update
brew upgrade --cask database-viewer
```

A Developer ID build also checks GitHub Releases from inside the app.

## Uninstall

```bash
brew uninstall --cask database-viewer
```

To remove the app and its local data (saved connections under `~/Library/Application Support/database-viewer`, and the older `databae-viewer` folder):

```bash
brew uninstall --cask --zap database-viewer
```

## After a release

Tag the release on `MarkKiepe/database-viewer` first. From a checkout of this tap, pass that version:

```bash
bash scripts/bump-cask.sh 0.1.3
```

The script reads the sha256 digest of `Database-Viewer-<version>-arm64.dmg` from the GitHub release asset. If the digest is missing, it downloads that DMG and hashes it, then updates `Casks/database-viewer.rb`. Add `--print-only` to print the version and checksum without editing the cask.
