# Dvsk running costs

Development token spend is out of scope.

| Item | Plan | Monthly cost | Why needed | Cheaper alternative | Status |
|---|---|---|---|---|---|
| GitHub repository, releases | Free | $0 | Source, DMG downloads | n/a | In use |
| GitHub Actions (CI, DMG build, tap update) | Free tier for public repos | $0 | Tests and release automation | n/a | In use |
| Homebrew tap (fabianwgl/tap) | A GitHub repo | $0 | `brew install` support | n/a | In use |
| Apple Developer Program (Developer ID signing and notarization) | Individual, about $99 per year (about $8.25 per month), verified via web search 2026-10-11 | about $8.25 | Lets the release build be signed and notarized, so macOS opens Dvsk without override steps. `scripts/bundle.sh` uses it since 0.1.1 (PR #1) | Build without credentials: the script still makes a DMG, with the app ad-hoc signed inside an unsigned DMG ($0), but macOS blocks its first launch and users must use "Open Anyway" | Likely in use since PR #1 (assumed, confirm). No notarized release is published yet |

## Notes on the Apple Developer Program line

- Assumed, confirm: the user accepts about $99 per year as a Dvsk cost. The signing in PR #1 (merged 2026-10-11) needs a Developer ID certificate, which needs a paid membership, so the account exists. Not known: whether it is paid for Dvsk alone or shared with other apps (then the extra cost for Dvsk is $0), and the renewal date. The cost question in DVSK-003 was not answered as asked.
- Assumed, confirm: if the membership lapses, new releases cannot be notarized; versions already notarized keep opening.
- As of 2026-10-13 the latest published release is v0.1.0, which is not notarized, so users do not get the benefit yet. Publishing v0.1.1 changes that.
