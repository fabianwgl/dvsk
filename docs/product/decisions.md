# Dvsk decisions

## Summary

- The code on main is Dvsk 0.1.1. PR #1 (merged 2026-10-11) put Developer ID signing and notarization into the build script. The only public release is still 0.1.0, which is not notarized (checked 2026-10-13).
- Approved 2026-10-13: Launch at login (DVSK-001), off by default. It is in the Backlog.
- Not selected, still Proposed: sunrise/sunset (DVSK-002; decided: location typed by hand only, alongside the fixed times as a choice) and the notarized release (DVSK-003; mostly done by PR #1, the user is asked whether to close it).
- Still assumed, confirm: the Apple Developer Program cost is accepted, and "0.2" means closing the gaps the README lists (now launch at login and sunrise/sunset).

## 2026-10-11 Understanding

*Superseded in part on 2026-10-13: this note was written against 0.1.0 because the local checkout was behind. See the 2026-10-13 Understanding below.*

**What I heard**
- Request: review the project and propose the next three entries toward a 0.2 release.
- Current state (0.1.0): fixed-time schedule (default 20:00 to 07:00, 30 minute fade), night temperature slider, darkroom mode, pause for an hour, safe restore on exit, `--reset` recovery, DMG and Homebrew cask distribution, unit tests for the colour and schedule logic.
- Gaps the README names: no launch at login, no sunrise/sunset support, app not notarized.

**Assumptions** (assumed, confirm)
- "0.2" is not defined by the user. I assume it means closing the gaps the README lists.
- Sunrise/sunset times come from a place the user enters, not from automatic location (see questions).
- Launch at login is off until the user turns it on.

**Success criteria for 0.2**
- A user can have Dvsk start by itself after login.
- A user can follow the sun instead of typing clock times.
- A user can install the DMG without any macOS override steps (depends on paying for an Apple developer account).

**Out of scope for this round**
- Cutting the release itself (raising the version from 0.1.0, tagging, release notes). Not proposed yet because the request caps this round at three entries.
- Automatic location, per-display settings, hotkeys, other new features.

## 2026-10-13 Understanding (round 2)

**New fact, and a correction to round 1**
- Round 1 was written from a checkout that was 3 commits behind origin/main, so it read 0.1.0. The code on main is 0.1.1.
- PR #1, "Sign and notarize release builds (0.1.1)", was merged by the user on 2026-10-11. It changed `README.md`, `AppInfo.plist`, `scripts/bundle.sh` and `scripts/render-cask.sh`.
- Read from the files, not run: when a Developer ID and a notary profile are set, the build script signs the app and the DMG, has Apple notarize both, attaches the proof, and checks the DMG. Without them it still builds a DMG, with the app ad-hoc signed inside an unsigned DMG. The README no longer asks users to override macOS and documents the signed build. The Homebrew cask template has no workaround step.
- Checked on GitHub (its API and the Homebrew tap, 2026-10-13): the only release is v0.1.0, published 2026-10-11, and its notes still say "isn't notarized" and give the "Open Anyway" steps. There is no v0.1.1 tag. The tap's cask is still 0.1.0 and still prints the quarantine caveat. So the README on main describes 0.1.1 builds, while nothing a user can download is notarized yet. Publishing v0.1.1 closes that gap.

**What I heard** (answers relayed by the main session)
- Approve Launch at login only. The other two entries were not selected, so they stay Proposed for later. They are not closed.
- Sunrise/sunset: the location is entered by hand only, and the schedule is offered alongside the fixed times as a choice.
- Launch at login: off by default.
- Not answered: the notarization cost, and whether "0.2" means closing the README gaps.

**Current state (0.1.1 code)**
- Same features as 0.1.0 (fixed-time schedule, night temperature slider, darkroom mode, pause for an hour, safe restore on exit, `--reset`), plus signed and notarized builds when the maintainer builds with credentials.
- Gaps the README names now: no launch at login, no sunrise/sunset support. The notarization gap is closed in the code but not published.

**Assumptions** (assumed, confirm)
- The Apple Developer Program cost (about $99 per year) is accepted. PR #1 needs a Developer ID certificate, which needs a paid membership, so the account exists. The user has not said they accept the cost as a Dvsk cost, or whether the membership is shared with other apps.
- "0.2" means closing the gaps the README lists. Today that is launch at login and sunrise/sunset, plus a published notarized build. The version number of the next release is not decided.
- Releases are built and signed on the maintainer's Mac. There is no release job in CI.
- Sunrise/sunset: the location is typed as latitude and longitude, with no built-in city list and no place-name lookup. The 5 minute accuracy limit is my proposal.
- Launch at login: at a start at login during the night, the screen is warm within 10 seconds. The limit is my proposal.

**Success criteria** (updated)
- A user can have Dvsk start by itself after login, and only if they turn it on (DVSK-001).
- A user can follow the sun instead of typing clock times, by typing their location once (DVSK-002, not selected yet).
- A user can install the published DMG or the Homebrew build without any macOS override steps. The code is done (PR #1); a published and checked release is what is left (DVSK-003).

**Out of scope**
- Cutting the release itself (tag, release notes, uploading the DMG) as a board entry. Still not proposed; this round adds no new entries.
- Builds signed in CI with credentials as CI secrets. Not proposed; it would be a new entry if wanted.
- Automatic location, a city list, per-display settings, hotkeys, other new features.

## Q&A log

The round 1 question wording is paraphrased from the round 2 request. The original texts are not stored in this file.

### 2026-10-13, round 2 (answers relayed by the main session)

1. Which of the three draft entries should move to the Backlog?
   - Answer: Launch at login (DVSK-001) only. Sunrise/sunset (DVSK-002) and the notarized release (DVSK-003) were not selected. The user was told "not selected = stays Proposed for later".
   - Effect: DVSK-001 moved to Backlog (Owner: sse). DVSK-002 and DVSK-003 stay Proposed. Neither is closed.
2. DVSK-002: where does the location come from?
   - Answer: Manual entry only.
   - Effect: no automatic location and no system location permission. Folded into the DVSK-002 criteria. That the location is typed as latitude and longitude is assumed, confirm.
3. DVSK-002: should sunrise/sunset replace the fixed times or sit next to them?
   - Answer: Alongside, as a choice.
   - Effect: the fixed times stay, and stay the default until the user switches. Folded into the DVSK-002 criteria.
4. DVSK-001: should Launch at login be on or off by default?
   - Answer: Off.
   - Effect: written into the DVSK-001 criteria: off on a fresh install and after an update, until the user turns it on.
5. DVSK-003: does the user approve the Apple Developer Program cost (about $99 per year)?
   - Answer: not answered.
   - Effect: kept as assumed, confirm. PR #1 implies the account exists. The costs.md line is updated to say so.
6. Does "0.2" mean closing the three gaps the README listed?
   - Answer: not answered.
   - Effect: kept as assumed, confirm. Two gaps are left in the README. The third (notarization) is done in the code but not published.

### Open question (asked 2026-10-13, awaiting answer)

7. DVSK-003: close it, keep it narrowed to what is left, or leave it as it is?
   - Fact given with the question: the README on main already says release builds are notarized, but the only public release (v0.1.0) and the Homebrew cask are still the un-notarized 0.1.0. PR #1 put signing and notarization into the build script.
   - Options: (A) keep it, narrowed to the checks. The user publishes v0.1.1 (it needs the user's signing identity, so this happens under any option); the board then tracks the checks: QA runs the signature checks on the published DMG, the user does the clean-Mac open and confirms the cost. It stays Proposed until the user approves it separately. (B) close it as "Won't fix (already delivered by PR #1)": the user publishes and checks v0.1.1 alone and nothing is tracked on the board. (C) leave it Proposed and unchanged, for later.
   - Recommended: A, because the README already claims notarized builds that nobody has checked on a published file.
   - If unanswered: the entry stays Proposed and unchanged, and no work starts. No option moves it to the Backlog.
