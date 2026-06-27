# Lesaria TestFlight + CloudKit Setup

Diese Repo ist fuer TestFlight vorbereitet. Die letzten Schritte passieren im Apple Developer Portal und in App Store Connect.

## App IDs und Capabilities

1. Oeffne Apple Developer > Certificates, Identifiers & Profiles > Identifiers.
2. Lege die App ID `com.urusborz.lesaria` an oder oeffne sie.
3. Aktiviere `Sign in with Apple`.
4. Aktiviere `iCloud` und darin `CloudKit`.
5. Lege den iCloud Container `iCloud.com.urusborz.lesaria` an und weise ihn der App ID zu.
6. Speichere die App ID.
7. Oeffne das Projekt auf dem iPad in Swift Playgrounds > App Settings > Capabilities und aktiviere ebenfalls `Sign in with Apple` sowie `iCloud/CloudKit`, falls diese dort angeboten werden. Die Repo enthaelt `Lesaria.swiftpm/Lesaria.entitlements` als Referenz fuer die erwarteten Entitlements.

## App Store Connect

1. Lege in App Store Connect eine neue iOS-App `Lesaria` mit Bundle ID `com.urusborz.lesaria` an.
2. Die TestFlight-Builds kommen ueber GitHub Actions, nicht ueber Xcode Cloud.

## GitHub Actions Upload von Windows aus

Da Xcode Cloud den ersten Workflow in Xcode erwartet, nutzt diese Repo fuer Windows den Workflow `.github/workflows/testflight.yml`.

Lege in GitHub > Settings > Secrets and variables > Actions diese Repository Secrets an:

- `APPLE_TEAM_ID`: Team ID aus dem Apple Developer Account
- `APP_STORE_CONNECT_KEY_ID`: Key ID des App Store Connect API Keys
- `APP_STORE_CONNECT_ISSUER_ID`: Issuer ID aus App Store Connect API
- `APP_STORE_CONNECT_API_KEY_BASE64`: Inhalt der heruntergeladenen `.p8` API-Key-Datei als Base64
- `BUILD_CERTIFICATE_BASE64`: Apple Distribution `.p12` als Base64
- `P12_PASSWORD`: Passwort der `.p12` Datei
- `BUILD_PROVISION_PROFILE_BASE64`: App Store Connect Provisioning Profile `.mobileprovision` als Base64

Der Workflow setzt `bundleVersion` ueber `ci_scripts/ci_pre_xcodebuild.sh` auf die aktuelle GitHub-Run-Nummer, baut auf `macos-15`, signiert mit dem Apple Distribution Zertifikat und App Store Connect Provisioning Profile und laedt die IPA zu TestFlight hoch.

Windows-Helfer:

1. `ci_scripts/create_distribution_csr.ps1` erzeugt auf dem Desktop `lesaria_distribution.csr`. Der dazugehoerige private Key wird exportierbar im Windows Current User Zertifikatsspeicher angelegt.
2. Die `.csr` Datei im Apple Developer Portal fuer ein `Apple Distribution` Zertifikat hochladen.
3. Das heruntergeladene `.cer` mit `ci_scripts/create_p12_from_apple_cer.ps1 -CertificatePath "C:\Pfad\distribution.cer"` in eine `.p12` umwandeln. Der Base64-Wert wird in die Zwischenablage kopiert.
4. Im Apple Developer Portal ein App Store provisioning profile fuer `com.urusborz.lesaria` mit diesem Apple Distribution Zertifikat erstellen.
5. Das Provisioning Profile herunterladen und mit `ci_scripts/copy_profile_base64.ps1 -ProvisionProfilePath "C:\Pfad\profile.mobileprovision"` als Base64 in die Zwischenablage kopieren.

## CloudKit Schema

Die App speichert einen privaten Datensatz pro iCloud Account:

- Container: `iCloud.com.urusborz.lesaria`
- Database: Private Database
- Record Type: `LesariaSnapshot`
- Record ID: `primary`
- Fields: `payloadData` (Bytes), `updatedAt` (Date/Time), `schemaVersion` (Number), `deviceID` (String)

Beim ersten erfolgreichen TestFlight-Start erzeugt die App den Datensatz automatisch.
