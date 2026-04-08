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
5. To try installation through AltStore, start the `masevpn-ios-ui-ipa` workflow and download `MaseVpnIOS-unsigned.ipa`.

Important:
- auto-scan may not detect this app because the repo contains `project.yml`, not a pre-generated `.xcodeproj`
- this workflow is for simulator builds only
- the `masevpn-ios-ui-ipa` workflow creates an unsigned device `.ipa` by packaging the built `.app`
- for App Store or a normally signed device build, proper iOS code signing is still required
