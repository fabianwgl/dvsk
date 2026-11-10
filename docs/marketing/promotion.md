# Dvsk promotion plan

Written by the marketing role on 2026-10-13. This is a plan. Nothing was posted, sent or published, and nobody was contacted.

How to read it: every market or audience claim has a URL next to it. "Estimate" is my own guess, with its basis. "Unknown" means I found no source. Time figures are estimates from the size of each task; none were measured. Cash cost is $0 unless a row says otherwise. Money options are in [monetization.md](monetization.md).

## Summary

- Do not promote yet. First a notarized release must be published and checked on a downloaded copy. Today the only public build is v0.1.0, which is not notarized.
- Second gate: Apple has an open bug where the gamma call Dvsk uses has no visible effect on some new MacBook Pros. Dvsk is expected to be affected (not tested on Dvsk). Say so in the README before anyone arrives (DVSK-004).
- Best audience: developers and open-source fans. General Mac users already have free f.lux and built-in Night Shift.
- Plan: five Proposed entries, DVSK-004 to DVSK-008. Cash cost $0. The first four take about 8 to 12 hours (estimate, from task size).
- Measure by hand: stars, release downloads, GitHub traffic. No analytics in the app, because the overview promises no network.

## Where Dvsk stands (2026-10-13)

| Fact | Source |
|---|---|
| Repo created 2026-10-11. 0 stars, 0 forks, 0 watchers. Issues on, Discussions off, no website set. 13 topics, including f-lux, flux, night-shift, blue-light-filter, swift, macos, menubar-app. | https://api.github.com/repos/fabianwgl/dvsk |
| One release: v0.1.0, published 2026-10-11, one asset (Dvsk-0.1.0.dmg) with 1 download. | https://api.github.com/repos/fabianwgl/dvsk/releases |
| v0.1.0 is not notarized. main is at 0.1.1 with signing and notarization in the build script. v0.1.1 is not published and the cask still points to 0.1.0. Nobody has checked a downloaded 0.1.1. | Board DVSK-003 notes; [overview](../product/overview.md) |
| The README on main already says release builds are notarized, so it claims more than the only download does. | Board DVSK-003 notes; [decisions](../product/decisions.md) |
| The repo page shows no screenshot (fetched 2026-10-13). | https://github.com/fabianwgl/dvsk |
| Launch at login: implemented, Ready for QA with manual checks open (DVSK-001). Sunrise/sunset: Proposed only (DVSK-002). | Board |
| What v0.1.0 does: fixed-time schedule (default 20:00 to 07:00, 30-minute fade), night temperature slider, Darkroom mode, disable for an hour, colours restored on quit, `Dvsk --reset`. | [decisions](../product/decisions.md) ("Same features as 0.1.0"), [README](../../README.md) |

## What to say

Pitch, true today (from the [overview](../product/overview.md)): "Dvsk is a small, free, open-source Mac menu bar app that makes your screen warmer in the evening. It is a proof of concept, kept small and readable."

Honest positioning (my wording): it does less than f.lux and Night Shift (fixed times only). Reasons to look at it: MIT license, small readable Swift code, no account, no network, Homebrew install.

| Say today (true of v0.1.0 and the code) | Hold until true and checked | Avoid |
|---|---|---|
| Warms the screen at fixed times (default 20:00 to 07:00) with a 30-minute fade. Night temperature slider, 1200K to 6500K. Darkroom (all-red) mode. Disable for an hour. Colours return when you quit; `Dvsk --reset` if the screen stays tinted. MIT. No account, no network. Install by Homebrew or DMG. | "Signed and notarized, opens with no warning": until v0.1.1 or later is published and a downloaded copy is checked. "Launch at login": until it ships. "Sunrise/sunset": until it ships. "Works on your Mac": never without the M5 caveat (see "The gate" below). | Sleep or health claims. "Better than f.lux". Asking anyone to upvote. |

