# Dvsk monetization

Written by the marketing role on 2026-10-13. This is a plan. Nothing was posted, bought, sent or published.

How to read it: every market claim has a URL next to it. "Estimate" is my own guess, with its basis. "Unknown" means I found no source. Effort and time figures are estimates from task size; none were measured.

## Summary

- Recommendation: keep Dvsk free and open source, with no donation link for now (option 1). Look again when a trigger under "When to revisit" is met.
- Revenue from any model today: unknown. Estimate: close to zero. Basis: on 2026-10-13 GitHub shows 0 stars, 0 forks and 0 watchers, and the only release (v0.1.0) has 1 download ([repo](https://api.github.com/repos/fabianwgl/dvsk), [releases](https://api.github.com/repos/fabianwgl/dvsk/releases)).
- The one recurring cost is the Apple Developer Program, about $99 per year ([costs.md](../product/costs.md)). It may already be shared with your other Mac apps; costs.md says that is not known.
- Free alternatives are strong, so a price is hard to defend: f.lux is free on macOS and Night Shift is built into macOS (sources below).

## Facts that shape the choice

| Fact | Source |
|---|---|
| Repo created 2026-10-11. 0 stars, 0 forks, 0 watchers, Discussions off. One release, v0.1.0, with 1 download of its DMG. Read 2026-10-13. | https://api.github.com/repos/fabianwgl/dvsk and https://api.github.com/repos/fabianwgl/dvsk/releases |
| f.lux is listed as free on macOS and Linux (free for personal use on Windows). | https://justgetflux.com |
| Night Shift is built into macOS: sunset-to-sunrise or custom schedule, and a warmth slider. | https://support.apple.com/en-us/102191 |
| AlternativeTo lists 7 open-source f.lux alternatives for Mac. Dvsk is not one of them. | https://alternativeto.net/software/f-lux/?platform=mac&license=opensource |
| BetterDisplay: Pro is $21.99 / €19.99, a perpetual license (not a subscription), with a 14-day trial. Many features are free for non-business use. | https://github.com/waydabber/BetterDisplay |
| Lunar: the free tier is limited to 100 adjustments per day. Pro is a $23 lifetime license, with a 14-day trial. | https://lunar.fyi/ |
| MonitorControl: MIT license, 34.5k stars, and no sponsor or donation link on its repository page (read 2026-10-13). | https://github.com/MonitorControl/MonitorControl |
| GitHub Sponsors charges no fee on sponsorships from personal accounts and up to 6% on those from organizations. Recipients must live in a supported region. | https://docs.github.com/en/sponsors/getting-started-with-github-sponsors/about-github-sponsors |
| A study of 8,028 maintainers, 13,555 sponsors and 22,515 sponsorships found a long-tail effect with most maintainers' expectations unmet. Sponsors mainly say thanks for software they use. Developer social status is the main factor in how many sponsorships a developer gets. | https://arxiv.org/abs/2111.13323 |
| Mac App Store Small Business Program: 15% commission for developers with up to 1 million USD in proceeds. The page does not state the standard rate. | https://developer.apple.com/app-store/small-business-program/ |
| Apple has an open bug where the gamma call Dvsk uses has no visible effect on some new MacBook Pros (details in promotion.md). | https://developer.apple.com/forums/thread/819331 |

## Options

| # | Model | Fit | Effort | Revenue range | Risks |
|---|---|---|---|---|---|
| 1 | Keep it free, no ask (today) | High. Matches the overview: "free, open-source", kept small. | None | None | You keep paying the Apple membership yourself (about $99 per year) unless it is shared. |
| 2 | Free, plus a GitHub Sponsors button | Medium. Users who like it can say thanks. No feature is locked. | S (estimate: 1 to 2 hours for the profile, payout and tax details, and a `FUNDING.yml`) | Unknown. Estimate: close to zero for now. Basis: 0 stars and 1 download today; the [arXiv study](https://arxiv.org/abs/2111.13323) found most maintainers' expectations unmet. | Your country must be on GitHub's [supported list](https://docs.github.com/en/sponsors/getting-started-with-github-sponsors/about-github-sponsors) (unknown for you; check). Payout and tax paperwork. Estimate (basis: 0 stars today): a funding ask on a proof of concept with no users looks early. |
| 3 | Free, plus a tip jar elsewhere (Ko-fi, Buy Me a Coffee, PayPal.me) | Low to medium. Same idea as option 2, with one more account to keep. | S | Unknown. Same basis as option 2. | Fees and terms: not checked (unknown). Not tied to GitHub, where Dvsk's users already are. |
| 4 | Free core, paid "Pro" license (as Lunar and BetterDisplay do) | Low. Dvsk has no feature worth locking. The source is MIT, so anyone can build every feature. f.lux and Night Shift are free. | M to L (estimate: license keys, a payment provider, support) | Unknown. Estimate: close to zero. Basis: no audience. The two neighbours that charge ($21.99 to $23) sell far larger feature sets. | Clashes with "free, open-source" in the overview. Support, tax and VAT duties: unknown. A paid tier in an MIT project can be bypassed by building from source. |
| 5 | Paid signed DMG, free source ("pay for convenience") | Low. The Homebrew cask and `swift run` stay free, so few people have a reason to pay. | M | Unknown. Estimate: close to zero. Basis as in option 4. | Blurs what is free. Needs a payment page and a place to host it. |
| 6 | Mac App Store (free or paid) | Low for now. | L (estimate: a different packaging and review path) | Unknown. Apple's commission is [15% under the Small Business Program](https://developer.apple.com/app-store/small-business-program/). | Unknown whether the gamma call works inside the App Store sandbox; not checked. The open Apple gamma bug (above). App Review. |
| 7 | Indirect: a line in the README linking to your other work, so Dvsk acts as a portfolio piece | Depends on you. | S (estimate: 15 minutes) | Indirect and unknown. | Needs you to link your name or company. A tool that does nothing on some Macs reflects on the link. |

Options 1, 2, 3 and 7 keep Dvsk free. Options 4 and 5 change what the project is.

## Recommendation

Option 1 now. Reasons:

1. There is no audience to ask yet: 0 stars, 1 download.
2. The overview calls Dvsk free and open source, kept small. A price or a paid tier changes that.
3. The same need is already covered for free: f.lux, Night Shift, and several open-source Mac tools on [AlternativeTo](https://alternativeto.net/software/f-lux/?platform=mac&license=opensource).
4. Apple's open gamma bug means the tint may do nothing on some new MacBook Pros ([thread](https://developer.apple.com/forums/thread/819331)). That is a poor moment to ask for money.
5. The neighbours that charge sell large feature sets. The MIT neighbour with 34.5k stars (MonitorControl) shows no donation link on its repo page.

If a trigger below is met, add option 2, not a paid model. GitHub is where Dvsk's users already are, personal sponsorships carry no GitHub fee, and nothing gets locked. Set it up only then, because it needs payout and tax details in a supported region.

Option 7 is separate and cheap. It needs your decision on whether to link your name or company (a `[user]` question in the report).

## Costs (feeds PM cost control)

| Item | Cash | Time |
|---|---|---|
| Apple Developer Program, already in use | about $99 per year ([costs.md](../product/costs.md)) | none |
| Option 1 | $0 | none |
| Option 2 | $0 (no GitHub fee on personal sponsorships) | 1 to 2 hours once (estimate) |
| Options 4 to 6 | not priced: fees and tax handling unknown | days (estimate) |

This plan adds no new recurring cost.

## When to revisit

These are my suggestions, not data:

- Dvsk reaches 75 stars. That is the bar Homebrew uses for a project not submitted by its owner ([policy](https://docs.brew.sh/Package-Acceptance-Policy)), so it is a sign of a real audience.
- Someone asks how to support the project.
- Six months after the first notarized public release (an arbitrary checkpoint, estimate).

At the check, look at stars, release downloads (`download_count` in the [releases API](https://api.github.com/repos/fabianwgl/dvsk/releases)) and whether Dvsk has gained features that cost you ongoing work.

## Not checked (unknown)

- Fees and terms of Ko-fi, Buy Me a Coffee and PayPal.me.
- Whether your country is on GitHub's supported-region list.
- Whether `CGSetDisplayTransferByTable` works in the Mac App Store sandbox.
- Tax and VAT duties for any paid model.
- Whether the Apple membership is shared with your other apps.
