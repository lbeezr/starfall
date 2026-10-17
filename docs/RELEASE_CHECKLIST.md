# Starfall release checklist

For the current default game, complete the [six shipping quality gates](ROADMAP.md#shipping-quality-gates) and use the [falling-sky playtest](PLAYTEST-FALLING-SKY.md). This checklist owns distribution prerequisites; historical original-puzzle passes do not establish current falling-sky acceptance.


Checked 2026-10-16. This checklist tracks release gates; it is not a claim of App Store approval, legal compliance, or distribution readiness. See `ROADMAP.md` and `ACCEPTANCE.md` for execution and gameplay scope.

## Verified source and packaging state

- Clean offline MVP: inspected app/core/package source uses local saves and settings; no advertising, IAP, analytics or external SDK dependency was found. Re-audit the final candidate and any added dependency before submitting privacy answers.
- `Config/PrivacyInfo.xcprivacy` declares no tracking, no tracking domains, no collected-data types, and UserDefaults reason `CA92.1` for app-local saves/settings.
- **Bundled manifest check passed** in [run 38895166811](https://github.com/lbeezr/starfall/actions/runs/38895166811), source `c4ac5d7d19a2e118d2ee9077201c8649b50ef5b4`, Xcode 26.3, iPhone SE (3rd generation), iOS 26.2 Simulator. The `privacy-manifest-result.json` receipt reports semantic equality with source and the expected reason. Source and bundled SHA-256: `a331d51864743ebe4e00dd22360b4a538b6b3ac26a6b3eb54094e60a36959a12`. This isolated packaging pass does **not** imply the whole run or accessibility suite passed.
- Current configuration: version `0.1.0`, build `1`, deployment target iOS 17, provisional bundle ID `com.starfall.prototype`, automatic signing without an established team, iPhone **and iPad** device families. These are prototype settings, not approved production identity.

## Gates before a signed beta

- [ ] **Icon:** catalog registration and native app-icon metadata have [historical build evidence](evidence/swarm-2026-10-16/source-and-product.json). Independently review the final icon, verify its actual Home Screen appearance, and recheck compiled metadata in the final signed candidate; the earlier build does not establish acceptance of that candidate.
- [ ] **Supported devices:** resolve iPhone-first scope explicitly. If retaining current iPad support, verify portrait/landscape layouts and supply required iPad screenshots; do not infer support from compilation.
- [ ] **Release configuration:** build the exact candidate in Release, verify acceptance-only fixtures are excluded, examine warnings and bundle contents, and rerun applicable regression tests. Retain source SHA/build/toolchain evidence.
- [ ] **Identity:** confirm publisher/team, production bundle ID, name availability and version/build numbering before upload. Do not silently register the prototype identifier; the bundle ID cannot be changed after the first upload.
- [ ] **Account/signing:** confirm the existing Apple Developer Program membership and App Store Connect role. Establish authorized signing/provisioning securely. No credential belongs in source or public CI logs.
- [ ] **Upload gate:** create the approved app record and validate a signed device archive only when account and distribution authority are established. Simulator builds are not installable TestFlight builds.

## Gates before public submission

- [ ] **Physical iPhone:** record device/OS and real play through the full acceptance script, interruptions/relaunch, sound, VoiceOver, Reduce Motion and responsiveness/energy behavior. Simulator checks do not establish physical-device acceptance.
- [ ] **Human playtest:** run the bounded script in [PLAYTEST-FALLING-SKY.md](PLAYTEST-FALLING-SKY.md) with approved participants; resolve major confusion or friction without adding scope merely to extend play time.
- [ ] **Privacy/support:** finalize publisher/contact details, publish working policy/support URLs at an approved destination, and expose the privacy policy accessibly inside the app. No placeholder URL or personal contact details without authorization.
- [ ] **Metadata:** prepare truthful description, category, content-rights and age-rating answers; use real final-build gameplay screenshots in Apple's required sizes. Draft export-compliance answers from the actual binary rather than assuming an exemption.
- [ ] **Commercial choices:** confirm pricing, storefront availability, required account declarations and final submission authority. Keep the clean MVP free of monetization SDKs; this checklist does not choose a business model.
- [ ] **Beta/review:** invite only approved testers. External TestFlight builds may require Beta App Review. Resolve feedback, retain exact-head evidence, and submit only after the remaining gates are satisfied. No promised review time or acceptance.

## Draft privacy wording — not published or final

**Publisher:** pending approved identity  
**Effective date:** pending publication date  
**Privacy-policy URL / support URL / support contact:** pending approved destinations

> Starfall's current clean edition stores your saved game and sound and motion preferences locally on your device. It does not include advertising, in-app purchases, analytics SDKs or an account system, and the app does not send gameplay or preference data to a server operated by us.
>
> Starting a new game replaces the saved round. Removing the app using Delete App removes its local app data; device backups and Apple's own services are governed by their respective settings and policies. Offloading an app is different from deleting its data.
>
> If you choose to contact support, your message and any information you provide are handled through the selected support channel. The publisher, contact method, purposes and retention/deletion process for that correspondence must be finalized before this policy is published.

Review the wording against the final shipped app and support process. The manifest, App Store privacy answers and a public privacy policy are separate requirements. Do not represent this draft as a complete legal policy or assert that Apple/platform services collect no information.

## Draft support wording — not published

> Need help with Starfall? Contact [approved support contact pending]. Please include the app version, iPhone/iPad model, iOS version, what happened, and the steps to reproduce it. A screenshot is optional; avoid including personal information. Starfall currently saves progress locally and has no account-based cross-device sync.

Replace the placeholder and verify the contact works before submission. Do not promise a response time or recovery of deleted progress without an established support process.

## Official references

- [Required-reason API values](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitypereasons): CA92.1 covers defaults accessible only to the app itself.
- [App privacy declarations](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/): disclose actual collection and provide a privacy-policy URL even when selecting no collection.
- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/): 2.1 calls for on-device testing and complete submissions; 2.3.3 requires screenshots showing the app in use; 5.1.1 requires accessible in-app and metadata policy links.
- [App review support requirements](https://developer.apple.com/app-store/review/): working support and privacy links.
- [App icon configuration](https://developer.apple.com/documentation/xcode/configuring-your-app-icon) and [screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications).
- [Minimum SDK requirements effective April 28, 2026](https://developer.apple.com/news/upcoming-requirements/?id=04282026a): Xcode 26+ and iOS 26 SDK+ for uploads; deployment target may be older. Recheck at actual submission.
- [Create an app record](https://developer.apple.com/help/app-store-connect/create-an-app-record/add-a-new-app/), [prepare distribution](https://developer.apple.com/documentation/xcode/preparing-your-app-for-distribution), and [App Store provisioning](https://developer.apple.com/help/account/provisioning-profiles/create-an-app-store-provisioning-profile).
- [TestFlight overview](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/) and [Developer Program](https://developer.apple.com/programs/).

Apple Arcade is a separate curated opportunity, not an automatic promotion or a prerequisite for this release.