Why no health claims: Wikipedia's f.lux article cites a 2021 study of 167 undergraduates that found Night Shift had no effect on sleep outcomes ([article](https://en.wikipedia.org/wiki/F.lux)). In the 2026 Hacker News thread on a similar app, commenters dispute the sleep benefit ([thread](https://news.ycombinator.com/item?id=49124214)). Apple's own page says evening blue light can affect circadian rhythms ([Apple](https://support.apple.com/en-us/102191)). The claim is disputed in the places you will post, so say "warmer screen at night" and stop there.

## What readers will compare it to

| Tool | What it is | Source |
|---|---|---|
| f.lux | Free on macOS and Linux. Sets colour by sunrise and sunset at a chosen location. Released 2009, by F.lux Software LLC. | https://justgetflux.com, https://en.wikipedia.org/wiki/F.lux |
| Night Shift | Built into macOS. Sunset-to-sunrise or custom schedule, warmth slider. Needs macOS Sierra 10.12.4 or later. | https://support.apple.com/en-us/102191 |
| Open-source Mac tools | Lumen (GPL-3.0), Shifty (GPL-3.0), Shady, Brisync (MIT). Redshift, Desktop Dimmer and Nocturne are marked discontinued. | https://alternativeto.net/software/f-lux/?platform=mac&license=opensource |
| Paid or freemium | Iris (freemium), Solace (paid, Mac only). | https://alternativeto.net/software/f-lux/ |
| Drift | Posted on Hacker News on 2026-07-31 as a f.lux alternative. Its author says it uses Night Shift directly, not gamma tables. Price and license: unknown (its site did not load for my fetch and the thread does not say). | https://news.ycombinator.com/item?id=49124214 |

## The gate: Apple's gamma bug (as read on 2026-10-13)

- Apple Developer Forums, thread opened March 2026: `CGSetDisplayTransferByTable` has no visible effect on MacBook Pro M5 Pro and M5 Max, and on MacBook Neo with an external display. Reports cover macOS 26.3 to 26.5.1. An Apple DTS engineer reproduced it on an M5 Max: the calls return success and the read-back is correct, but the screen does not change. Apps named: BetterDisplay, MonitorControl, f.lux, Lunar. The latest Apple reply, about a week before I read it, says the bugs are still open and under investigation. https://developer.apple.com/forums/thread/819331
- An earlier thread (July 2025) on the same call during the Tahoe betas. One user there reports a fix in Tahoe developer beta 5, and that the call had no effect with "Automatically adjust brightness" on. https://developer.apple.com/forums/thread/795074
- The [README](../../README.md) says Dvsk writes to every display with `CGSetDisplayTransferByTable`. So Dvsk is expected to be affected. It is not tested on Dvsk: nothing in the project docs says which Macs it has run on (a `[pm]` question in the report).
- Because Apple's reply says the read-back is correct, reading the table back would probably not reveal the failure (my reading of the DTS reply, not tested). An in-app warning would need another signal, such as the Mac model. That is a product decision, not proposed here.

## Audiences and channels

| Audience | Where they already are | Evidence | Fit |
|---|---|---|---|
| Developers and open-source fans (the overview's second audience) | GitHub search and topics; Hacker News; Swift Forums Community Showcase; the open-source-mac-os-apps list | Hacker News has 7 stories matching "f.lux alternative" between 2010 and 2026. The newest (2026-07-31) has 25 points and 21 comments; the others 1 to 4 points ([search](https://hn.algolia.com/api/v1/search?query=f.lux%20alternative&tags=story&hitsPerPage=10)). Developers are also asking Apple about the same call ([thread](https://developer.apple.com/forums/thread/819331), 13 replies). | Best fit. Estimate: a small but real audience. |
| Mac users who want a free, open-source, no-account warm screen (the overview's first audience) | AlternativeTo's f.lux page (60 alternatives listed); MacMenuBar.com (1700+ menu bar apps); OpenAlternative; Homebrew users; r/macapps | See channel notes. | Weaker. f.lux and Night Shift are free and already do more. |
| f.lux users on M5 Pro/Max MacBooks who lost their tint | Apple's forums, the f.lux forum ([Mac OS X category](https://forum.justgetflux.com/category/5/mac-os-x), listed by my search, not opened) | [Apple thread](https://developer.apple.com/forums/thread/819331), [Hacker News](https://news.ycombinator.com/item?id=49124214) | Not reachable. Same call, so Dvsk is expected to fail the same way. Do not target them and do not promise. |

## Channel notes (rules read on 2026-10-13)

- **GitHub repo.** Topics are set. Missing: a screenshot (the repo page shows none) and a website field (null in the API). Social preview image: not checked (DVSK-005 covers it). Traffic data shows "visitors from the past 14 days" and needs push access ([docs](https://docs.github.com/en/repositories/viewing-activity-and-data-for-your-repository/viewing-traffic-to-a-repository)).
- **Homebrew tap.** Keep `fabianwgl/tap`. The official cask needs one of 30 forks, 30 watchers or 75 stars, and 90 forks, 90 watchers or 225 stars when the owner submits it. A repo under 30 days old is normally not eligible, so 2026-11-10 at the earliest ([policy](https://docs.brew.sh/Package-Acceptance-Policy)). Not now.
- **open-source-mac-os-apps** (about 50.8k stars, 430 open pull requests, so a merge may be slow: estimate). Add an entry to `applications.json` by pull request, one per suggestion. Template fields include `icon_url` and `screenshots`. Projects are ineligible if they lack a recent commit or have an unclear or non-English README, and may be removed if they lack a license or do not build in the current Xcode. No star minimum is stated. https://github.com/serhii-londar/open-source-mac-os-apps and its [CONTRIBUTING.md](https://raw.githubusercontent.com/serhii-londar/open-source-mac-os-apps/master/CONTRIBUTING.md)
- **awesome-mac.** Rules unknown: both CONTRIBUTING URLs I tried returned 404. Read the repo's README before submitting. https://github.com/jaywcjlove/awesome-mac
- **MacMenuBar.com.** "A curated directory of 1700+ Mac menu bar apps", with an Open Source tag and no night-mode category (nearest: display apps, color apps). The submit form is for "true macOS menu bar apps only" and is reviewed manually. Fee: unknown. https://macmenubar.com/ and https://macmenubar.com/submit-your-menu-bar-app/
- **AlternativeTo.** The f.lux page lists 60 alternatives and not Dvsk. Lists are crowd-sourced and the page has an "Add Alternatives" option. How submissions are reviewed: unknown. https://alternativeto.net/software/f-lux/
- **OpenAlternative.** Has a "Submit" link and a menu bar app tag. Requirements and fees: unknown (the page did not show them). https://openalternative.co/submit and https://openalternative.co/tags/menu-bar-app
- **Show HN.** "Show HN is for something you've made that other people can play with." Make it easy to try, ideally without signups. "Please don't ask friends to upvote or comment." No landing pages or fundraisers. https://news.ycombinator.com/showhn.html
- **Swift Forums, Community Showcase.** "Announcements of Swift-related content, conferences, projects, and products." https://forums.swift.org/c/community-showcase/66
- **r/macapps.** reddit.com is blocked for my fetch tool, so I read the sidebar through a mirror: https://redlib.groet-infra.nl/r/macapps. Rule 1: "Use PCP Post template" and "Open Source? Prefix title [OS]". Rule 2: download links must use the publisher's official source. Rule 3: "Infrequent self-promotion is permitted; however, it is not permitted more than once per developer in 30 days", and "Always disclose your relationship to your software". Rule 8: developers who do not qualify through trust or transparency "must limit promotion to the monthly Megathread". Rule 9: posts require approval. Unconfirmed (from a search summary of mirrored moderator posts; I could not open the originals): the main-feed route for GitHub projects needs 10+ local karma, 1 year or more of development history and 100+ stars on the promoted repo, and another route asks for a real identity and portfolio. With 0 stars, the megathread is the realistic route. Check reddit.com/r/macapps before posting.
- **Not researched** (rules unknown): other subreddits, Product Hunt, X, Mastodon, Bluesky, newsletters. Read each community's rules before posting there.

## Actions

Time is an estimate from task size. "Board" says which entry carries the action, or why none does.

| # | Action | Cadence | Cash | Time (estimate) | Board |
|---|---|---|---|---|---|
| 1 | Publish v0.1.1 or later (tag, Release with the notarized DMG), update the cask, check a downloaded DMG and the brew install on a Mac that has never seen Dvsk | Once, then each release | $0 beyond the Apple membership (about $99 per year) | user step | None: covered by DVSK-003 (criteria 3 and 4 are these checks) |
| 2 | Edit the v0.1.0 release notes to say it is superseded (they still say "isn't notarized") | Once | $0 | 5 minutes | None: user step, part of publishing |
| 3 | Decide whether launch at login is in the release you promote | Once | $0 | none | None: DVSK-001 plus a `[pm]` question in the report |
| 4 | Name the Apple gamma bug in the README and overview; add an issue template | Once | $0 | 1 hour | DVSK-004 |
| 5 | README screenshots and a social preview image | Once; redo when the UI changes | $0 | 1 to 2 hours | DVSK-005 |
| 6 | Submit to AlternativeTo, MacMenuBar.com, OpenAlternative and open-source-mac-os-apps | Once | $0 (fees unknown for two of them) | 2 hours | DVSK-006 |
| 7 | Show HN and Swift Forums showcase posts | Once at launch | $0 | 2 hours writing, about 3 hours answering | DVSK-007 |
| 8 | One r/macapps megathread post | Once; the sub allows one promotion per developer in 30 days | $0 | 45 minutes | None: optional, only if you say yes to open question 2; it would join DVSK-007 |
| 9 | Technical write-up on tinting a display with gamma tables | Once | $0 | 4 to 6 hours | DVSK-008 |
| 10 | Per release: release notes, plus at most one short post in one channel | Each release | $0 | 30 to 60 minutes | None: routine at each release |
| 11 | Write down stars, downloads and referrers | Weekly for 4 weeks after launch | $0 | 10 minutes | None: logged by hand in the Results log below |
| 12 | Answer issues and comments | Best effort | $0 | unknown | None: ongoing; set the expectation with one README line ("best effort") |
| 13 | GitHub Sponsors button | Not now | $0 | 1 to 2 hours | None: not worth doing now (see monetization.md) |
| 14 | Official Homebrew cask submission | Not now | $0 | unknown | None: not possible yet (thresholds in channel notes) |
| 15 | Product Hunt, paid ads, landing page or domain, Mac App Store | Not now | not priced | n/a | None: not worth doing now (see "Not now") |

## Launch checklist

**A. Published and verified. Nothing else starts before this.**
- [ ] A1. v0.1.1 or later is published: tag, GitHub Release with the notarized DMG, and the cask in `fabianwgl/tap` points to it (user step).
- [ ] A2. A DMG downloaded from that Release opens with no override step on a Mac that has never seen Dvsk. `brew install --cask fabianwgl/tap/dvsk` gives the same version and opens the same way (DVSK-003 criteria 3 and 4). Nobody has checked this yet.
- [ ] A3. The v0.1.0 release notes say it is superseded.
- [ ] A4. The README, the Release notes and every post claim only what that download does. Launch at login only if it is in that release. Sunrise/sunset only if it has shipped.

**B. The page** (B1 and B2 can start now; they do not depend on A)
- [ ] B1. DVSK-004 done: the Apple gamma bug is named, the issue template asks for Mac model, macOS version and display.
- [ ] B2. DVSK-005 done: screenshots in the README, social preview set.
- [ ] B3. The README says support is best effort (one line).

**C. Listings** (after A and B)
- [ ] C1. DVSK-006: four submissions made; dates and status written in the Results log.

**D. Launch day** (after A, B and C)
- [ ] D1. Pick a day when you can answer comments for about three hours (estimate).
- [ ] D2. DVSK-007: Show HN, then the Swift Forums showcase post, using the drafts below updated to what is true that day. Say you are the author. Do not ask anyone to upvote.
- [ ] D3. Answer "does it work on my M5 Pro/Max?" with the README line.

**E. After**
- [ ] E1. Write the weekly numbers for 4 weeks in the Results log.
- [ ] E2. Reply to issues; each "tint does nothing" report goes to DVSK-004's template fields.
- [ ] E3. Write what worked. Decide on DVSK-008 and on the monetization triggers.

## Measuring (no telemetry)

- Stars, forks, watchers: the repo page or `https://api.github.com/repos/fabianwgl/dvsk`.
- Downloads: `download_count` per asset in `https://api.github.com/repos/fabianwgl/dvsk/releases` (1 for v0.1.0 on 2026-10-13).
- Referrers and views: GitHub Insights, Traffic. It keeps only the past 14 days, so copy the numbers weekly.
- Issues: the count, and how many say the tint does nothing.
- Homebrew tap installs: unknown, not checked.
- No in-app analytics. The overview promises no network, and adding any would break it.

Results log:

| Date | Stars | Forks | Watchers | Release downloads | Note |
|---|---|---|---|---|---|
| 2026-10-13 | 0 | 0 | 0 | 1 (v0.1.0) | Baseline. Repo created 2026-10-11. |

## Not now

- Official Homebrew cask: thresholds above, and the repo is under 30 days old.
- GitHub Sponsors: see [monetization.md](monetization.md).
- Product Hunt: rules not researched, and Dvsk has no screenshots yet.
- Paid ads: they cost cash and I have no conversion data (unknown).
- Landing page or domain: the README is the page. A domain price is unknown (not checked), and upkeep is not worth it at 0 stars (estimate).
- Mac App Store: see monetization.md.
- Apple Developer Forums as an ad channel: no. Reply there only with a reproducible finding.

## Draft launch text (not posted)

Keep only lines that are true on the day. Add "notarized", "launch at login" or "sunrise/sunset" only after they ship and are checked. Say how Dvsk was built, including any AI tools, the way you decide in open question 3.

**Show HN.** Title: `Show HN: Dvsk, a small open-source f.lux alternative for macOS`

> I made Dvsk, a menu bar app that makes the screen warmer in the evening. It is MIT licensed, has no account and makes no network calls.
>
> What it does: a fixed-time schedule (default 20:00 to 07:00) with a 30-minute fade, a 1200K to 6500K temperature slider, a red Darkroom mode, disable for an hour, and colours come back when you quit.
>
> What it does not do: there is no sunrise/sunset schedule. It writes gamma tables with CGSetDisplayTransferByTable, and Apple has an open bug where that call has no visible effect on MacBook Pro M5 Pro and M5 Max (developer.apple.com/forums/thread/819331). I expect Dvsk to be affected too. [Replace this sentence with the test result if you tested it.]
>
> It is a proof of concept, kept small so the code is easy to read: github.com/fabianwgl/dvsk
> I would like feedback on: [one specific question].

**Swift Forums, Community Showcase.** Title: `Dvsk: a small SwiftPM menu bar app that tints your displays at night`

> Dvsk (MIT) warms the screen in the evening. DvskCore holds the colour temperature and schedule logic (plain Swift, unit tested). Dvsk is the app: it writes gamma tables with CGSetDisplayTransferByTable and restores the original colours through ColorSync on quit. The repo has a build script that can sign and notarize a release. Known limit: Apple's open gamma bug on some M5 MacBook Pros (thread link). Feedback welcome on [X].

**r/macapps megathread** (only if you opt in). Prefix the title with `[OS]`, use their PCP template (the sidebar names it; its three parts are unconfirmed), and say you are the developer. Free, MIT, link to the Releases page.

## Open decisions (the plan assumes the default until answered)

1. Money: keep free, no ask (default). Alternatives are in [monetization.md](monetization.md). Option 7 there (a README line linking to your other work) can be combined with any choice.
2. Channels: GitHub, directories, Show HN and Swift Forums (default). The r/macapps megathread only if you say yes.
3. How Dvsk was built: answer plainly when asked, never deny (default).
4. `[pm]` Which Macs Dvsk has been run on, and what Known limits should say about the Apple bug (DVSK-004 depends on it).
5. `[pm]` Which release is promoted first: 0.1.1 as is, or the one that adds launch at login.
