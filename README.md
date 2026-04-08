# MaseVpn iOS UI

This directory contains a SwiftUI interface prototype for the iOS version of MaseVpn.

Current scope:
- custom dark interface
- mock connection state
- mock traffic counters and session timer
- server list and settings screens
- local SwiftUI view model with demo data

Not included yet:
- PacketTunnel / Network Extension
- real Xray integration
- tun2socks
- production signing or IPA export

How to open on macOS:
1. Install XcodeGen.
2. Run `xcodegen generate` inside the `ios` directory.
3. Open the generated `MaseVpnIOS.xcodeproj` in Xcode.
4. Build and run on an iPhone simulator or device.

Codemagic:
1. Put `codemagic.yaml` in the repository root next to `project.yml`.
2. In Codemagic, select the repository and use YAML configuration.
3. Start the `masevpn-ios-ui-simulator` workflow.
4. Download the generated `.zip` with the unsigned simulator `.app`.

Important:
- auto-scan may not detect this app because the repo contains `project.yml`, not a pre-generated `.xcodeproj`
- this workflow is for simulator builds only
- building a real device `.ipa` still requires iOS code signing
