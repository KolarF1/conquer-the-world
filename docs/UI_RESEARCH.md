# Measuring Conquer the World against great Roblox UI

*Research as of 2026-11-01. Section 6 scores the working tree on that date, including uncommitted HUD work. It does not score a published build. All product ids are still 0, so paid items are hidden. Nothing in this project was run in Studio or on a phone for this report.*

## 1. Key findings

- **A great Roblox UI, as far as anyone can show, does five things:** it shows only what this moment needs, makes one main action obvious, keeps one visual language, stays readable on a small screen, and uses little text. Roblox, designers and player complaints all point this way. No public test on Roblox proves it. [official advice, community; tested: none found]
- **This research found no proof that UI causes success on Roblox.** No controlled test with published numbers was found. Every link between a UI and a game's popularity in this report is correlation. Roblox's tested numbers are about price, not layout. Your own Experiments would be stronger evidence than anything public. [unverified: a search found none; price tests measured by Roblox]
- **Mobile is the design case, with a precise meaning.** Roblox reported **83% of average daily accounts on mobile in 2025**. That counts accounts, not people, hours, sessions or spending, and the filing does not split phone from tablet. [official]
- **Roblox publishes few UI numbers, and most are advice.** It gives no target resolution, tap size or contrast ratio. Its only text-size figure is advice not to set `MinTextSize` below 9. It also gives a 16.67 ms frame check at the default 60 FPS cap, and recommended ceilings of 100 shadows on screen and 1000 gradients. Its strict rules are the odds rules for paid random items. Most other thresholds have to be our own choice. [official]
- **In first-minute captures, four popular non-strategy games show an always-on HUD (controls and readouts) of about 4.5-5.5% of a desktop screen. Strategy games show 7.2-20.6%.** These figures come from hand-placed boxes, good to about ±2-3 points, so the low end of the strategy range overlaps the others. Several captures are tutorial states, and genre may explain part of the gap. No phone capture of a Roblox map-strategy game exists in this research, which makes phone readability the largest open question. [measured]
- **Conquer the World is strong on structure and weak on proof.** It has a coded phone layout, not checked on a device in this research, touch alternatives to most hover, 44-logical-pixel targets on most touch controls, a policy check on crates and a contrast test. It has no real-device pass of the current HUD, no accessibility settings, no localization and no gamepad support, and its coverage budget is not enforced. [measured from source]
- **Five moves matter most, in order:** add per-item crate odds before release (the card shows rarities only, and the policy asks for every item), run one real phone and tablet pass, bring the phone HUD inside our own budget or change the budget on purpose, test map legibility on the smallest screens, and test how English-sized boxes behave under Roblox's automatic translation.
- **Release question for the owner:** an established game with 317.7M visits (2026-11-01) already uses the "Conquer The World" name. Section 7 sets out the facts. This report reaches no legal conclusion.

### How to read the labels

Every claim carries one of four labels. Some source notes use finer labels, mapped here.

| Label | Meaning here |
|---|---|
| **official** | Roblox filing, docs, API reference, legal page or staff post, or a standards body. Advice from these is still advice, not a test result. |
| **measured** | A number or fact someone observed: a Roblox-reported test, a study, Studio readings, hand-placed boxes on captures, API readings, or a direct reading of our source code ("measured from source", with file:line). |
| **community** | DevForum posts, designers, press, wikis, third-party trackers, and non-Roblox developers describing their own games. |
| **unverified** | Seen only in a search excerpt, with no traceable source, or arithmetic not observed in a running game. An official page known only from a search excerpt stays unverified. |

Other caveats that apply throughout:

- **Wording may be approximate.** Many docs and forum posts were read through a summarising fetch tool or as search snippets. Recheck the wording against the source before treating any line here as a rule.
- **Docs have no dates.** Roblox docs pages show no reliable date, so they are dated by the access date, 2026-11-01.
- **"Stale"** marks data or publication older than 18 months (before about May 2025).
- **Player sentiment is mostly developer feedback.** Reddit could not be read by search, direct fetch or browser. "Players" here are mostly developers reviewing each other's games on DevForum, and children are almost absent.
- **Age mix.** Roblox's age figures cover only age-checked users, not the whole audience.

## 2. Who plays and on what

### What the mobile figure measures

The primary series is the "Breakdown of Our Users / By Platform" chart in each annual filing. It is a **share of average daily active users (DAU) for the year**. [official]

