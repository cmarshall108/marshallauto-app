# Marshall Auto Admin for iPhone

Initial native SwiftUI client for the staff dashboard. It supports the existing
staff password and authenticator/recovery-code sign-in, and displays dashboard
statistics, financials, recent leads and activity. It is not yet a replacement
for the rest of the website's admin workflows.

First-time authenticator enrollment, recovery-code saving, and staff profile
setup are completed on the website. The app directs staff there and asks them
to sign in again afterwards. Passwords and codes are not saved by the app;
the HTTPS session is kept only in the app's in-memory URL session.

## Build

Install Xcode and XcodeGen on macOS, then:

```sh
xcodegen generate
open MarshallAuto.xcodeproj
```

Choose a simulator and run the `MarshallAuto` scheme. The app connects to
`https://marshallautosanford.com`; the website must first be deployed with the
corresponding `/admin/mobile/*` and `/admin/dashboard/data` endpoints.
GitHub Actions builds an unsigned simulator app on pushes and pull requests.
This is a build check, not an installable iPhone release.

## Distribution is not configured

A device build requires an Apple Developer membership, a unique bundle ID,
signing certificate, Ad Hoc provisioning profile containing each registered
device, and an Xcode archive/export on macOS. Linux cannot run the standard iOS
Xcode build. The current workflow does not create, sign, publish, or host an IPA,
and no website installation link is configured. Do not commit signing materials
or credentials to the repository. HTTPS hosting and an appropriately protected
OTA manifest and IPA distribution mechanism still need to be implemented.
