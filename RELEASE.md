# Releasing Clacky

Releases are cut by **pushing a `v*.*.*` tag**. GitHub Actions then signs with
Developer ID, notarizes with Apple, and publishes a DMG + ZIP to the GitHub
Releases page. No local toolchain needed; the entire pipeline runs on a
`macos-14` runner.

## One-time GitHub Secrets setup

In the repo's **Settings → Secrets and variables → Actions**, add:

| Secret | Value |
| --- | --- |
| `APPLE_CERTIFICATE` | Base64 of your **Developer ID Application** `.p12` (cert + private key). See "Exporting the cert" below. |
| `APPLE_CERTIFICATE_PASSWORD` | The password you set when exporting the `.p12`. |
| `APPLE_ID` | Apple ID email used for notarization. |
| `APPLE_APP_SPECIFIC_PASSWORD` | App-specific password from [appleid.apple.com → Sign-In and Security → App-Specific Passwords](https://appleid.apple.com/account/manage). |
| `APPLE_TEAM_ID` | Your team ID, e.g. `JAT3GYBPJ4`. From `security find-identity -v -p codesigning` it's the parenthesized prefix. |
| `DEVELOPER_ID_APPLICATION` | The full identity string, e.g. `Developer ID Application: Jiajun Zhang (JAT3GYBPJ4)`. Copy the quoted name from `security find-identity -v -p codesigning`. |

### Exporting the cert

In **Keychain Access**:

1. Find **Developer ID Application: Your Name (TEAMID)** in the *login* keychain
2. Right-click → **Export…** → choose `.p12` format, set a password (this becomes `APPLE_CERTIFICATE_PASSWORD`)
3. Base64 it:

   ```bash
   base64 -i ~/Desktop/DeveloperID.p12 | pbcopy
   ```

4. Paste into the `APPLE_CERTIFICATE` GitHub secret. Delete the local `.p12`.

## Cutting a release

```bash
# 1. Bump the version (also updates CURRENT_PROJECT_VERSION and regenerates the project)
make bump-patch    # or bump-minor / bump-major
make version       # confirm

# 2. Commit + tag + push
git add project.yml Clacky.xcodeproj
git commit -m "Release v$(grep MARKETING_VERSION project.yml | head -1 | sed 's/.*"\(.*\)".*/\1/')"
VERSION=$(grep MARKETING_VERSION project.yml | head -1 | sed 's/.*"\(.*\)".*/\1/')
git tag "v$VERSION"
git push origin main "v$VERSION"
```

The tag push triggers `.github/workflows/release.yml`. When it finishes
(~5 min), a new GitHub Release appears with auto-generated release notes and
the signed/notarized artifacts attached:

- `Clacky-X.Y.Z-arm64.dmg`
- `Clacky-X.Y.Z-arm64.zip`

A failed build will keep the tag in git; delete it and re-push after fixing:

```bash
git tag -d vX.Y.Z
git push --delete origin vX.Y.Z
```

## How the pipeline works

`.github/workflows/release.yml` calls the reusable
`.github/workflows/build-workflow.yml` with `release: true`. That workflow:

1. Installs `xcodegen`, regenerates `Clacky.xcodeproj`, runs the test suite
2. Creates an ephemeral keychain and imports the Developer ID cert + Apple
   intermediate CAs
3. Runs `scripts/make_release.sh`, which:
   - `xcodebuild archive` in Release, signed with the Developer ID identity
   - `xcodebuild -exportArchive` with method `developer-id`
   - Zips the `.app` and submits it to `xcrun notarytool ... --wait`
   - `xcrun stapler staple` once notarization succeeds
   - Builds a DMG (via `hdiutil`) and a ZIP (via `ditto`)
   - Submits the DMG itself for notarization + staples it
4. Uploads the artifacts; the downstream `release` job attaches them to the
   GitHub Release

## CI build (no release)

Every push to `main` and every PR runs `.github/workflows/build.yml`, which
calls the same reusable workflow with `release: false` — it generates the
project, runs the tests, and stops. No secrets needed.