| Year (average DAU) | Mobile | Desktop | Console | Filed | Source |
|---|---:|---:|---:|---|---|
| FY2025 (127M) | **83%** | 14% | 3% | 2026-02-11 | [10-K](https://www.sec.gov/Archives/edgar/data/1315098/000131509826000024/rblx-20251231.htm), [chart](https://www.sec.gov/Archives/edgar/data/1315098/000131509826000024/rblx-20251231_g2.jpg) |
| FY2024 (82.9M), stale | 80% | 17% | 3% | 2025-02-18 | [10-K](https://www.sec.gov/Archives/edgar/data/1315098/000131509825000033/rblx-20241231.htm), [chart](https://www.sec.gov/Archives/edgar/data/1315098/000131509825000033/rblx-20241231_g2.jpg) |
| FY2023 (68.4M), stale | 80% | 18% | 2% | 2024-02-21 | [10-K](https://www.sec.gov/Archives/edgar/data/1315098/000131509824000026/rblx-20231231.htm), [chart](https://www.sec.gov/Archives/edgar/data/1315098/000131509824000026/rblx-20231231_g2.jpg) |
| FY2022 (56.0M), stale | 78% | 20% | 1% | 2023-02-28 | [10-K](https://www.sec.gov/Archives/edgar/data/1315098/000131509823000035/rblx-20221231.htm), [chart](https://www.sec.gov/Archives/edgar/data/1315098/000131509823000035/rblx-20221231_g4.jpg) |

What that figure does and does not tell us:

- **It counts accounts.** A DAU is a logged-in user on a registered account per day, and one person can hold several accounts. [official, [FY2025 10-K](https://www.sec.gov/Archives/edgar/data/1315098/000131509826000024/rblx-20251231.htm)]
- **It does not say how a two-device player is assigned.** A text search of the FY2022-FY2025 filings found no rule, so a constant method cannot be confirmed. The FY2025 filing also says sessions may be tracked differently across devices. [official, same filing]
- **It does not split phone from tablet, and has no VR slice.** There is one "mobile" bucket. The filing does not say outright that tablets sit inside it. [official, same chart]
- **It is not hours, sessions or spending.** No primary source found splits those by device. Sites that say "80% of sessions" have relabelled the figure; the filing chart is DAU. [unverified, [Search Engine Land snippet](https://searchengineland.com/guide/roblox-users), [RoWatcher](https://rowatcher.com/news/mobile-vs-desktop-on-roblox-who-s-playing-what-in-2026)]
- **App-store revenue is a sales channel, not a device.** Apple plus Google took 44% of FY2025 revenue (29+15), down from 52% in the first nine months of 2020. Gift cards and web sales sit outside that, and a phone player can use them. [official, [FY2025 10-K](https://www.sec.gov/Archives/edgar/data/1315098/000131509826000024/rblx-20251231.htm), [S-1, stale](https://www.sec.gov/Archives/edgar/data/1315098/000119312520298230/d87104ds1.htm)]

**Disagreement.** GameAnalytics reports PC plus mobile at 48.39%, PC only at 37.56% and mobile-only at about 7-10% for 2025, which flatly contradicts the filing. Its data covers only games using its tool, and the labels were read through a summariser that may have swapped them. It is shown here and not used for device share. [measured but unverified as extracted, [GameAnalytics 2025](https://www.gameanalytics.com/reports/2025-roblox-report)] Other aggregator splits (72/25/3, about 70%) do not trace to a primary source. [unverified, [DemandSage](https://www.demandsage.com/how-many-people-play-roblox/), [rolearn](https://rolearn.dev/trend-reports/roblox-mobile-gaming-trends-2026)] An X post claims most revenue comes from the PC and console minority. The filings do not support that either way. [unverified, [X, snippet](https://x.com/Richmond_Lee/status/1967967045561253953)]

A single game's own split is better than any platform figure. The creator dashboard splits charts by computer, phone, tablet, console and VR, and warns that users on several devices can count more than once. [official, [Analytics dashboard docs](https://create.roblox.com/docs/production/analytics/analytics-dashboard)] Genre skew (roleplay toward mobile, some PvP toward PC) is stated without a source. [unverified, [RoWatcher](https://rowatcher.com/news/mobile-vs-desktop-on-roblox-who-s-playing-what-in-2026)]

### Region

Roblox publishes no device share by region or age. The audience has moved toward Asia-Pacific, and mobile share rose over the same years. A causal link is unproven.

| DAU by region | US and Canada | Europe | Asia-Pacific | Rest of world |
|---|---:|---:|---:|---:|
| FY2022, stale | 23 | 27 | 23 | 26 |
| FY2025 | 18 | 23 | 30 | 29 |

[official, [FY2022 chart](https://www.sec.gov/Archives/edgar/data/1315098/000131509823000035/rblx-20221231_g3.jpg), [FY2025 chart](https://www.sec.gov/Archives/edgar/data/1315098/000131509826000024/rblx-20251231_g2.jpg)]

- About 82% of FY2025 DAU but only 39% of revenue came from outside the US and Canada. [official, [FY2025 10-K](https://www.sec.gov/Archives/edgar/data/1315098/000131509826000024/rblx-20251231.htm)]
- Q2 2026 revenue by billing country: US and Canada 57%, Europe 21%, Asia-Pacific 12%, rest of world 10%. [official, [10-Q](https://www.sec.gov/Archives/edgar/data/0001315098/000162828026051082/rblx-20260630.htm)]
- Q3 2026 DAU growth year on year: India +37%, Japan +33%, Saudi Arabia +30%, Germany +13%, France +12%. [official, [Q3 2026 letter](https://s27.q4cdn.com/984876518/files/content_files/Q3-2026-Earnings-Shareholder-Letter.pdf)]

So the region that spends most is not the region driving audience growth. Paying and non-paying players may need different things from language and device support.

### Screens and hardware

- **Roblox publishes no target resolution, aspect ratio or minimum tap size.** It says to design for mobile first (staff post, 2024-07-17, stale) and to test on an Entry level phone. [official, [staff post](https://devforum.roblox.com/t/designing-ui-tips-and-best-practices/3074034), [Device Simulator docs](https://create.roblox.com/docs/studio/device-simulator)]
- **Memory:** a staff post advises under about 1.3 GB of client memory to support 2 GB phones. It also says its CPU and rendering budgets give 60 FPS on most phones. That is a claim about those budgets, not a device census. [official, stale, [2024-08-20](https://devforum.roblox.com/t/real-world-building-and-scripting-optimization-for-roblox/3127146)]
- **Crash flag:** Roblox analytics flag a game when 5% or more of concurrent users are on Android devices under 2 GB and the crash rate is well above average. Out-of-memory is named as a common crash cause. [official, stale, [2024-09-03](https://devforum.roblox.com/t/analytics-optimize-low-end-android-crash-rates-server-memory-and-cpu-performance/3145364)] No share of players by RAM, chipset or OS is published.
- **Blurrier textures:** devices at 4 GB or less drop texture detail. The effect on UI images is unchecked. [unverified, official per snippet, [thread](https://devforum.roblox.com/t/all-materials-and-many-textures-and-decals-very-blurry-on-4-gb-ram-mobile-devices-even-in-a-baseplate-game-at-60-fps-major-bug/3414955)]
- **Minimum OS disagreement:** the help page says iOS 14, and a later recap says iOS 13 and 14 support ends 2026-06-01. Both were seen only as snippets, and the newer one likely wins. [unverified, [help article](https://en.help.roblox.com/hc/en-us/articles/203625474-Roblox-Mobile-System-Requirements), [recap](https://devforum.roblox.com/t/weekly-recap-april-13-17-2026/4582794)]
- **Planning proxy, not Roblox data:** the top mobile web resolutions in October 2026 were 414x896 (12.67%), 360x800 (8.57%), 384x832 (7.24%), 390x844 (5.33%), 393x873 (4.43%) and 360x780 (3.31%). [measured, general web traffic, [StatCounter](https://gs.statcounter.com/screen-resolution-stats/mobile/worldwide)] In landscape that suggests a canvas only 360-414 logical pixels tall. How this maps to Roblox's viewport is untested.
- **New screen classes:** Roblox for smart TVs was announced. [unverified, official per snippet, [DevForum](https://devforum.roblox.com/t/roblox-is-coming-to-smart-tvs/4582709)] Browser play through WebAssembly is planned. [official via transcript, [Q3 2026 call, 2026-10-29](https://www.fool.com/earnings/call-transcripts/2026/10/30/roblox-rblx-q3-2026-earnings-call-transcript/)]

### Age

These figures cover **age-checked users only**. They are not the whole audience.

| As of | Share of global DAU age-checked | Under 13 / 13-17 / 18+ among those checked | Source |
|---|---:|---:|---|
| 2026-01-31 | 45% | 35 / 38 / 27 | [Q4 2025 letter](https://www.sec.gov/Archives/edgar/data/1315098/000131509826000009/ex991-q42025shareholder.htm) |
| End Q1 2026 | 51% | 36 / 38 / about 26 | [Q1 2026 letter](https://www.sec.gov/Archives/edgar/data/0001315098/000162828026028882/ex991-q12026earningsshar.htm) |
| End Q2 2026 | 57% | 35 / 38 / 27 | [Q2 2026 letter](https://www.sec.gov/Archives/edgar/data/0001315098/000162828026051059/ex991-robloxq22026earnin.htm) |
| End Q3 2026 | **64%** (13-17s over 80%) | **34 / 37 / 29** | [Q3 2026 letter](https://s27.q4cdn.com/984876518/files/content_files/Q3-2026-Earnings-Shareholder-Letter.pdf) |

[official]

- Roblox itself says this data is estimated, is not comparable to its older self-reported data and may not represent actual demographics. Teens are over-represented among the checked. [official, Q3 2026 letter]
- Rough whole-audience estimates, from the research notes' arithmetic: 13-17s are at most about 30% of DAU (Q3 2026), and under-18s about 69% (Q2 2026). The second depends on how Roblox estimates unchecked users, which is undisclosed. [unverified]
- The older self-reported series (under 13: 54% in 2020, about 40% in 2024) is stale and not comparable. The FY2025 filing dropped the age chart. [official, [FY2024 10-K](https://www.sec.gov/Archives/edgar/data/1315098/000131509825000033/rblx-20241231.htm), [FY2025 10-K](https://www.sec.gov/Archives/edgar/data/1315098/000131509826000024/rblx-20251231.htm)]
- Users without an age check cannot chat, so UI that relies on chat to teach or coordinate will not reach everyone. [official, [Kids and Select newsroom, 2026-06-16](https://about.roblox.com/newsroom/2026/06/age-based-roblox-kids-and-select-accounts-now-globally-available)]
- Roblox gives no reading-level number. Its docs say players generally skip text, more text means more misreading, and teaching without words helps those still learning to read. [official, advice, [Onboarding techniques](https://create.roblox.com/docs/production/game-design/onboarding-techniques)]

The practical range runs from early readers to adults. Roblox calls 18+ its fastest-growing group, and says US 18+ users monetise 50% above under-18s. [official, Q3 2026 letter] Nothing cited tests what tone or text level either group prefers.

### Time and retention

- **Platform:** 2.7 hours per DAU per day in 2025, across all experiences, and including Studio, chat, avatar features and some non-active time. It is not a session length. [official, [FY2025 10-K](https://www.sec.gov/Archives/edgar/data/1315098/000131509826000024/rblx-20251231.htm)]
- **Inside a game:** a median session of about 6.6 minutes and about 2 sessions a day per user, among games on one analytics network. [measured, third party, [GameAnalytics 2025](https://www.gameanalytics.com/reports/2025-roblox-report)]
- **Retention:** median Day 1 is about 4-11% and median Day 7 about 0.4-1.8%, rising with the game's session length. That is correlation and says nothing about UI. [measured, same report]
- **Disagreement:** Roblox's docs give an example benchmark of 12.11-18.73% Day 1 at the 50th-90th percentile, which does not line up with GameAnalytics. Samples and definitions differ. Use your own dashboard's benchmark. [official, example only, [Analytics dashboard docs](https://create.roblox.com/docs/production/analytics/analytics-dashboard)]
- **First minutes:** Roblox advises fun "ideally in 5 minutes or less". This is advice, not a measured threshold. The dashboard's New User First Session Retention chart shows a game's own early drop-off. [official, [Retention](https://create.roblox.com/docs/production/analytics/retention), [Engagement](https://create.roblox.com/docs/production/analytics/engagement)]

With single-digit or about 10% median Day 1 retention, most new players see a game once, so the first session is the main audience for the UI. This does not show that UI is what loses them.

## 3. How Roblox UI works

Reference material as of 2026-11-01. Property names are exact. Studio readings ("measured") were taken in Studio 0.745.0.7451137 in Edit mode on unparented instances. Beta flags were not inspected, so a property being readable does not prove it can be published, and layout and on-device behaviour were not tested.

### What you can ship, what is beta, what does not exist yet

| Status | Feature | Evidence |
|---|---|---|
| **Shippable** | `UICorner` per-corner radii; `UIShadow` base (`BlurRadius`, `Color`, `Transparency`, `Offset`, `Spread`, `ZIndex`, `Enabled`) | official, [full release 2026-06-23](https://devforum.roblox.com/t/full-release-new-ui-capabilities-shadows-individual-corners/4636263) |
| **Shippable** | `UIStroke` `StrokeSizingMode`, `BorderStrokePosition`, `BorderOffset` | official, [full release 2025-12-04](https://devforum.roblox.com/t/full-release-uistroke-improvements-scaling-offsets-and-more/3958036) |
| **Shippable** (docs lag) | `UIGradient` `Type`, `TileMode`, `Scale` | official, [full release 2026-10-29](https://devforum.roblox.com/t/full-release-upgraded-ui-gradients/4846594); see disagreement below |
| **Shippable** | UI Styling and Style Editor (`StyleRule`, `StyleSheet`, `StyleLink`, `StyleDerive`) | official, [full release 2026-01-20](https://devforum.roblox.com/t/full-release-ui-styling-is-officially-released/4275082) |
| **Shippable** | Styling Transitions | official, [full release 2026-07-27](https://devforum.roblox.com/t/full-release-styling-transitions/4646870) |
| **Shippable** | Input Action System (`InputContext`, `InputAction`, `InputBinding`) | official, [full release 2026-06-11](https://devforum.roblox.com/t/full-release-input-action-system-ias-newly-converted-player-scripts/4678416) |
| **Shippable** (opt-in) | Roblox's personalised Shop, off by default | official, [2026-06-24](https://devforum.roblox.com/t/introducing-shop-a-personalized-in-game-storefront/4701505) |
| **Beta: cannot publish** | `UIShadow` `Mode = Text`, `Inset`, `ShowBehindParent = false`, child `UIGradient` | official, [Studio beta 2026-10-14](https://devforum.roblox.com/t/studio-beta-upgraded-uishadow-capabilities/4934553) |
| **Beta** | `InputActionLabel` and Input Action Manager. Snippets say IAS instances made through the manager can be published. | official for beta status, [docs](https://create.roblox.com/docs/input/input-action-system); unverified for publishing, [manager](https://devforum.roblox.com/t/studio-beta-input-action-manager/4737890), [label](https://devforum.roblox.com/t/studio-beta-no-code-hotkey-hints-with-inputactionlabel/4779420) |
| **Unreleased** | `UIBlur` | See disagreement below |
| **Announced** | Player scripts default to IAS: phase 2 early 2027, property removed mid 2027 (both estimates) | official, [IAS post](https://devforum.roblox.com/t/full-release-input-action-system-ias-newly-converted-player-scripts/4678416) |
| **No public release found** | Foundation, Roblox's own component library; any official Figma importer | community, [Fusion Foundation port](https://devforum.roblox.com/t/fusion-foundation-a-fusion-port-of-robloxs-foundation-library-used-to-create-native-components/4706377); searches found no official docs |

**Disagreements in Roblox's own material.** These are shown rather than settled silently.

| Topic | One source says | Another says | Working position |
|---|---|---|---|
| Gradient features | [Docs](https://create.roblox.com/docs/ui/appearance-modifiers): need a beta flag | [Announcement, 2026-10-29](https://devforum.roblox.com/t/full-release-upgraded-ui-gradients/4846594): flag removed | The dated announcement is newer. Docs appear stale. |
| Device Simulator | [Docs](https://create.roblox.com/docs/studio/device-simulator): beta | [Recap, October 12-18, 2026](https://devforum.roblox.com/t/weekly-recap-october-12-18-2026/4938638): out of beta | The recap is probably current. Other docs still say "device emulator", and no doc says one replaces the other. |
| UI blur | [RDC26 post, 2026-09-11](https://devforum.roblox.com/t/rdc26-what-we-announced/4865880): late 2026 | [Roadmap, page last updated September 2026](https://create.roblox.com/updates/roadmap): early 2027 | Do not plan on it. An apparent staff member called it unreleased on [2026-10-11](https://devforum.roblox.com/t/replace-uiblurunreleased-with-a-general-purpose-uibackdropfilter-system/4926590) (community, staff status inferred). `Instance.new("UIBlur")` succeeds (measured), which does not show it renders or publishes. |
| Text shadows | [Roadmap, page last updated September 2026](https://create.roblox.com/updates/roadmap): "Live" | [Studio beta post, 2026-10-14](https://devforum.roblox.com/t/studio-beta-upgraded-uishadow-capabilities/4934553): cannot publish | The dated post wins. Treat as beta. |
| `ZIndexBehavior` default | [Docs](https://create.roblox.com/docs/reference/engine/classes/LayerCollector.md): Sibling | Studio: `Instance.new("ScreenGui")` returned Global (measured) | Set it explicitly in scripts. A Studio-inserted ScreenGui was not checked. |
| Where to place a top meter | [ScreenInsets](https://create.roblox.com/docs/reference/engine/enums/ScreenInsets.md): `CoreUISafeInsets` for important items | [HUD tutorial](https://create.roblox.com/docs/tutorials/use-case-tutorials/ui/create-hud-meters): `DeviceSafeInsets` to save space | Both are official. Check overlap per device. |
| UI image size limit | [ImageLabel docs](https://create.roblox.com/docs/reference/engine/classes/ImageLabel.md): no maximum stated. [4K post](https://devforum.roblox.com/t/4k-texture-rendering/4316229) does not list UI instances. | [Community, 2026-06-30](https://devforum.roblox.com/t/decal-uploads-are-still-limited-to-1024x1024/4710639): uploads still shrink to 1024. One [unverified report](https://devforum.roblox.com/t/how-to-implement-sprite-sheets-correctly/4714044) mentions 8192. | Assume 1024 until tested. No official page confirms it. |
| Selection groups | [GuiService page](https://create.roblox.com/docs/reference/engine/classes/GuiService.md): `AddSelectionParent` and `AddSelectionTuple` create groups | [API source](https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/reference/engine/classes/GuiService.yaml): those and `RemoveSelectionGroup` are deprecated | Use `SelectionGroup` on `GuiBase2d`, and check before relying on it. |
| `ViewportDisplaySize` | [GuiService page](https://create.roblox.com/docs/reference/engine/classes/GuiService.md) metadata: ReadWrite | Same page's description and [API source](https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/reference/engine/classes/GuiService.yaml): read-only | Treat as read-only. |
| Auto-translate languages | [Docs](https://create.roblox.com/docs/en-us/production/localization/automatic-translations.md): 18 | [2022 post](https://devforum.roblox.com/t/auto-translate-for-all-more-languages-and-new-feedback-program/1843258): 15. [FY2024 10-K, excerpt](https://www.sec.gov/Archives/edgar/data/1315098/000131509825000033/rblx-20241231.htm): 16 | Current docs win. The older counts are probably dated, not wrong. |
| External social links | Earlier forum update reportedly 13+ | [Newsroom, 2026-06-16](https://about.roblox.com/newsroom/2026/06/age-based-roblox-kids-and-select-accounts-now-globally-available), [Community Standards](https://about.roblox.com/community-standards): 16+ | The later sources win. |

### Layout and safe areas

**Sizing.** Roblox's docs recommend neither "always scale" nor "always offset". They recommend mixing on purpose. No official base resolution or `UIScale` formula was found. [official]

- `UDim2`: Scale is a percentage of the container, Offset is fixed pixels, and they add. Use Scale for responsive position and Offset for fixed spacing. [official, [Position and size](https://create.roblox.com/docs/ui/position-and-size)]
- `AnchorPoint`: defaults to (0,0). Growth starts from it, so a bottom-right button uses (1,1). Objects under a layout or size constraint lose full control of their position and size. [official, same page]
- `UIScale`: multiplies size and scales children and modifiers such as `UIStroke` and `UICorner`. [official, [Size modifiers](https://create.roblox.com/docs/ui/size-modifiers)]
- `UIAspectRatioConstraint` and `UISizeConstraint` both override layouts. `UITextSizeConstraint` sets a font range, and docs say not to set `MinTextSize` below **9**. [official, same page]
- `AutomaticSize` fits text and descendants, and `AnchorPoint` sets the growth direction. `ScrollingFrame` uses `AutomaticCanvasSize` instead. [official, same page]
- `TextScaled` fills a label and ignores `TextSize`. Docs say it suits BillboardGuis, should be paired with `UITextSizeConstraint` on-screen, and that `AutomaticSize` is generally preferred. [official, [TextLabel](https://create.roblox.com/docs/reference/engine/classes/TextLabel.md)]
- `GuiService.ViewportDisplaySize` reports Small (most tablets and handhelds), Medium (laptops and monitors) or Large (TVs), and can change at runtime. No doc gives a recipe for using it. [official, [GuiService](https://create.roblox.com/docs/reference/engine/classes/GuiService.md)]
- Orientation defaults to landscape. Set it with `StarterGui.ScreenOrientation` and `PlayerGui.ScreenOrientation`, and listen with `PlayerGui.CurrentScreenOrientation`. [official, [Mobile input](https://create.roblox.com/docs/input/mobile)]

**Safe areas.** `ScreenGui.ScreenInsets` takes one of four values. [official, [ScreenInsets](https://create.roblox.com/docs/reference/engine/enums/ScreenInsets.md)]

| Value | What it clears | Documented use |
|---|---|---|
| `None` | Nothing, so UI can land behind notches | Non-interactive content such as backgrounds |
| `DeviceSafeInsets` | Hardware cutouts, but not Roblox's core UI | Not recommended where content must clear core UI. The HUD tutorial uses it for a health meter to save space |
| `CoreUISafeInsets` (default) | Cutouts plus core UI, an area guaranteed unobscured | Buttons and status messages |
| `TopbarSafeInsets` | Limited to free top-bar space, changes dynamically | Small items beside Roblox's controls |

- ScreenGui defaults: `ClipToDeviceSafeArea = true`, `SafeAreaCompatibility = FullscreenExtension`, `IgnoreGuiInset = false`. Setting `IgnoreGuiInset` true under `CoreUISafeInsets` changes it to `DeviceSafeInsets`. [official, [ScreenGui](https://create.roblox.com/docs/reference/engine/classes/ScreenGui.md)]
- `FullscreenExtension` expands a covering background to full screen. Docs advise against it for new work, even though it remains the default. Staff confirmed a very thick `UIStroke` can trigger it. [official, [SafeAreaCompatibility](https://create.roblox.com/docs/reference/engine/enums/SafeAreaCompatibility.md), [2026-07-24](https://devforum.roblox.com/t/high-uistroke-thickness-unintendedly-increases-parent-ui-element-size-on-most-phones/4753842)]
- Roblox's notch advice: background art in a `None` ScreenGui, text and buttons in a safe-inset ScreenGui, and floating UI over edge-anchored UI. Test both orientations. [official, stale, [2022-12-08](https://devforum.roblox.com/t/notched-screen-support-full-release/2074324)]
- `Camera.ViewportSize` uses the device-safe viewport. `AbsolutePosition` and `InputObject.Position` use Core UI safe coordinates, so their origin is inset on notched devices. [official, stale, same post]
- `GuiService.TopbarInset` is a Rect for free top-bar space, and changes at runtime. `GetGuiInset` is not deprecated. [official, [GuiService](https://create.roblox.com/docs/reference/engine/classes/GuiService.md)]
- **Top bar height:** the reserved space grew from 36 to 58 pixels, with actual space varying by device. Roblox tied that height to tap-target practice. Experience controls cannot be hidden through `CoreGuiType`. Do not hardcode the height. [official, stale, [2023-08-28, updated 2024-02-20](https://devforum.roblox.com/t/studio-beta-for-experience-controls-available-now/2567355)] A 2024 test moved to user-pinned, left-aligned controls. [official, stale, [2024-06-18](https://devforum.roblox.com/t/updated-in-experience-controls-on-roblox/3028958)] Nothing newer was found, which does not prove there was no change.
- `GetInsetArea` exists, but all four values read the same in Edit mode, so real insets need a play session or a device. [measured] Bottom insets such as a home indicator are not described separately in the pages read.

**Containers.** Each of these has a defined job, and a layout takes over its siblings' position and size.

- `UIListLayout` with flex (`HorizontalFlex`, `VerticalFlex`, `Wraps`, plus `UIFlexItem` modes Grow, Shrink, Fill, Custom) is the adaptive row tool. `Padding` applies only between items. [official, [List and flex](https://create.roblox.com/docs/ui/list-flex-layouts)]
- `UIGridLayout` gives strict cells, `UITableLayout` gives data rows, and `UIPageLayout` gives pages. [official, [Grid and table](https://create.roblox.com/docs/ui/grid-table-layouts), [Page layouts](https://create.roblox.com/docs/ui/page-layouts)] `UIPageLayout` input defaults are on. [measured]
- `ScrollingFrame` clips by default, content can sit under the bar unless inset, and clipping fails for rotated containers and rounded corners. [official, [Scrolling frames](https://create.roblox.com/docs/ui/scrolling-frames)]
- `DisplayOrder` orders ScreenGuis, and `ResetOnSpawn` defaults to true. [official, [ScreenGui](https://create.roblox.com/docs/reference/engine/classes/ScreenGui.md), [LayerCollector](https://create.roblox.com/docs/reference/engine/classes/LayerCollector.md)]
- `SurfaceGui` and `BillboardGui` draw in the world, and interactive ones must be under `PlayerGui`. `ViewportFrame` renders 3D into 2D. [official, [In-experience containers](https://create.roblox.com/docs/ui/in-experience-containers), [Viewport frames](https://create.roblox.com/docs/ui/viewport-frames)]

### Visual tools

- `UICorner`: setting `CornerRadius` overwrites all four corner radii. [official, [2026-06-23](https://devforum.roblox.com/t/full-release-new-ui-capabilities-shadows-individual-corners/4636263)]
- `UIShadow`: an element can have several, `ZIndex` can only be negative, and shadows may look jagged on a large corner radius. At full release, text objects shadowed only the background rectangle. [official, same post]
- `UIStroke`: strokes do not affect layout and can overlap neighbours, so padding must allow for them. Only one contextual stroke per object. [official, [2025-12-04](https://devforum.roblox.com/t/full-release-uistroke-improvements-scaling-offsets-and-more/3958036)]
- `UIGradient`: colours now interpolate in linear space, not sRGB, so older gradients may look different. A banding regression on some dark gradients has a fix pending. [official, [2026-10-29](https://devforum.roblox.com/t/full-release-upgraded-ui-gradients/4846594)]
- 9-slice: `ScaleType = Slice`, `SliceCenter`, `SliceScale`. Sprite sheets use `ImageRectOffset` and `ImageRectSize`. [official, [ImageLabel](https://create.roblox.com/docs/reference/engine/classes/ImageLabel.md)]
- `CanvasGroup`: draws children as one flattened image, with `GroupTransparency`, and always clips. It needs `Sibling` `ZIndexBehavior`. [official, [CanvasGroup](https://create.roblox.com/docs/reference/engine/classes/CanvasGroup.md)]
- Rich text supports `<font>`, `<stroke>`, `<b>`, `<i>`, `<u>`, `<s>`, `<br/>`, `<uppercase>`, `<smallcaps>` and `<mark>`. Localization removes the tags, so they must be reapplied. [official, [Rich text](https://create.roblox.com/docs/ui/rich-text)]
- `TextService`: `GetTextSize` does not yield but supports only the Font enum. `GetTextBoundsAsync` yields and should be wrapped in `pcall`. [official, [TextService](https://create.roblox.com/docs/reference/engine/classes/TextService.md)]
- Deprecated on `GuiObject`: `Draggable`, `TweenPosition`, `TweenSize`, `TweenSizeAndPosition`, `Transparency`, `BackgroundColor`, `BorderColor`. [official, [GuiObject](https://create.roblox.com/docs/reference/engine/classes/GuiObject.md)]

### Input

- **Use the Input Action System for new work.** `ContextActionService` bind methods "aren't recommended for new work and are planned for deprecation". [official, [ContextActionService](https://create.roblox.com/docs/reference/engine/classes/ContextActionService.md)] Docs recommend one binding each for gamepad, keyboard and mouse, and touch. Esc, F9, F11, F12 and PrintScreen cannot be overridden. [official, [Input Action System](https://create.roblox.com/docs/input/input-action-system)]
- **Migration risk:** `Workspace.PlayerScriptsUseInputActionSystem` defaults to Disabled now, then Enabled in early 2027 (an estimate), which may break games relying on old scripts or input sinking. [official, [2026-06-11](https://devforum.roblox.com/t/full-release-input-action-system-ias-newly-converted-player-scripts/4678416)]
- **Choosing UI by device:** `PreferredInput` (KeyboardAndMouse, Gamepad, Touch, MicroGamepad) is the docs' pointer for mixed-input devices. `TouchEnabled` can report false on some touch-capable desktops. [official, [PreferredInput](https://create.roblox.com/docs/reference/engine/enums/PreferredInput.md), [UserInputService](https://create.roblox.com/docs/reference/engine/classes/UserInputService.md)]
- **Buttons:** `Activated` fires on click release, touch release and console A or cross. `MouseButton1Click` is described only in mouse terms. `SecondaryActivated` gives right-click or long press. `Interactable = false` blocks presses. `AutoButtonColor` has no effect on an `ImageButton` once `Image` is set. [official, [GuiButton](https://create.roblox.com/docs/reference/engine/classes/GuiButton.md), [Buttons](https://create.roblox.com/docs/ui/buttons), [GuiObject](https://create.roblox.com/docs/reference/engine/classes/GuiObject.md)]
- **Hover:** `MouseEnter` and `MouseLeave` are documented for the cursor, and no doc describes touch hover. Tooltips therefore need another route on touch. [official for the docs; the conclusion is an inference]
- **Gamepad:** `GuiNavigationEnabled`, `AutoSelectGuiEnabled`, `SelectedObject` and `GuiService:Select(parent)`, with `NextSelectionUp/Down/Left/Right`, `SelectionOrder` and `SelectionBehaviorUp/Down/Left/Right`. ButtonA confirms and ButtonB cancels. [official, [GuiService](https://create.roblox.com/docs/reference/engine/classes/GuiService.md), [Gamepad input](https://create.roblox.com/docs/input/gamepad)] Directional selection improved in August 2025 and is on by default. [official, [2025-08-06](https://devforum.roblox.com/t/introducing-improvements-to-directional-ui-selection-on-gamepad/3864317)]
- **Phone zones:** default controls occupy parts of the bottom-left and bottom-right corners. Most players use two thumbs. A button 40% below the top edge is reachable on a phone but almost unreachable on a tablet. Custom buttons can be placed relative to `JumpButton`. [official, [Position and size](https://create.roblox.com/docs/en-us/ui/position-and-size.md)]
- **Touch target size: Roblox gives no number,** only "large enough to tap reliably". [official, [Test on hardware](https://create.roblox.com/docs/performance-optimization/test-on-hardware)] The default jump button is 70 px on small screens and 120 px otherwise. [community with staff replies, stale, [thread](https://devforum.roblox.com/t/jump-button-and-thumbstick-sized-positioned-wrong-in-mobile-emulator/2861222)] Outside Roblox: Apple 44 pt, Material 48 dp, WCAG 24 CSS px (AA) and 44 (AAA), NN/g 1 cm. [unverified digest of official standards, [summary](https://specification.website/spec/accessibility/touch-target-size/); community for [NN/g, 2019](https://www.nngroup.com/articles/touch-target-size/)] The 24 px figure is challenged in an [open W3C issue](https://github.com/w3c/wcag/issues/1831). [community]
- **VR:** `VREnabled` exists, but `create.roblox.com/docs/input/vr` returned 404, so no official VR UI guidance was captured.

### Performance

- **Frame:** 60 FPS cap by default, so a frame over **16.67 ms** signals a problem. Measure in the client, not Studio. [official, [Identify performance issues](https://create.roblox.com/docs/en-us/performance-optimization/identify.md)]
- **Memory:** no numeric client limit in the docs. Investigate if crash rates rise above **2-3%**. [official, same page]
- **Images:** memory depends on pixels, not file size. 1024x1024 uses four times the memory of 512x512. **Most images need at most 512x512, and minor ones should be under 256x256.** [official, [Improve performance](https://create.roblox.com/docs/performance-optimization/improve)]
- **Recommended ceilings:** **100 or fewer `UIShadow` on screen** and **no more than 1000 gradients at once**. Identical gradients deduplicate. Animating `Offset` or `Rotation` is cheaper than animating colour. [official, [2026-06-23](https://devforum.roblox.com/t/full-release-new-ui-capabilities-shadows-individual-corners/4636263), [2026-10-29](https://devforum.roblox.com/t/full-release-upgraded-ui-gradients/4846594)]
- **Shadows:** `UIShadow` is stated to be consistently faster than 9-sliced images, with no number given. [official, same post]
- **Do not tween `UIStroke.Thickness` on text.** It renders and stores many glyph sizes each frame. [official, [Appearance modifiers](https://create.roblox.com/docs/en-us/ui/appearance-modifiers.md)]
- **`CanvasGroup`:** uses extra texture memory, capped by `QualityLevel`, and past the cap it **renders blank**. Static sizes are recommended. [official, [API source](https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/reference/engine/classes/CanvasGroup.yaml)] One bug report describes about 250 groups with strokes partly failing to render. [community, excerpt, [thread](https://devforum.roblox.com/t/problem-with-the-rendering-of-a-uistroke-on-a-canvasgroup/3243111)]
- **`ViewportFrame`:** no shadows or post-processing, and no official cost figure. [official, [API source](https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/reference/engine/classes/ViewportFrame.yaml)]
- **Per-frame work:** limit RunService use to where it is essential. Tween on the client, not the server. [official, [Improve performance](https://create.roblox.com/docs/performance-optimization/improve)]
- **Loading:** preload loading-screen and key menu images. Keep `ReplicatedFirst` lean and use basic UI there. Offer Skip when loading a lot. Do not build loading bars from `RequestQueueSize`. [official, same page, [ContentProvider source](https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/reference/engine/classes/ContentProvider.yaml)] Reports say `PreloadAsync` on ImageLabels can still leave a short render delay. [community, excerpt, [thread](https://devforum.roblox.com/t/contentprovider-doesnt-preload-imagelabels/4039525)]
- **Tools:** Developer Console (F9), with memory categories `GraphicsTexture`, `Gui`, `Signals` and `Instances`. Render Stats shows draw calls. [official, [Developer Console](https://create.roblox.com/docs/en-us/studio/developer-console.md), [Memory usage](https://create.roblox.com/docs/en-us/studio/optimization/memory-usage.md)]
- **Device testing:** emulation cannot reproduce frame rate on constrained hardware, thermal throttling, memory use, touch responsiveness or cellular behaviour. [official, [Test on hardware](https://create.roblox.com/docs/performance-optimization/test-on-hardware)] A safe-area emulator bug on the Y axis was fixed in Studio 0.742, so older screenshots of the bottom edge are not trustworthy. [official reply, [2026-10-09](https://devforum.roblox.com/t/studio-mobile-emulator-does-not-respect-devicesafeinsets-along-y-axis/4703438)]
- **Gap:** no official or measured per-element cost was found for `UIStroke`, `UIGradient`, `CanvasGroup`, `ViewportFrame` or text on phones. Settling this needs a MicroProfiler capture on a target device.

### Accessibility

Roblox's guidance is qualitative. It publishes no contrast ratio or colour-blind palette. Its only text-size figure is the `MinTextSize` advice above. A standard such as WCAG would be an outside choice. [official, [Accessibility](https://create.roblox.com/docs/production/publishing/accessibility)]

| Player setting | Values | Roblox's pattern |
|---|---|---|
| `GuiService.PreferredTextSize` | `Medium` (default), `Large`, `Larger`, `Largest` | `TextScaled` does not follow it. `UITextSizeConstraint` limits still apply. `AutomaticSize` and `TextWrapped` adapt. `TextService` results reflect it. |
| `GuiService.PreferredTransparency` | 0 to 1, default 1; 0 is fully opaque | Multiply each element's `BackgroundTransparency` by it |
| `GuiService.ReducedMotionEnabled` | Boolean | Set tween time to 0, or replace movement with a fade |

[official, [Accessibility](https://create.roblox.com/docs/production/publishing/accessibility), [GuiService source](https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/reference/engine/classes/GuiService.yaml)]

- Over 5% of people have some colour blindness, so pair colour with symbols. Do not convey events by sound alone, and give separate volume controls for effects, music and speech. [official, same page]
- Developers complained that the text-size setting broke existing layouts. [community, [thread](https://devforum.roblox.com/t/preferred-text-scaling-needs-to-be-reverted-abrupt-release-with-no-concerns-addressed-are-disruptive/3911199)]
- No screen-reader API was found, but no dedicated search was run, so this is not proof of absence.

### Localization

- Roblox lists **50 locales**, and automatic translation covers **18 languages**: Arabic, Chinese Simplified and Traditional, English, French, German, Hindi, Indonesian, Italian, Japanese, Korean, Polish, Portuguese, Russian, Spanish, Thai, Turkish, Vietnamese. [official, [Language codes](https://create.roblox.com/docs/en-us/production/localization/language-codes.md), [Automatic translations](https://create.roblox.com/docs/en-us/production/localization/automatic-translations.md)]
- Automatic Text Capture takes text objects with `AutoLocalize` on. It cannot capture text in images, default leaderboards and chat, or badge and pass names. New strings can take days. Studio capture takes 1-2 minutes. [official, same page]
- **Players with the Automatic Translations account setting see translated text even if the creator has not enabled translation.** [official, [Localization overview](https://create.roblox.com/docs/production/localization)]
- Scripting: `LocalizationService:GetTranslatorForPlayerAsync` (wrap in `pcall`), `Translator:FormatByKey`. Localized images use asset IDs under a Key. [official, [Localize with scripting](https://create.roblox.com/docs/en-us/production/localization/localize-with-scripting.md)]
- The only audience figure found: over 50% of users speak languages other than English, and experiences with over 80% of strings translated see the most benefit. No method was given. [official, stale, [2022-06-23](https://devforum.roblox.com/t/auto-translate-for-all-more-languages-and-new-feedback-program/1843258)]
- `Enum.RtlTextSupport` controls right-to-left text direction. [official, [enum](https://create.roblox.com/docs/reference/engine/enums/RtlTextSupport.md)] No official mirrored-layout support or text-expansion percentage was found. A bug report says Roblox's own Avatar Editor layout breaks in Arabic. [community, excerpt, [thread](https://devforum.roblox.com/t/avatar-editor-has-incorrect-layout-positioning-and-category-navigation-issues-when-website-language-is-set-to-arabic/4766208)]

### Tooling

- **Device Simulator:** simulates screen dimensions, pixel density, on-screen keyboard and platform. Phones are grouped as Flagship, Mid-range and Entry level, with desktop, console and headset groups. It has a physical-size mode, and comparing phone and tablet there is recommended for tap targets and text. It names no devices or resolutions on the page. Touch is a mouse with Alt modifiers. [official, [Device Simulator](https://create.roblox.com/docs/studio/device-simulator)] Named presets sit in Device Manager, readable only inside Studio.
- **Controller Emulator** tests gamepads, VR controllers and TV remotes. [official, same page]
- **Libraries:**

| Library | Owner | Status found | Label and source |
|---|---|---|---|
| React Luau | Roblox | Based on React 17, MIT, read-only mirror, on Wally and Creator Store | official, [repo](https://github.com/Roblox/react-luau) |
| Roact | Roblox | Described as deprecated | unverified, stale, [2024-05-10](https://devforum.roblox.com/t/how-to-react-roblox/2964543) |
| Fusion | dphfox | MIT, third party, current 1.0 status unconfirmed | community, [repo](https://github.com/dphfox/Fusion) |
| Vide | centau | MIT, third party, bus-factor concern raised | community, [repo](https://github.com/centau/vide), [thread](https://devforum.roblox.com/t/fusion-vs-react-lua-which-one-to-use-for-long-term-development/2781328) |

No reliable data was found on what top studios use, and no measured performance comparison of these libraries was found.

- **Figma:** all importers are third party (UILint, roimport, Bloxig), read as search excerpts and untested. [community, [UILint](https://devforum.roblox.com/t/plugin-uilint-v2-import-figma-ui-into-roblox-studio/4765869), [roimport](https://devforum.roblox.com/t/free-figma-to-roblox-plugin-roimport/4731967), [Bloxig](https://bloxig.onrender.com/docs)]

### Policy

The firmest UI rules concern **paid random items**. This covers anything bought with Robux or Robux-bought currency, including capsule items (eggs, chests), enhancement items, combination items and probability modifiers. [official, [Paid random items](https://create.roblox.com/docs/en-us/production/monetization/paid-random-items.md), [Clarifying Requirements, 2026-05-26](https://devforum.roblox.com/t/clarifying-requirements-for-paid-random-items/4654622)]

- Show **every outcome with numeric percentages before currency is spent, totalling exactly 100%**. Indirect spending (keys, tickets) counts.
- **If a category has many outcomes, each individual outcome must still have its odds shown.** Odds by rarity tier need the itemized list behind the control described next.
- A long list may sit in a pop-up opened by a visible control labelled "Info" or "Details". **An (i) icon alone does not qualify.**
- When rounding, **keep four or more decimals past the first non-zero digit and add Roblox's disclaimer**.
- Shared odds may be stated once at the top of a list. If an outcome can only be obtained once, update the remaining odds for that user.
- Every outcome must give some benefit. **Bundling a random item into a paid pack makes the whole pack a paid random item.** [official, also [Community Standards](https://about.roblox.com/community-standards)]
- Restricted users need one of: a free path, a disclosed fixed order, direct sale, hiding the item, blocking with a message, or moving them away. Named regulated markets are Australia, Belgium, the Netherlands, the UK and Brazil, and the list can change. Test with Studio's Player Emulator.
- The Content Maturity questionnaire must declare paid random items. Confirmed violations can remove the game and suspend the account.

Other rules:

- **`PolicyService:GetPolicyInfoForPlayerAsync`:** wrap in `pcall`. Keys include `AreAdsAllowed`, `ArePaidRandomItemsRestricted`, `IsPaidItemTradingAllowed`, `IsEligibleToPurchaseSubscription`, `IsEndlessContentLoadAllowed` and others. Each is marked as required for experiences using that feature. [official, [API source](https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/reference/engine/classes/PolicyService.yaml)]
- **Purchases:** prompt from a button press or NPC interaction, check `IsForSale`, and show `PriceInRobux` from product info. With price optimisation, show prices on the client so users see personalised prices. [official, [Developer products](https://create.roblox.com/docs/en-us/production/monetization/developer-products.md)] Managed Pricing flags hard-coded prices. [official, [2026-06-15](https://devforum.roblox.com/t/managed-pricing-one-system-for-better-pricing-and-earnings-growth/4684738)]
- **Deception:** content meant to drive monetisation or engagement must not be deceptive, sensational or misleading. The page does not use the term "dark patterns" and has no rule on imitating Roblox itself. Removing functionality from buyers without notice is prohibited. [official, [Community Standards](https://about.roblox.com/community-standards)]
- **Imitation:** ads and commerce sellers reportedly may not mimic system functionality or Roblox UI, or use non-functional buttons. These rest on excerpts only, as the pages returned 403 or were not fetched, so read them in a browser first. [unverified, [Advertising Standards](https://en.help.roblox.com/hc/en-us/articles/13722260778260-Advertising-Standards), [Commerce Standards](https://en.help.roblox.com/hc/en-us/articles/36495190721172-Commerce-Standards)] No equally explicit rule for in-game UI was found.
- **Gambling wording differs:** the Community Standards bar simulated and actual gambling. The Terms of Use reportedly allow portraying gambling with nothing of value exchanged. [official, [Community Standards](https://about.roblox.com/community-standards); unverified, [Terms of Use](https://en.help.roblox.com/hc/en-us/articles/115004647846-Roblox-Terms-of-Use)]
- **Reserved areas:** the Roblox menu button cannot be removed. [community, excerpts, [thread](https://devforum.roblox.com/t/how-to-hide-roblox-coregui-button/3906962)] No explicit rule on prompt spam or countdown pressure was found, and none saying they are permitted.
- **Age:** age-checked 5-8 (Roblox Kids) has chat off by default, 9-15 (Roblox Select) unlocks chat gradually, and 16+ has chat on. Reaching Kids and Select accounts requires developer ID verification, two-factor authentication and a subscription or refundable publishing fee. Exact bands vary by region. [official, [2026-06-16](https://about.roblox.com/newsroom/2026/06/age-based-roblox-kids-and-select-accounts-now-globally-available)]

## 4. Game teardowns

### How to read these figures

- **Player counts are a single snapshot:** [games API](https://games.roblox.com/v1/games?universeIds=918677693,4983034985,20587584,10768172922,10768464559,10768044367,7685678300,10768553908,10764297006,10769221492,10258991999,9837612476,10563114921,1686885941,66654135,7326934954,383310974,994732206,6035872082,245662005), **2026-11-01 03:45 UTC**. [official]
- **Coverage boxes are hand-placed** on the owner's 14 captures (folder `_Roblox_ui_refs`, files dated 2026-11-01, desktop window 2000x1081, game area 2000x1060). Roblox's own top-left buttons and system chat are excluded. Allow about ±2-3 points on coverage and ±10% on sizes. [measured]
- **OpenFront is different:** page element sizes were read in a live browser at 1024x768, not from an owner capture. [measured]
- **State matters.** Every capture is from the first minutes. None shows a phone, a shop screen or an open menu. Control counts were not click-tested.
- **Popularity does not prove a UI good.** Jailbreak has similar density to Blox Fruits with far fewer current players. Rise of Nations' dense layout coexists with a long-lived game.
- **Conquer The World WW2 is identified by match, not by a title.** Neither capture shows a game name. The top strip, date pill and icon columns match dated videos, a basket icon matches guides, and the lobby map names and player rows fit the store listing. Below, "CTW WW2" always means this other game, not ours. [mixed labels, see Section 7]

### Per-game table

Coverage is permanent HUD, then with transient items such as banners and prompts. Button size is % of screen height.

| Game (playing, 2026-11-01) | State captured | HUD % | Where groups sit | Button size (% height) | Shop | First-time path |
|---|---|---:|---|---|---|---|
| Rise of Nations (1,164), `riseofnations-hud.webp`, `-event.webp` | Normal play | 20.6 / 22.2 with event pop-up | Top: menu toggle, ticker, date. Right: player list, 13 map modes. Bottom: flag and stats | Map mode 5.0, menu 2.1, list row 2.3 (text about 1) | None visible in HUD. 29 passes | Server list first, with Quick Join and Play Tutorial small at the bottom |
| Rise of Nations, `riseofnations-lobby.webp` | Lobby | 34.6 | Centre panel 50% wide x 66% tall | Quick Join about 2.6 | n/a | About 16 rows and tabs |
| CTW WW2 (6,195), `ctwww2-likely-hud-tutorial.webp` | Tutorial | 7.4 / 12.5 | Top: 4 resources, country, date. Left and right: 7 icons each. Bottom-centre: recruit | Right 7.0, left 5.6, pills 5.2, recruit 9.9 | Unlabelled basket, left column, green dot. 62 passes | Arrow, "Teleport to Capital", "Skip Tutorial" |
| CTW WW2, `ctwww2-likely-lobby.webp` | Country and server pick | 82.5 | One modal: country grid, server list | Country about 9, server row about 5 | n/a | Picks country and server first |
| The Conquerors 3 (52), `conquerors3-tutorial-hud.webp` | Tutorial | 11.5 / 19.8 | Top: full-width bar. Bottom-left: minimap (23% height). Bottom-right: buttons, cash | Side 4.7, Create Buildings 3.9 | None visible. 100 passes (API page cap) | Modal: short tutorial earns 3 skins, one Okay button |
| Adopt Me! (177,241), `adoptme-hud-tutorial.webp` | Tutorial | 4.7 / 5.6 | Top-right: currencies. Right: 4 labelled tiles, 4 icons. Bottom-centre: backpack | Tiles 8.5, small 4.5, backpack 8.5 | Labelled SHOP tile, event tile with countdown and "!". 24 passes | Splash with Play (`adoptme-first.webp`, 17.6%, Play 7.5% tall), then a pointer |
| Blox Fruits (289,812), `bloxfruits-hud.webp` | First spawn, safe zone; game reports gamepad mode, so layout may be the gamepad variant | 4.5 / 7.5 | Bottom-left: Menu, money, bars, icons. Bottom-centre: ability slot | Menu 5.3, bars 6.4, small 2.5, slot 5.0 | None visible, assumed behind Menu (not verified). 6 passes | Pirates or Marines choice (`bloxfruits-first.webp`, 26.1%), then quest marker |
| RIVALS (199,745), `rivals-lobby-hud.webp` | **Lobby, not a match** | 12.4 / 13.7 | Top-centre: keys. Right: player list, duel cards. Bottom-centre: Play, Weapons, Tasks, Settings | Play 5.8, menu icons about 8, join 3.6 | Keys with green "+", red nudge over Weapons, badge on Tasks. 9 passes | Bubble over Play |
| Steal An Egg (1,107,607), `stealanegg-hud.webp` | First minute | 4.7 / 6.1 | Left: Shop, Index. Right: 3 tiles. Bottom-centre: hotbar | Shop 6.9, tiles 7.7, hotbar 5.2 | Labelled green Shop with "!", visible countdowns. 2 passes | Banner, red ground chevrons, 0/3 counter |
| Jailbreak (5,149), `jailbreak-hud.webp` | First police spawn | 5.5 / 8.3 | Left: 4 round buttons, cash, minimap. Right: 6 actions. Bottom-centre: hotbar | Left 7.1, actions 6.0, hotbar 6.4 | Green and blue "+" by readouts, promos on team screen. 9 passes | Team pick (`jailbreak-first.webp`, 13.1%) with live counts, then banner |
| OpenFront (live browser, 1024x768) | Solo game, tutorial open | 7.2 without tutorial box | Corners: 1 left, 5 right. Bottom-centre: 500 px panel with troop slider and about 9 slots | Panel 8.1, slot strip 3.9, corners about 5.3 | Store tab on home page | Tutorial button beside Solo |

[measured for layout; official for passes via the API per game, 2026-11-01: [RoN](https://apis.roblox.com/game-passes/v1/universes/918677693/game-passes?passView=Full&pageSize=100), [CTW WW2](https://apis.roblox.com/game-passes/v1/universes/4983034985/game-passes?passView=Full&pageSize=100), [TC3](https://apis.roblox.com/game-passes/v1/universes/20587584/game-passes?passView=Full&pageSize=100), [Adopt Me](https://apis.roblox.com/game-passes/v1/universes/383310974/game-passes?passView=Full&pageSize=100), [Blox Fruits](https://apis.roblox.com/game-passes/v1/universes/994732206/game-passes?passView=Full&pageSize=100), [RIVALS](https://apis.roblox.com/game-passes/v1/universes/6035872082/game-passes?passView=Full&pageSize=100), [Steal An Egg](https://apis.roblox.com/game-passes/v1/universes/10563114921/game-passes?passView=Full&pageSize=100), [Jailbreak](https://apis.roblox.com/game-passes/v1/universes/245662005/game-passes?passView=Full&pageSize=100); OpenFront: [site](https://openfront.io)]

**Visual style, from the same captures.** [measured]

- Rise of Nations: flat dark slate, small plain sans.
- CTW WW2: chunky translucent grey pills, gold-toned serif, curved country labels.
- The Conquerors 3: flat dark rectangles, thin squared type, neon green.
- Adopt Me: sticker tiles with ribbon labels.
- Blox Fruits: gradient bars, yellow Menu.
- RIVALS: dark minimal bars, 3D icon art with labels.
- Steal An Egg: saturated colour, thick black outlines, comic numerals.
- Jailbreak: round dark-grey buttons, condensed caps.
- OpenFront: dark navy flat panels.

**Video-only neighbours.** [unverified: read from 320x180 frames, no numbers taken]

- [RoWorld, 2026-10-26](https://www.youtube.com/watch?v=gK2FG_H5Dg8): bottom-centre build bar, top status panel, top-right attacks list, big troop numbers on territory.
- [WorldFront, 2026-10-12](https://www.youtube.com/watch?v=k7dQhSOIXnk): left column with text labels.
- [Control Europe, 2026-10-31](https://www.youtube.com/watch?v=NHWVWA5PtHo): thin stat strip, pop-up on the selected city.
- [Mini War, 2026-10-17](https://www.youtube.com/watch?v=_iTvaom09Ic): dense icons on both sides.
- [Command An Army, 2026-10-31](https://www.youtube.com/watch?v=eMDUVpGq5Sg): left icon column, ability row.
- [Murder Mystery 2, 2026-10-19](https://www.youtube.com/watch?v=4alYEZs8pms), [Brookhaven, 2026-10-23](https://www.youtube.com/watch?v=-dHrQYLcPnw) and [99 Nights, 2026-10-31](https://www.youtube.com/watch?v=zVoNHi0ZE-w): small edge tiles.

**Phone evidence is thin.**

- OpenFront at an emulated 812x375 (desktop browser, no touch) collapsed its panel to one 500x36 row, and tutorial-state coverage rose from 5.3% to 9.4%. [measured, live browser]
- Blox Fruits and RIVALS phone layouts come from video frames only. [unverified, [Blox, 2026-09-10](https://www.youtube.com/watch?v=fGzfurdTvSM), [RIVALS, 2026-10-26](https://www.youtube.com/watch?v=iLFT4TMNbXE)]
- No phone source was found for CTW WW2, The Conquerors 3 or Adopt Me.

### Cross-game patterns

All of these are correlation from a small sample of early-session states.

**Popular non-strategy games** share these traits. [measured]

- In-play coverage of 4.5-5.5% (Blox Fruits, Adopt Me, Steal An Egg, Jailbreak). RIVALS' 12.4% is a lobby and not comparable.
- Buttons at about 5-9% of screen height, on edges, with the centre clear.
- Text labels on the main money buttons (SHOP, Shop, Menu, Weapons).
- Single-path openers: one big choice or one pointer.
- Attention markers: "!" badges or numbers, and visible countdowns.

Their low coverage may partly reflect genre, a character in a 3D world, so the strategy comparison is not like for like.

**Strategy games** differ in these ways. [measured]

- In-play coverage of 7.2-20.6%.
- CTW WW2 uses 14 unlabelled icons. Rise of Nations uses text-only buttons. WorldFront labels its icons (video, unverified).
- They show a clock or date and a shared world state (ticker or banner).
- Two of them open on a data-heavy list (RoN's server list, CTW WW2's 82.5% modal). OpenFront makes Solo and Tutorial its largest buttons.
- Bottom-centre holds economy and recruitment where action games put a hotbar.
- CTW WW2's 7.4% with 16 controls shows a strategy HUD can stay fairly small on desktop by using narrow side columns. Whether that works on a phone is unknown, and no test supports or undercuts icon-only columns.

**Keeping a full map readable.** Phone evidence is limited to OpenFront's emulated size.

- Labels scale with territory size (CTW WW2, OpenFront). [measured]
- Key numbers sit on the map (OpenFront [measured], RoWorld [unverified]).
- Panels collapse at phone size (OpenFront). [measured]
- An action menu opens at the point of touch: OpenFront's radial (right-click tested, touch not) [measured] and Control Europe's pop-up [unverified].
- Deep screens are centred modals closed with X (CTW WW2). [unverified, [frames, 2026-09-15](https://www.youtube.com/watch?v=DpmoWgHHP10)]
- Data layers are separate map modes (RoN's 13 buttons). [measured]

**Pass catalogues vary and do not track popularity:** Steal An Egg 2, Blox Fruits 6, RIVALS 9, Jailbreak 9, Adopt Me 24, RoN 29, CTW WW2 62, TC3 100 or more. These are passes listed by the API, not all on sale. [official, links above]

**Like ratios** (Mini War 96%, RIVALS 94%, Steal An Egg 91%, RoN 87%, RoWorld 83%, CTW WW2 81%) are correlational at best and isolate nothing about UI. [official, [votes API, 2026-11-01](https://games.roblox.com/v1/games/votes?universeIds=918677693,4983034985,20587584,10768172922,7685678300,10258991999,9837612476,10563114921,383310974,994732206,6035872082,245662005)]

## 5. What makes it good or bad

No public controlled test on Roblox was found for hierarchy, clutter, icon style, text amount, shop layout, offer timing or visual style. So most of this section is "designers say", with the small "tested and shown" base kept separate.

### Principles

**Designers say.**

- **Context only:** put the most important information first and swap buttons by situation, because excess buttons, screens and text overwhelm phone players. Advisers agree on using collapsible menus and one clear main action. [official, advice, [UI and UX design](https://create.roblox.com/docs/production/game-design/ui-ux-design); community, [2023-06-25](https://devforum.roblox.com/t/how-to-make-extremely-clean-ui-while-keeping-good-ux/2438099), [2023-09-03](https://devforum.roblox.com/t/ui-style-guide-series-minimalistic-simplistic/2578826)] This has the widest source agreement, but that is agreement plus anecdote, not an experiment.
- **Conventions:** X closes, grey means unusable, a lock means locked, a red price means unaffordable. Keep one style across menus and study your genre. [official, same docs page]
- **Directing attention:** use colour, size, negative space, proximity and movement, with bright for crucial items and muted for the rest. [official, single source at this detail, same page]
- **Primary action distinct from secondary:** quieter Cancel, brighter main button. [community, same 2023 thread]
- **HUD versus menu:** keep essential, context-relevant items on the HUD, with a prominent button opening a categorised menu. [official, same page]
- **Text:** players generally skip prompts. Prefer highlights, arrows and in-world signs, which also need no translation. Roblox gives no number. [official, [Onboarding techniques](https://create.roblox.com/docs/production/game-design/onboarding-techniques)]
- **Onboarding:** avoid long fixed sequences, trigger guidance at first relevant use, and show timed hints only to the stuck. The hint-delay figures on that page are explicitly hypothetical. [official, same page]

**Where advisers disagree.**

| Topic | One side | Other side | Data |
|---|---|---|---|
| Depth | Add highlights or shadows for a tactile feel [official, [docs](https://create.roblox.com/docs/production/game-design/ui-ux-design)] | No shadows or outlines [community, [2023-09-03](https://devforum.roblox.com/t/ui-style-guide-series-minimalistic-simplistic/2578826)] | None |
| Minimal vs bold | Clean and restrained [community] | Roblox players may prefer bold, colourful buttons [community, same [2023 thread](https://devforum.roblox.com/t/how-to-make-extremely-clean-ui-while-keeping-good-ux/2438099)] | None |
| Red and green | Green for health, red for unaffordable [official] | Avoid bright red and green for accessibility [community, same thread] | None |
| Fonts and icons | Three different font and icon sets in one thread [community] | | None |
| Motion | Use sparingly [official] | Animations matter, and kits sell heavy animation [community, [listing](https://builtbybit.com/resources/simulator-ui-pack.127378/)] | See Feel |
| Tap size | 24 px, 44 pt, 48 dp and 1 cm are all current floors | | Only the 1 cm guideline cites a study. The article gives no error rates. |
| Minimum text | Xbox 26 px console and 18 px PC at 1080p; handheld never under 14 px | IGDA 32 px, 46 px for timed text | Search digests only, none Roblox ([Xbox](https://devdocs.xbox.com/build/game-principles/accessibility/xag-deep-dives/xag-101-text-display.md), [handheld](https://devdocs.xbox.com/build/gdk-and-engines/handheld/handheld-guidelines-and-testcases), [IGDA](https://igda-gasig.org/?p=1387)) |

**Tested and shown.** The only map-related finding is general and non-game: a survey of 84 map variations found the user's task was the dominant factor in map UX. [measured, search digest, [PMC8459706](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC8459706/)]

### Player complaints

All of these are community anecdote from a skewed sample, not measured rates. Stated reasons for leaving are leads to test, not causes. One thread's "95% leave" figure is the developer's own estimate. [community, [thread](https://devforum.roblox.com/t/almost-every-player-is-immediately-leaving-my-game-can-you-tell-me-why/3483806)] Complaints also cluster on the first 30 seconds partly because that is where reviewers look.

- **Too much UI on first join (3 threads):** "overwhelming seeing those many buttons as soon as you join"; too big and cluttered on mobile; inventory not found on mobile. [[2025-09-30](https://devforum.roblox.com/t/the-age-old-question-what-makes-people-leave-this-after-30-seconds/3969002), [2026-01-16](https://devforum.roblox.com/t/why-do-people-leave-my-game-after-a-couple-minutes/4263070), [2025-02-17](https://devforum.roblox.com/t/almost-every-player-is-immediately-leaving-my-game-can-you-tell-me-why/3483806)]
- **Forced or unclear tutorials (2 threads):** a developer blamed a forced teleport into a tutorial, even with a skip button, then moved it into the main area. One reviewer found that far better, which is not a measured result. Another reviewer found a tutorial hard to start and a failure that forced you onward. [same threads]
- **Paying before the hook (single source):** a starter-pack prompt as the first thing shown. [[2026-01-16](https://devforum.roblox.com/t/why-do-people-leave-my-game-after-a-couple-minutes/4263070)]
- **Repeated prompts (1 thread, several posters):** favourite, group and event prompts, plus accidental console purchases. Another poster says players can just avoid those games. [[2026-06-23](https://devforum.roblox.com/t/let-us-disable-non-essential-in-game-prompts/4699372)]
- **Confusing purchase wording (1 thread, several posters):** a generic Buy Item label, refund requests from players who thought a developer product was permanent, and a large buy button with no nearby cancel. [[2025-08-09](https://devforum.roblox.com/t/suggestion-to-improve-the-purchase-ui/3870582)]
- **Looks unfinished (2 threads):** mismatched loading bar, dark inconsistent UI, bland buttons, camera moving before the loading screen. [same threads]
- **Praise is rarely specific:** a war-themed UI rated 9/10 with no reasons. Cartoon UIs get mixed reactions. Minimal ones draw complaints that buttons cannot be made out. [[2025-03-04](https://devforum.roblox.com/t/feedback-on-war-themed-ui/3526231); search digest, [cartoon review](https://devforum.roblox.com/t/cartoon-style-ui-review/3615711)]
- **Parents:** Common Sense calls Robux the centre of most parent-child conflict on the platform. Its reviews were not read individually. [community, [guide](https://www.commonsensemedia.org/articles/parents-ultimate-guide-to-roblox)]

### Feel

**Designers say.**

- Rule-of-thumb durations: simple feedback about 100 ms; modal or substantial change 200-300 ms; pop-up in about 300 ms and out 200-250 ms; large movement up to 400 ms; above 500 ms feels like a drag. NN/g gives no experimental data for these. [community, single source for the numbers, [2020-02-09](https://www.nngroup.com/articles/animation-duration/)]
- Roblox gives no recommended values. Its example uses 0.25 s base and 0.5 s Cubic Out for colour, and says per-property transitions perform better than defaults. [official, example, [Styling Transitions](https://devforum.roblox.com/t/full-release-styling-transitions/4646870)]
- Give feedback for hover, pressed and released, and grey for disabled. [official, [docs](https://create.roblox.com/docs/production/game-design/ui-ux-design)]
- Spamming a button stacks tweens and looks like lag. [community, search digest, [thread](https://devforum.roblox.com/t/tweening-issues/2739132)]
- Show the loading screen immediately, and hide chat and leaderboard until loaded. [community, [2025-02-17](https://devforum.roblox.com/t/almost-every-player-is-immediately-leaving-my-game-can-you-tell-me-why/3483806)]

**Tested and shown.** None of these used a child or Roblox population, so transfer is unconfirmed.

- **Feedback tied to player success raised all motives, while amplified feedback unexpectedly lowered them.** Curiosity was the only predictor of playtime. Pre-registered, n=1,699, action RPG, single study. [measured, [Kao et al., CHI 2024](https://spiral.imperial.ac.uk/entities/publication/253c32f5-d124-4a23-88b5-9aaaf114608d)]
- Visual embellishments improved appeal in all games tested, but competence only in specific circumstances. n=40 and n=32. [measured, digest, [Hicks et al., 2019](https://unpaywall.org/10.1145%2F3311350.3347171)]
- Vibration feedback improved player experience measures in Breakout. n=38. [measured, digest, [Singhal and Schneider, 2021](https://uwaterloo.ca/haptic-experience-lab/projects/juicy-haptic-design-vibrotactile-embellishments-can-improve)]
- Response limits: 0.1 s feels instant, 1 s keeps flow, 10 s is the limit of attention. Over 10 s use percent-done, and for 2-10 s a busy indicator is enough. [measured, older research summarised, [NN/g](https://www.nngroup.com/articles/response-times-3-important-limits/)]
- No measured evidence was found for UI sound effects or ticking numbers.

### Monetization presentation

**Tested and shown, all about price, not layout, and self-reported by Roblox.**

- Regional pricing, top 2,500 games, 2025-01-06 to 2025-12-21: 4-10% more Robux spend, 1-6% more players and playtime, 43-52% more pass purchases in discounted regions. Results vary by audience geography. [measured, [2026-06-15](https://devforum.roblox.com/t/managed-pricing-one-system-for-better-pricing-and-earnings-growth/4684738)]
- Early regional tests raised the share of users spending by about 17% in Mexico, 26% in Brazil and 52% in the Philippines. [measured, digest, [2025-04](https://about.roblox.com/newsroom/2025/04/roblox-launches-regional-pricing-for-in-experience-items)]
- Price Optimization: earnings +4%, described as an average in one source and a median in another. Conditions are unknown. [measured, [same post](https://devforum.roblox.com/t/managed-pricing-one-system-for-better-pricing-and-earnings-growth/4684738); digest, [docs](https://create.roblox.com/docs/production/monetization/price-optimization)]

**Claimed, not shown.**

- Roblox calls its persistent global Shop button the most effective entry point, with no data in the post. Developers object to lost control and lost 3D previews. It also says over 5% more spend per user for one game, with no method. [official claim, community objections, [2026-06-24](https://devforum.roblox.com/t/introducing-shop-a-personalized-in-game-storefront/4701505)]
- A developer blog says product order, button size and pop-up timing affect conversion, with no figures. [unverified, [moze](https://note.com/moze_inc/n/ncb863e883fc1?hl=en)]
- "Show a pack on join" is common, but its benefit is unsupported in public data and players object to it.

**How to test it yourself.** Experiments can vary shop visibility, starter pack types and pricing, with up to two variants plus control. Metrics include Day 1 and Day 7 retention, playtime, ARPU (average revenue per user) and payer conversion. Default early-harm thresholds are playtime -10%, ARPU -20% and payer conversion -20%. [official, [Experiments](https://create.roblox.com/docs/production/experiments)]

**Risk.**

- Fortnite: $245M in refunds over confusing button configurations that charged on a single press. [official FTC action via law-firm summary, digest, [Miller Canfield](https://www.millercanfield.com/resources-FTC-Settlement-Signals-Risks-for-Digital-Platforms.html)] A practical reading is that a purchase button should never sit where a non-purchase action normally sits. This is an inference.
- Fairplay and NCOSE filed an FTC complaint on 2026-05-20, alleging among other things that Roblox obscures the cash-to-Robux rate. Roblox strongly disputes it. These are allegations, not findings, and no sign of an opened investigation was found. [community press, digest, [Quartz](https://qz.com/fairplay-ncose-ftc-complaint-roblox-child-safety-052026)]
- Roblox's own paid-random-item rules are in Section 3.

### Trends

**Designers say.**

- "Matte and clean" is a current sales pitch, and glossy and chunky kits still sell. [community listings, [matte, 2026-09-20](https://devforum.roblox.com/t/roblox-simulator-asset-ui-pack-clean-modern-matte-look-for-roblox-simulator-games/4884711), [BuiltByBit](https://builtbybit.com/resources/roblox/graphics-ui/)]
- Commenters called minimalism a fad back in 2020, and advised matching genre. [community, stale, [2020-04-29](https://devforum.roblox.com/t/aesthetically-pleasing-ui/549103)]
- War-themed evidence is thin peer opinion: Black Ops and old Call of Duty comparisons, metal textures, rounded corners. [community, [2025-03-04](https://devforum.roblox.com/t/feedback-on-war-themed-ui/3526231), [digest](https://devforum.roblox.com/t/military-game-menu-ui/1489591), [2022-06-07](https://devforum.roblox.com/t/feedback-on-a-new-strategy-game/1822875)] One non-Roblox strategy player felt a solid-colour redesign lost the WWI feel. [community, stale, [2018-12-03](https://www.playsupremacy.com/en/forums/1914/1914-news-updates/supremacy-1914-live-release-and-beyond-e0ca929d)]

**Tested and shown.** Nothing. No test, survey or success correlation links any style to Roblox player preference or retention. "Dated versus current" is at present a developer-taste distinction. The only recurring test across style threads is readability.

### Lessons from map games outside Roblox

- **Supremacy 1914:** the developer reports map readability among the largest feedback topics, and UI and HUD among the most common. Work tracks include label sizing and clutter, borders, unit-versus-map contrast, safe areas and an overview toggle. No counts given. [community, developer-reported, [2026-07-06](https://www.playsupremacy.com/en/news/1914/focus-group-update)] In 2018 players complained of same-colour maps, small icons and unreadable borders. [community, stale, [thread](https://www.playsupremacy.com/en/forums/1914/1914-news-updates/supremacy-1914-live-release-and-beyond-e0ca929d)]
- **Civilization VII:** about 50% positive among almost 8,000 Steam reviews at launch, with UI a common complaint, and Firaxis named UI a top priority. Other launch issues were in play, so this is correlation. A late overhaul that was not ready is the warning. [community press, digest, [80.lv](https://80.lv/articles/less-than-half-of-civilization-vii-s-players-on-steam-are-happy-with-the-game/), [Aftermath, 2025-02-27](https://aftermath.site/civilization-vii-civ-7-update-ui/)]
- **OpenFront issue titles** show recurring pressure points: mobile placement, range visibility on phone, a UI size slider, collapsible panels, chat over the map and a mobile leaderboard. Only titles were read, and closed does not prove shipped. [community, [issues](https://github.com/openfrontio/OpenFrontIO/issues?q=is%3Aissue+mobile+UI)]
- **Roblox strategy peers:** overlapping menus, no guidance, very cluttered, and maps too washed out to read at distance. [community, [2022-06](https://devforum.roblox.com/t/feedback-on-a-new-strategy-game/1822875), [digest](https://devforum.roblox.com/t/release-and-singleplayer-pacific-warfare/2002736)]

Backed by two or more games: distinct colours and borders, and panels that do not hide the map. Backed by one game each: zoom-controlled labels, reserved safe areas, an overview toggle, and player-scalable UI size.

## 6. Scoring Conquer the World

**Scope.** This scores the working tree on 2026-11-01, including uncommitted work in `CommandBar` and `TopStatus` and untracked `HudCoverage`. HEAD is 08e16a7. Nothing was run in Studio, and the current look was not viewed. File references are to our source, and `UI/` means `src/client/UI/`. All findings are "measured from source" unless labelled otherwise. Comments in code are the author's claims, not facts.

### Coverage: what we can and cannot say

- **The "22%" figure is unverified.** It is not in `HudCoverage`, its test or `docs/PLAN.md`. A memory note attaches it to a concept image, eyeballed, not to our HUD.
- **The "12-15%" budget is unverified as stated.** The code holds **15% desktop and 10% phone** (`UI/HudCoverage.luau:10-11`). The 12% lower bound is not in code. The code's own comment calls these "our own numbers, not a published standard".
- **The budget is not enforced.** `tests/hud_coverage.luau:18` asserts only that the constants stay at or under 0.15 and 0.10. No HUD rectangles are tested. `UIRoot.hud_coverage()` reports a string and compares nothing, and it was not run. The note that the budget is "checked automatically" is not confirmed by code.
- **The only live readings are from the earlier build session, and were not rerun for this report.** Project notes record `hud_coverage` in Studio on this HUD: desktop 7.3%, and 9.2% in phone-size emulation at 829x400, or about 10% with the real row size because emulation undersizes it. They are not from a real phone. [measured, project notes of 2026-11-01]
- **The estimates below are arithmetic from code, not measurements.** They come from a hand-built model of fixed widths and paddings, because the real `TopStatus` would not build under Lune. The desktop estimate runs above the 7.3% reading, so treat these as a guide to how coverage climbs on small screens, not as exact values. [unverified]

| Screen (logical px) | State | Share | Code's budget |
|---|---|---:|---:|
| 1600x900 | 8 rail slots | 8.4% | 15% |
| 1600x900 | 11 rail slots (silo) | 9.0% | 15% |
| 932x430 | Touch, compact | 8.3% | 10% |
| 873x402 | Touch, insets 62 left and right | 9.4% | 10% |
| 844x390 | Touch, compact | **10.1%** | 10% |
| 800x360 (this report's addition, same parts) | Touch, compact | **11.5%** | 10% |
| 667x375 | Touch, compact | **13.3%** | 10% |

Why it climbs on small phones: touch scale never drops below 1.0 (`UI/UITheme.luau:690-696`), so the parts keep their size as the screen shrinks. The 800x360 row is added because that is the second most common web resolution above, not because Roblox players use it. The arithmetic is 33,160 logical square pixels of parts over the screen area, assuming no overlap and no insets.

**These figures do not compare directly with the teardown percentages.** The teardown boxes were hand-placed on real captures. Ours are arithmetic, and they leave out Roblox's buttons, the leaderboard panel, attacks chip, event feed, notices, tutorial card, doctrine draft, phone build tray, tooltips and shadows (`UI/UIRoot.luau:696-707`). As a loose orientation only, the desktop estimate sits near CTW WW2 (7.4%) and OpenFront (7.2%), and above the 4.5-5.5% of popular non-strategy games. OpenFront's emulated phone figure of 9.4% is close to the "about 9%, by eye" that our code comment cites.

### Scorecard

| Area | What we have | Against the findings | Score |
|---|---|---|---|
| Phone layout structure | One HUD breakpoint, `compact` at height under 560 or width under 900 (`UI/UIRoot.luau:2489`). A few screens add their own size checks (`UI/TitleScreen.luau:864`, `UI/PartyPanel.luau:423`, `UI/TopStatus.luau:209`). Phone gets corner pill, corner strip, Build toggle and tray | Matches Roblox's "collapsible menu" advice and OpenFront's collapse. Not seen on a device | **Good, unproven** |
| Coverage | Budgets exist, unenforced. Small phones estimated over | See above | **Partial** |
| Touch targets | Most kit buttons are 44 logical px or more, and touch scale is at least 1.0. Difficulty chips rise to 44 on touch (`UI/TitleScreen.luau:946`). Exceptions on touch: rail slot 42 tall; Tutorial Skip and Next 36; Locker, Arsenal, FlagShop, CommandCenter and GeneralOffer close buttons 34; Locker tabs and CommandCenter chips 32; phone Locker buy buttons 40 and 34; party kick 26 | Roblox gives no number. 44 is our choice. It equals Apple's 44 pt in number and sits below Material's 48 dp (digest). Physical size on devices was not measured | **Mostly** |
| Text size | Kit minimum 12 on touch = `TextSize` 15 at scale 1 (`UI/UIRoot.luau:2507`, `UI/UITheme.luau:269-271`). Raw exceptions such as "Tap here" at 13 (`UI/Tutorial.luau:78`) | No Roblox number. Well above RoN's list text, about 1% of screen height | **Mostly** |
| Safe areas | Main UI on `ScreenInsets.None` with hand-applied insets from a probe. `CoreUISafeInsets` used nowhere | Docs suit `None` to non-interactive content. The active plan's "interactive UI in CoreUISafeInsets" is not implemented | **Partial** |
| Mouse, touch, keyboard | All three, including pinch, long press, radial slide and full hotkeys | Strong | **Good** |
| Hover on touch | Long-press cards, tray captions, pinned tile card, stats details | Good. Era strip has no touch path (`UI/TopStatus.luau:119-126`), and top-bar icons have no label or touch tooltip (`src/client/Main.luau:125`) | **Mostly** |
| Gamepad and console | One activity check (`src/client/Main.luau:459`), and kit buttons set `Selectable = false` (`UI/Widgets.luau:428`) | Console is 3% of average DAU. Automatic cursor behaviour is unverified | **Gap, owner decision** |
| Player accessibility settings | None read: no `PreferredTextSize`, `ReducedMotionEnabled` or `PreferredTransparency` | Roblox documents all three with patterns | **Gap** |
| Contrast | `tests/ui_look.luau` passes at 16.5, 10.2 and 6.3 against our own 7, 4.5 and 3 thresholds | A good habit Roblox does not ask for. The test panel is fully opaque, and the scan tool skips anything over the map | **Good on panels, untested on map** |
| Colour as signal | Mostly paired with a second cue. Colour-only: leaderboard threat, clock under 120 s | Roblox says pair colour with symbols | **Mostly** |
| Localization | None, all hard-coded English. Boxes measured from English, exact metrics cover Latin only | About 82% of DAU is outside US and Canada | **Gap** |
| First session | Auto-starts tutorial match, single path, Skip on cards, 12 steps (6 actions, 6 lessons), steps time out | Single path matches top games. 12 steps and 6 text lessons sit against Roblox's "avoid long fixed sequences" | **Partial** |
| Shop visibility | Labelled gold SHOP slot on desktop rail. Not in the phone's always-visible list | Matches the labelled-money-button pattern on desktop (correlation). Phone route not traced | **Mostly** |
| Paid random items | Policy check fails closed, never gives an owned item, updates remaining odds per rarity. Card shows four rarity rows in whole percents, with no per-item odds (`UI/Locker.luau:343-360`, `:446`) | The rules ask for odds on each individual outcome | **Gap, fix before release** |
| Prices | Displayed prices come live from Roblox (`UI/Prices.luau`) | Matches Managed Pricing advice | **Good** |
| Offer pressure | Starter waits until after the tutorial, with a clear NOT NOW. Also has a 48 h countdown, "-76%", and repeats every 6 h | No Roblox rule on countdowns found, no public test either way | **Untested** |
| Performance signals | One `CanvasGroup`, `ViewportFrame` only for crate art, throttled refreshes | Low-risk signs. No timings on any device | **Unknown** |
| Motion | Hover 0.12-0.16 s, fade 0.2 s, most tweens 0.1-0.5 s | Within the rule of thumb. Title dock is longer (see change 12) | **Good** |
| Testing | Logic and token tests. No test builds HUD panels. Checklist says phones are unchecked | Roblox says emulation misses touch feel, reach and memory | **Gap** |
| Style | Dark indigo plates, Builder Sans, one accent | No evidence favours or opposes any style | **Not scored** |

### Changes, biggest impact first

Ranked by consequence if we are wrong, weighted by evidence strength. **Strong** means an official rule or filing that applies directly. **Moderate** means official advice or repeated reports with no test. **Weak** means a single source, our own arithmetic or a rule of thumb. Only change 1 and the truthfulness part of change 7 rest on published rules. Everything else is a recommendation, and no single source's advice is treated as a requirement here.

**1. Add per-item crate odds, then check every crate route, before release.** Failure can cost the game and the account, though Roblox describes an appeal path. All product ids are 0, so nothing is exposed yet.

- *Outcomes:* the card shows rarities only. Items roll uniformly among unowned items in a rarity, so each item's odds are its rarity share divided by that count, and they change per player. An itemized list behind a labelled Details control would fit the docs' example.
- *Format:* we show whole percents, renormalised over rarities with unowned items (`src/shared/Data/Cosmetics.luau:493-515`). The base 62/25/10/3 is exact. Once a rarity runs out, Common becomes 62/97, about 63.9%, which is a rounded value. The policy asks for four or more decimals past the first non-zero digit plus a disclaimer.
- *Placement:* odds appear in the Locker card, and a grep of `CrateButton`, `CrateOpening`, `FlagShop`, `Arsenal` and `StarterOffer` found none. The reveal screen's ANOTHER button also prompts a purchase (`UI/CrateOpening.luau:1112`, `UI/Locker.luau:585-586`), and that file shows no odds. Confirm that every route to buying a crate, including the 3 and 10 packs, shows odds or a labelled Info or Details control first.
- *Scope:* crate credits come only from crate products and the General perk (`src/server/Purchases.luau:512`, `:773`), and no Stars route to crates was found. The General subscription advertises "A free crate every day" with no odds (`UI/GeneralOffer.luau:273`). Whether the bundling rule makes it a paid random item is unverified, so decide before release or ask Roblox. Declare paid random items in the maturity questionnaire, and test with Player Emulator.
- *Restricted players:* the policy result `crates_allowed` fails closed (`src/server/ServerMain.luau:1312`) and the server applies it to the inventory and the General perk (`:1305`, `:1409`). Only the client stops a crate purchase (`UI/Locker.luau:516`), and server receipt handling does not read it, so a modified client could still buy. Measured from source, not exploited.
- *Evidence:* official policy. **Strong for the rule. The missing per-item odds are measured from source. Other routes are not fully traced.** [Paid random items](https://create.roblox.com/docs/en-us/production/monetization/paid-random-items.md), [2026-05-26](https://devforum.roblox.com/t/clarifying-requirements-for-paid-random-items/4654622)

**2. Run one real phone and tablet pass on the current HUD.** The checklist says phones were only previewed at phone size. Everything else in this list gets cheaper once it is done, and the checklist below batches it into one run.

- *Evidence:* mobile is 83% of average DAU [official]. Roblox says emulation cannot reproduce touch responsiveness, memory or throttling [official, [Test on hardware](https://create.roblox.com/docs/performance-optimization/test-on-hardware)]. `docs/RELEASE_CHECKLIST.md` section 3 flags it.
- **Strong on need. The effect on retention is unknown.**

**3. Bring the phone HUD inside our budget, or change the budget on purpose, and make a test enforce it.** The strip is 443x44, about 59% of the estimated phone parts, so it is the first place to look. Reaching 10% at 800x360 needs about 4,400 fewer square pixels, roughly 100 px off the strip. At 667x375 it needs about 8,100, which may not be possible without losing attack stops. That trade-off is the owner's call, and shrinking below 44 px targets is not recommended.

- First get live values from the Studio `hud_coverage` command at these sizes, then assert them in a repeatable check.
- Also measure opened states (leaderboard, tray, notices), which the current definition leaves out.
- *Evidence:* first-join clutter complaints in 3 threads [community]; Roblox's small-screen advice [official]; top-game coverage [measured, correlation].
- **Moderate on the principle. Weak on the number, which is our choice and our arithmetic.**

**4. Test map legibility at the smallest screens, and extend contrast checks to the map.** Our contrast test uses an opaque panel, and `tools/ui_contrast_scan.luau` skips anything over the map. So the screen's main content is outside our checks. Map labels were not scored in this research.

- Check territory labels, borders, troop numbers and colour pairs at 360 logical px tall. Add a non-colour cue to the two colour-only signals.
- *Evidence:* map readability led feedback on Supremacy 1914 [community, developer-reported]; two or more games on colours and borders [community]; over 5% colour blindness and pair with symbols [official, [Accessibility](https://create.roblox.com/docs/production/publishing/accessibility)]. No phone capture of any rival.
- **Moderate.**

**5. Test how we behave under automatic translation, then decide on localization.** Roblox says players with the setting can see translated text even if the creator has not enabled translation. Our boxes are measured from English templates such as "SPAWN PHASE" (`UI/TopStatus.luau:268`), and exact metrics cover Latin only (`UI/UITheme.luau:325-336`). So overflow is possible now, without our doing anything. This is unverified, as the `AutoLocalize` default was not checked.

- Then enable capture and fix overflow. Keep words out of images.
- *Evidence:* about 82% of DAU outside US and Canada, but only 39% of revenue there [official]; the "over 80% of strings translated" benefit is a stale 2022 claim with no method [official].
- **Strong on audience. Moderate on benefit. Our own failure is untested.**

**6. Measure the first session, then test a shorter tutorial.** Add funnel events per tutorial step, if not already present (not traced), and read the First Session Retention chart. Then run an Experiment: the 6 action steps, with the 6 text lessons (gold, cities, trade, defense, landmarks, eras) moved to coach tips at first relevant moment, against today's tutorial. Guardrails are the Experiments defaults. The funnel numbers in our code comments are the upstream game's, not ours. [unverified for this game]

- *Evidence:* Roblox advice, untested [official, [Onboarding techniques](https://create.roblox.com/docs/production/game-design/onboarding-techniques), [Funnel events](https://create.roblox.com/docs/production/analytics/funnel-events)]; forced-tutorial complaints in 2 threads [community].
- **Moderate. No test shows shorter is better.**

**7. Verify the Starter offer's claims, then test its pressure rather than assuming either way.** Confirm the "-76%" reference price is real under regional and personalised pricing, and that the 48 h window and "Then it's gone for good." are literally true for each player. Then test the 6 h repeat and the SHOP shake every 6.4 s through Experiments, with Day 1 retention as guardrail. The 25-Robux Takeover on the ELIMINATED screen belongs in the same review. Starter already waits until after the tutorial, has a clear NOT NOW, and a code comment says GameOver cards prompt nothing by themselves, so we appear to be already away from the worst pattern players describe.

- *Evidence:* general misleading-content rule [official, [Community Standards](https://about.roblox.com/community-standards)]; one complaint about pay-before-hook and one thread on repeated prompts [community]; Fortnite, on button confusion rather than countdowns [official via summary, digest]; no public test of timers or pop-ups.
- **Strong that claims must be true. Weak on whether the pressure harms or helps.**

**8. Check interactive UI against notches, and record the safe-area decision.** Main UI sits in a `None` ScreenGui with hand-applied insets, and the top-bar row uses `DeviceSafeInsets` (`src/client/Main.luau:329`). Docs say `None` suits only non-interactive content. The title's crate and Arsenal buttons deliberately sit about halfway into the notch-side band (`UI/TitleScreen.luau:987`). If a notched-phone check passes, keep the approach and update the plan. If not, move interactive parts to `CoreUISafeInsets`. A real phone screenshot on 2026-10-07 already caught one top-bar overlap (`src/client/Main.luau:327-328`). `SafeAreaCompatibility` is not recorded in the inventory, so check it too, since docs advise against the default for new work.

- *Evidence:* official docs, no failure observed on the current HUD.
- **Moderate.**

**9. Close the touch gaps and review the tablet layout.**

- Raise Tutorial Skip and Next (36), rail slots on touch (42), the 34 px close buttons, the 32 px tabs and chips, the phone Locker buy buttons (40 and 34) and party kick (26) to 44. Difficulty chips are already 44 on touch.
- Add a touch route to the era card, and text labels or a touch hint for top-bar icons.
- An iPad at 1024x768 is not `compact`, so it gets the left rail with 50x42 slots. Roblox warns that buttons 40% below the top edge are almost unreachable on a tablet. Check the rail's reach on the device. `ViewportDisplaySize` may be a better signal than logical size, which is worth testing because no doc gives a recipe.
- Confirm SHOP's phone route, which is not in the always-visible list.
- *Evidence:* [Position and size](https://create.roblox.com/docs/en-us/ui/position-and-size.md) [official]; tap numbers from outside Roblox [unverified digest].
- **Moderate on reach. Weak on exact sizes, as 44 is our choice.**

**10. Honour the three player settings.**

- `ReducedMotionEnabled`: applies to the SHOP shake, crate wiggle and Back-eased pop-ins.
- `PreferredTextSize`: replace `TextScaled` on the six labels where text matters (`UI/Arsenal.luau:416`, `UI/ArsenalButton.luau:124`, `UI/CrateButton.luau:142`, `UI/CrateOpening.luau:292`, `:350`, `src/client/Map/StructureLayer.luau:306`), and check whether fixed boxes clip at `Largest`, since our own metrics may not track the setting. Developers report that this setting broke their layouts.
- `PreferredTransparency`: cheap, but our panels are already about 96% opaque, so it changes little.
- Separate volume for effects: Settings has music and border pop switches, and no general effects control.
- *Evidence:* official patterns, no test. **Moderate.**

**11. Decide gamepad scope, and check the 2027 input change.** Console is 3% of average DAU globally, and your dashboard will give the real figure. Smart TVs are announced. If gamepad is in scope, it is new work, with selection navigation across `Widgets`. Separately, test custom input with `Workspace.PlayerScriptsUseInputActionSystem` set to Enabled before its early-2027 default. Consider `PreferredInput` for mixed devices alongside our `TouchEnabled and not MouseEnabled` start (`UI/UIRoot.luau:120-124`).

- *Evidence:* official dates (estimates). Effect on our code is unverified. **Moderate for the migration check. Weak for the value of gamepad.**

**12. Tune motion and loading.**

- The title dock takes 0.7 s after a 1.7 s delay (`UI/TitleScreen.luau:1346`), and the default pop-in takes 0.4 s. Check the play button is not waiting on that.
- Reserve the largest feedback for things the player achieved, such as captures and victory. This extends Kao et al. from an action RPG to UI, so treat it as a hypothesis.
- We have no custom loading screen and wait up to 2.5 s for fonts (`UI/UIRoot.luau:63`). Measure join-to-first-input in the device run, and add a basic `ReplicatedFirst` screen if it is long.
- `UIShadow` could replace our 9-slice panel shadows, since Roblox states it is faster, but it may look jagged at large radii. Low priority until a capture shows a need.
- *Evidence:* NN/g rule of thumb [community]; single study [measured]; Roblox's loading advice [official]. **Weak to moderate.**

**13. Clear leftover names players might see.** "RoWorld General" (`UI/GeneralOffer.luau:2`, `UI/UIRoot.luau:633`) and "Rofront Staging" (`UI/PartyPanel.luau:2`) appear in code or comments. Visible text was not checked. **Measured from source. Player visibility unverified.**

### What the evidence does not support changing

- **Style overhaul:** no evidence favours any style.
- **Library migration:** no measured comparison exists, and the hand-rolled kit is not shown to be a problem.
- **Planning on `UIBlur` or text shadows:** blur is unreleased, and text shadows cannot be published.
- **Chasing the 5% popular non-strategy coverage figure:** genre differs, and it is correlation.
- **Copying pass counts or the global Shop button:** there is no data behind either.

### One-run device checklist

Verify offline first, so the run answers as much as possible: crate routes and odds (change 1), coverage sweep and test (change 3), stretched-string overflow in Studio (change 5), Device Simulator at Entry level and tablet in physical-size mode, on Studio 0.742 or later.

Then one run on one entry-level Android phone and one tablet, ideally plus a notched phone. Capture screenshots at each step.

| Look at | Confirms if |
|---|---|
| Tutorial start to finish | Skip, Next and "Tap here" hit first try. No card covers the target |
| HUD at match start and mid-match with wars | Pill, strip, Build toggle and top row do not overlap Roblox's buttons or the notch |
| Map at default zoom | Names, borders and troop numbers read at arm's length |
| Build tray and a placement | Slots reachable with thumbs. Tray does not hide the placement target |
| Long press, radial, ratio stops | First-try success, no conflict with pinch |
| Title screen | Crate and Arsenal buttons fully tappable beside the notch. Time until PLAY can be pressed |
| Tablet: rail and top row | Upper and lower slots reachable while holding with two hands |
| Roblox's Largest text setting and Reduce Motion | Nothing clips. Motion calms if change 10 has landed |
| Developer Console (F9) on the Android phone | Note memory by `GraphicsTexture` and `Gui`, and frame feel. Compare to the 1.3 GB staff guideline |
| Open Locker, Starter and Arsenal | No blank panels. Prices readable. Close always reachable |

## 7. Open questions

### The name: a release question for the owner

**Conquer The World WW2 by Marian_Dev is live and established, and it already uses the name this project carries.** The owner should decide whether to keep, change or take advice on the name before public release. This report reaches no legal conclusion. Trademark status was not checked.

Facts found, from a single API snapshot at 2026-11-01 03:45 UTC unless stated:

- **CTW WW2:** full name "Conquer The World WW2" plus a seasonal bracket tag, verified creator, created 2023-08-13, updated 2026-10-30, 6,195 playing, 317,697,660 visits, 914,961 favourites. [official, [games API](https://games.roblox.com/v1/games?universeIds=918677693,4983034985,20587584,10768172922,10768464559,10768044367,7685678300,10768553908,10764297006,10769221492,10258991999,9837612476,10563114921,1686885941,66654135,7326934954,383310974,994732206,6035872082,245662005), [place page](https://www.roblox.com/games/14422394494)]
- Its store image shows a "CONQUER THE WORLD" logo. [official, [thumbnails API](https://thumbnails.roblox.com/v1/games/multiget/thumbnails?universeIds=4983034985&size=768x432&format=Png&countPerUniverse=10)]
- YouTubers already use the short form. [community, [2026-09-15](https://www.youtube.com/watch?v=DpmoWgHHP10)]
- Our `README.md` and `NOTICE.md` name this project "Conquer the World", and `NOTICE.md` says it derives from RoWorld. [measured from source]
- A tracker contradicts itself on this game (8,853 vs 6K online, 176.2M vs 317.7M visits), so its all-time peak of 31K is unconfirmed. [community, [RoWatcher](https://rowatcher.com/games/4983034985/conquer-the-world-ww2)]
- A Destructoid URL slug hints at an earlier name. [unverified, [2026-10-15](https://www.destructoid.com/conquer-europe-ww2-codes/)]

Close neighbours, same snapshot. [official, [search API](https://apis.roblox.com/search-api/omni-search?searchQuery=Conquer%20the%20World&pageType=all&sessionId=abc123)]

| Game | Playing | Visits | Created | Note |
|---|---:|---:|---|---|
| RoWorld [World PvP] | 15,571 | 75.7M | 2026-09-26 | Store text credits OpenFront |
| Control The World | 1,114 | 3.0M | 2026-09-28 | Closest wording to our name |
| WorldFront | 2,454 | 9.3M | 2026-09-25 | Same creator group as Control The World |
| Control Europe | 1,457 | 294.7M | 2025-05-11 | |
| Countryball Conquest WW2 | 2,824 | 3.9M | 2026-09-29 | One store image reads "CONQUER EVERYTHING" (unverified) |
| Pixel Front [PvP] | 850 | 80.5M | 2026-08-29 | Store text credits OpenFront |

The name collision is a real risk to discoverability and to how players read the game. The niche is also crowded, with most neighbours created between August and October 2026.

**What would settle it:** the owner's decision, informed by search results for the exact title once published, Marian_Dev's name history (tracker or Wayback snapshot), and legal advice if the owner wants a legal answer.

### Other open questions

| Question | Why it matters | What would settle it |
|---|---|---|
| What is our live HUD coverage? | All our figures are arithmetic | Studio Play with `CTW_DEBUG_UI` set, `hud_coverage` in desktop and phone emulation, in early and mid-match |
| Does the current HUD work on real devices? | "Works live" was reported on 2026-11-01 but not itemised, and predates the current HUD | The one-run checklist in Section 6 |
| How readable are rival map games on a phone? | No phone capture exists of RoN, CTW WW2 or RoWorld | Capture the same screens on a real phone and rerun the boxing method. Add mid-game captures |
| Once per-item odds exist, does our crate flow meet the rounding and placement wording? | See change 1 | Trace all purchase routes. `GeneralOffer` has no odds text (grepped) and advertises a daily crate. Trace Starter's behaviour while ids are 0 |
| Does UI change retention or spend for us? | Nothing public tests it | Funnel events, First Session Retention chart, then Experiments |
| What is our real device and region split? | Global 83% hides per-game differences | Own dashboard after launch |
| Does automatic translation reach our labels? | Fixed boxes may overflow | Read the `AutoLocalize` default, then test with a translated account or locale |
| Are phone and tablet shares known? | Tablet reach differs | Not published. Own dashboard only |
| Is 1024 the real UI image limit? | Asset sizes depend on it | Upload one larger test image and inspect it. Read later pages of the [4K thread](https://devforum.roblox.com/t/4k-texture-rendering/4316229) |
| What do UI elements cost on phones? | No per-element data exists | MicroProfiler capture on a target device |
| What are the exact policy words on imitation? | Excerpts only | Open [Advertising](https://en.help.roblox.com/hc/en-us/articles/13722260778260-Advertising-Standards) and [Commerce Standards](https://en.help.roblox.com/hc/en-us/articles/36495190721172-Commerce-Standards) and the Terms in a browser |
| Does Roblox's gamepad cursor make our menus usable? | Decides gamepad scope | Controller Emulator pass |
| What do real players and children say? | Reddit could not be read, and children are almost absent | Sample r/roblox and r/robloxgamedev by hand. Watch a few young players |
| What are current top-bar sizes and named test devices? | Docs give neither | Read Device Manager in Studio and `TopbarInset` in play sessions |
| Is RoFront a former name of RoWorld? Which sound count is right? | Minor. "Six sound effects" and "118 sounds" are unreconciled | Tracker history; read the audio manifest |

## 8. Scorecard for judging any Roblox screen

Use this on any screen, in any game. Name the game state first (first join, in play, mid-match, menu open). Check it at desktop size and at phone size, and mark each line pass, fail or not checked.

**Evidence labels.** **official**: Roblox. **measured**: observed in a test, study or capture. **community**: designers and forums. **unverified**: search excerpt or inference. Where Roblox publishes no number, the number is ours, marked one of two ways. **Our choice (in code)** is already a constant or test in this project. **Our choice (proposed here)** is suggested by this report and exists nowhere else. A pass means the screen meets the line, not that the game will succeed. No public test ties any line to retention on Roblox.

| | Check | Threshold | Evidence |
|---|---|---|---|
| **Space** | HUD share in play, desktop | 15% or less | Our choice (in code, `UI/HudCoverage.luau:10`). For scale, popular non-strategy games 4.5-5.5%, strategy 7.2-20.6%: measured, hand-placed boxes, early-session, correlation |
| | HUD share in play, phone | 10% or less | Our choice (in code, `UI/HudCoverage.luau:11`). No official number |
| | Interactive items | In `CoreUISafeInsets`, or checked on a notched device | official, no number ([ScreenInsets](https://create.roblox.com/docs/reference/engine/enums/ScreenInsets.md)) |
| | Reserved areas | Nothing important in default phone control corners; top bar read from `TopbarInset` | official, no dimensions ([Position and size](https://create.roblox.com/docs/en-us/ui/position-and-size.md), [GuiService](https://create.roblox.com/docs/reference/engine/classes/GuiService.md)) |
| | Smallest screen checked | Entry level phone, landscape, about 360 logical px tall | Device group official. 360 is our choice (proposed here), from non-Roblox web data |
| **Reading** | Phone text | `TextSize` 15 or more | Our choice (in code, `UI/UIRoot.luau:2507`). No official number; outside figures disagree (unverified) |
| | `MinTextSize` | Not below 9 | official advice ([Size modifiers](https://create.roblox.com/docs/ui/size-modifiers)) |
| | Contrast over the real background | 7:1 body, 4.5:1 secondary, 3:1 tertiary | Our choice (in code, `tests/ui_look.luau`). Roblox gives no ratio (official) |
| | Largest text setting | No clipping at `PreferredTextSize = Largest`; no `TextScaled` on text that matters | official, no number ([Accessibility](https://create.roblox.com/docs/production/publishing/accessibility)) |
| | Map or world labels | Readable on the smallest screen, no clutter zoomed out | community, developer-reported, no number |
| **Touch** | Touch target | 44 logical px or more | Our choice (in code, `UI/UITheme.luau:1195-1197`). Roblox gives no number. Apple 44 pt, Material 48 dp: unverified digest |
| | Frequent actions | In thumb reach. A button 40% below the top edge is almost unreachable on a tablet | official ([Position and size](https://create.roblox.com/docs/en-us/ui/position-and-size.md)) |
| | Hover information | Also reachable by touch | Docs tie hover to the cursor (official). The rule is an inference (unverified) |
| **Clarity** | Main action | One, visibly stronger than the rest | community, 2 sources, no test |
| | Conventions | X closes, grey unusable, lock locked, red price unaffordable | official advice ([UI and UX design](https://create.roblox.com/docs/production/game-design/ui-ux-design)) |
| | Colour | Never the only signal | official ([Accessibility](https://create.roblox.com/docs/production/publishing/accessibility)) |
| | Money button | Has a word on it, one tap from the main screen | measured pattern, correlation |
| | First-time path | One big choice or one pointer; fun in 5 minutes or less | measured pattern, correlation; official advice, not a measured threshold ([Retention](https://create.roblox.com/docs/production/analytics/retention)) |
| **Motion** | Durations | Press about 100 ms, panels 200-300 ms, nothing over 500 ms | community rule of thumb, no experimental data ([NN/g](https://www.nngroup.com/articles/animation-duration/)) |
| | Reduce Motion | `ReducedMotionEnabled` honoured | official ([Accessibility](https://create.roblox.com/docs/production/publishing/accessibility)) |
| | Waits | Over 10 s shows percent done; 2-10 s shows a busy indicator | measured, older research ([NN/g](https://www.nngroup.com/articles/response-times-3-important-limits/)) |
| **Cost** | Frame on an entry-level phone | 16.67 ms or less, in the client | official check at the default 60 FPS cap, not a rule ([Identify performance issues](https://create.roblox.com/docs/en-us/performance-optimization/identify.md)) |
| | Images and effects | Most images 512x512 or less, minor under 256x256; 100 or fewer `UIShadow`; 1000 or fewer gradients | official recommendations, not hard limits ([Improve performance](https://create.roblox.com/docs/performance-optimization/improve), [shadows](https://devforum.roblox.com/t/full-release-new-ui-capabilities-shadows-individual-corners/4636263), [gradients](https://devforum.roblox.com/t/full-release-upgraded-ui-gradients/4846594)) |
| **Money** | Paid random item odds | Every individual outcome, not only rarity tiers, numeric percent, before spending, totalling 100%. If rounded: 4 or more decimals past the first non-zero digit, plus disclaimer. An (i) icon alone fails | official ([Paid random items](https://create.roblox.com/docs/en-us/production/monetization/paid-random-items.md)) |
| | Prices and prompts | Prices read live; prompts come from a button press or NPC | official ([Developer products](https://create.roblox.com/docs/en-us/production/monetization/developer-products.md)) |
| | Offers | None before the player has played; discounts and timers literally true | First part is our choice (proposed here), one community complaint, no test. Second is a general official rule ([Community Standards](https://about.roblox.com/community-standards)) |

**Beyond the screen, check once per release:** only released features in the published build (official); no words baked into images (official, [Automatic translations](https://create.roblox.com/docs/en-us/production/localization/automatic-translations.md)); layout survives longer translated labels (no official figure; pick a test length); one real phone and tablet pass (official, [Test on hardware](https://create.roblox.com/docs/performance-optimization/test-on-hardware)); shop changes run through an Experiment, stopping at playtime -10%, ARPU -20% or payer conversion -20% (official defaults, [Experiments](https://create.roblox.com/docs/production/experiments)).
