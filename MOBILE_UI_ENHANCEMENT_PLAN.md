# OptigoAI Mobile UI Enhancement Plan

## Scope and Product Direction

This plan covers the authenticated **single-business branch experience** in `mobile/`.

The franchise and multi-location experience is explicitly out of scope. Existing franchise backend routes, franchise web views, branch switching behavior, and any franchise-specific UI must remain unchanged. The mobile app should continue to display one selected branch and use that branch as the context for every metric, recommendation, review, keyword, campaign, and AI response.

The product direction is:

- Make the app immediately understandable to a local business owner who is not a marketing specialist.
- Replace the Home screen's abstract Marketing Health Score hero with useful answers: what changed, what matters today, and what the app helped improve.
- Use comparisons and trends that are based on measured data, not health-score-derived or invented values.
- Keep the interface calm and scannable. Show a small number of decisions first and allow deeper detail on demand.
- Make every important number explain its time range, source, and comparison period.
- Preserve the current light OptigoAI visual language, brand assets, AI assistant, and five-tab structure unless a change below explicitly improves navigation.

## Current User Flow

### Entry and setup

1. `AuthRouter` checks saved authentication state.
2. Unauthenticated users see `SplashStoryScreen`, then `LoginScreen` or `SignupScreen`.
3. Authenticated users without a completed business see `BusinessOnboardingScreen`.
4. Authenticated users with a completed business enter `MainShell`.
5. `MainShell` holds five screens in an `IndexedStack`:
   - Home
   - Grow
   - Studio
   - Visibility
   - Reviews
6. The top bar opens the account drawer, AI CMO drawer, refresh action, and notifications.
7. The account drawer links to business profile, settings, and logout. The business profile can open the public website builder.

### Core branch-owner journey

The intended journey is:

1. Open Home and understand the latest business movement in under ten seconds.
2. Select one recommended action from Grow.
3. Execute or review that action in Reviews, Visibility, or Studio.
4. Return to Home later and compare current performance with the previous period and the branch's starting baseline.
5. Use Reviews and Visibility for diagnosis, Studio for execution, and the AI CMO for questions or guided actions.

The current UI partially supports this journey, but Home currently tries to be an executive dashboard, action center, review pulse, SEO summary, competitor view, and shortcut menu at once.

## Highest-Priority Issues

### 1. Home presents an abstract score instead of business outcomes

`home_screen.dart` makes Marketing Health Score the first major metric and uses a score-derived weekly reach chart. A user sees `68 Score`, but cannot immediately answer how many more calls, direction requests, views, reviews, or replies the app helped create.

**Change:** remove the score gauge and the `Why score?` path from the Home hero. Keep the score, if still needed by the AI engine, as an internal diagnostic or a secondary detail inside Grow or an insights sheet. Do not use it to generate any displayed metric.

### 2. Several displayed values are synthetic or misleading

Examples found in the mobile and backend paths include:

- Home weekly reach values calculated from `healthScore`.
- Empty review states defaulting to `70.29%` replied and `29.71%` pending.
- Empty sentiment states defaulting to `95%` positive.
- Empty charts defaulting to sample points such as `30, 45, 40, 60, 55, 75, 80`.
- ROI service values such as `1,420` views, `321` calls, `$23,895`, and `4.2x` returned as fixed values.
- Review monthly analysis generated from a formula instead of measured monthly records.

**Change:** every chart and KPI must have one of three explicit states: measured data, unavailable data, or estimated data clearly labelled as estimated. Never show a plausible-looking number as if it were real.

### 3. The mobile app does not consume the existing ROI/dashboard-summary APIs

The backend exposes `/analytics/roi` and `/analytics/dashboard-summary`, but mobile has no analytics repository or analytics model and Home assembles its own values from several repositories.

**Change:** add a branch-scoped analytics client contract and use it as the source for Home and the future Impact view. Keep repository and model work separate from widgets so the UI can be tested with known fixtures.

### 4. Before-and-after impact is not currently measurable

The current data model has dated `BusinessAnalytics` periods, but no explicit onboarding baseline, app activation date, intervention history, or attribution rules. A before/after chart built from current synthetic values would not be trustworthy.

**Change:** establish a baseline at branch activation or first successful GBP sync, record subsequent periods, and compare equivalent periods. Label the result as:

- Before OptigoAI
- Since OptigoAI
- Current period vs previous period

Do not claim revenue impact unless the source and attribution method are visible.

### 5. Important actions are simulated or silently fail

Content publishing currently waits briefly and reports success without a demonstrated provider operation. Several repository failures are swallowed, leaving the user with stale or empty screens and no recovery path.

**Change:** use explicit pending, success, failed, and retry states. A successful message must correspond to a persisted operation or a clearly stated local draft save.

### 6. Dense screens use long labels and too many competing cards

Home, Grow, SEO, and Reviews contain large cards, long copy, horizontal sections, and repeated actions. On the narrow phone layout shown in the screenshots, the user must scroll through multiple similar surfaces before reaching the next decision.

**Change:** establish one primary question per screen, one primary action per card, progressive disclosure for detail, consistent date ranges, and compact reusable KPI/chart components.

## Proposed Information Architecture

Keep the five existing bottom tabs to avoid disrupting the branch workflow:

1. **Home**: Today and measurable progress.
2. **Grow**: Recommended work and automation.
3. **Studio**: Create, preview, save, and publish content.
4. **Visibility**: Search discovery and local ranking.
5. **Reviews**: Reputation and response management.

Add an **Impact / Progress** destination from Home rather than adding a sixth bottom tab. It can be a full-screen route or an expandable Home detail view. This avoids crowding the primary navigation while giving users a dedicated place for before/after analytics.

## Screen-by-Screen Plan

### 1. SplashStoryScreen

**Current role:** animated product introduction with three slides and automatic progression.

**Issues:** the slides make outcome claims such as `+28% Customer Reach`, `#1 on Google Maps`, and `5.0 Review Replied` before the user has data. Tap regions are broad and the five-second auto-advance can feel rushed or inaccessible.

**Planned changes:**

- Replace unsupported numeric claims with capability language: understand, improve, and measure.
- Add visible `Skip` and `Get started` actions that remain available throughout.
- Keep progress indicators but support semantic labels and accessible tap targets.
- Respect reduced-motion preferences and avoid relying on animation to communicate state.

### 2. LoginScreen and SignupScreen

**Current role:** account authentication and password reset entry.

**Issues:** Google sign-up is presented as ready but only displays a success snackbar; reset password also reports success without a service call. Validation is minimal and error messages can expose raw repository text.

**Planned changes:**

- Use truthful copy for unavailable integrations and wire real actions before presenting them as complete.
- Add field-level validation for email, password strength, and duplicate account errors.
- Preserve entered form values after recoverable failures.
- Add loading, retry, and keyboard-safe layouts with accessible labels and focus order.
- Use a consistent authentication error component instead of repeated snackbars.

### 3. BusinessOnboardingScreen

**Current role:** three-step branch profile, audience, services, goals, and channels setup.

**Issues:** default location is `Bengaluru, India`, category defaults to Restaurant / Cafe, and several fields are free text where structured choices would improve data quality. The flow does not establish the baseline required for later impact comparisons.

**Planned changes:**

- Remove assumptions that can silently describe the wrong branch; use empty placeholders and detected location only when confirmed.
- Make the branch identity explicit: business name, address/service area, category, phone, website, and opening hours.
- Add an onboarding step or consented background job for `Starting point` capture: current Google profile metrics, current ranking sample, current review count/rating, and activation date.
- Explain that later progress comparisons depend on the starting point and data availability.
- Add save-and-resume behavior, field-specific errors, completion summary, and a clear sync status after submission.

### 4. MainShell and bottom navigation

**Current role:** five-tab `IndexedStack` with shared top bar.

**Issues:** tabs use internal product terminology (`Grow`, `Studio`, `Visibility`) without a first-use explanation; state is retained but refresh behavior is inconsistent. The shell has no entry point for impact analytics.

**Planned changes:**

- Keep the five tabs and branch-only context unchanged.
- Add a Home progress/impact route instead of a sixth tab.
- Standardize selected-state contrast, semantics labels, and minimum tap targets.
- Add a lightweight first-use explanation for each tab, dismissible and shown once.
- Ensure switching tabs never implies a franchise or multi-branch mode.

### 5. HomeScreen

**Current role:** greeting, AI prompt, health score, weekly reach chart, pulse carousel, growth opportunities, and quick tools.

**Issues:** too many sections compete for attention; score is the hero; weekly reach is score-derived; the one-time carousel auto-scrolls; data is loaded from six sources with no section-level error state; users cannot compare before and after.

**Planned layout:**

1. Top bar with selected branch and sync freshness.
2. **Today at a glance:** three or four compact metrics only, such as customer actions, profile views, rating, and pending replies. Each includes period and comparison.
3. **What changed:** one chart with a 7/30/90 day selector, showing measured customer actions or discovery views and a previous-period comparison.
4. **Your progress with OptigoAI:** a compact before/after summary with baseline date, current period, and available metrics. Link to full Impact detail.
5. **Recommended next step:** one primary action, with a secondary `View all` link to Grow.
6. Optional compact activity feed: latest review, ranking movement, or completed campaign, limited to three items.

**Remove from Home:** the health score bento card, score-derived chart values, auto-advancing carousel, repeated SEO/review/competitor cards, and large quick-action dock. Keep those details in their owning screens.

### 6. RecommendationsScreen / Grow

**Current role:** urgent/growth/automation/completed tabs and action cards.

**Issues:** urgency dominates even when the task is not urgent; impact text is often truncated; sort controls are present but only priority sorting is implemented; automation toggles appear local and may not persist; the screen mixes action execution with automation administration.

**Planned changes:**

- Rename the opening section to `Your next best actions` and show a short reason in plain language.
- Display expected outcome, effort, source, and last updated date separately.
- Show one primary CTA per card, with `Mark done` as a secondary action and undo support.
- Implement all visible sort options or remove unimplemented options.
- Split automation into a settings subsection with clear status, last run, next run, and failure state.
- Add empty states such as `You're caught up` and recovery states with retry.
- Preserve deep links to Reviews, Visibility, and Studio.

### 7. ContentStudioScreen / Studio

**Current role:** choose format, enter campaign details, generate AI posts, edit creative, publish/schedule.

**Issues:** the flow jumps directly to the creative step while generation is pending; defaults are generic and can encourage publishing unreviewed claims; publishing is simulated; the screen is long and combines strategy, copy, design, and scheduling.

**Planned changes:**

- Use a clear three-step progress header: Goal, Draft, Publish.
- Keep a persistent preview and channel selector while editing.
- Add content quality checks: missing offer, unsupported claim, missing business details, dates, and channel length limits.
- Separate `Save draft`, `Schedule`, and `Publish` states and show the provider result.
- Show campaign performance later from the Impact view only when channel data is available.
- Keep the generated copy branch-specific using the selected business profile.

### 8. SeoOptimizerScreen / Visibility

**Current role:** local map score, average rank, visibility trend, distribution, competitors, geo-grid, tracked keywords, audit, schema, and GSC actions.

**Issues:** the map score repeats the health-score pattern; the screen contains several advanced concepts without a simple explanation; ranking and visibility are not always clearly separated; fallback scores and competitor progress can look real; refresh and sync failures are mostly silent; keyword management is buried below multiple charts.

**Planned layout:**

1. `How customers find you` summary: discovery views, searches, calls/directions if available.
2. One measured visibility trend with 7/30/90 day comparison.
3. `Keywords to improve`: top three opportunities with current rank, movement, and next action.
4. `Local competitors`: compact comparison of rank, rating, and review count with source/date.
5. Expandable advanced tools: geo-grid, website audit, schema, keyword discovery, and GSC sync.

**Remove or demote:** the large local map score gauge and any rank-to-score conversion that implies a measured health index.

### 9. ReviewsScreen

**Current role:** sentiment dashboard and review management feed in two internal tabs.

**Issues:** tab labels are long; empty data uses invented percentages and monthly values; sentiment percentages are word-count based and may be misunderstood as customer percentages; reply states and filters are visually heavy; the review reply flow needs clearer publishing confirmation.

**Planned changes:**

- Use shorter tabs: `Overview` and `Manage reviews`.
- Make the first overview answer three questions: rating trend, reply coverage, and themes customers mention.
- Label keyword sentiment as `Mention share`, not customer sentiment, unless the calculation is changed to review-level classification.
- Replace fabricated empty values with `No review data yet` and a sync CTA.
- Add date/source labels to monthly charts and show a true review-volume plus rating trend.
- Add pending-reply count and a focused `Reply now` entry point.
- After reply, show `Saved locally`, `Sent to Google`, or `Needs retry`; never imply Google publication from a local update.

### 10. BusinessProfileScreen

**Current role:** branch profile completeness, information/hours, photos, Google profile actions, and website builder link.

**Issues:** operating hours and photo counts appear hard-coded; completeness can be a misleading percentage when fields are not synced; edit actions and read-only information are not clearly separated.

**Planned changes:**

- Make this the canonical branch profile source for the mobile experience.
- Show each field's source and sync freshness.
- Replace fake hours/photo counts with real data or explicit unavailable states.
- Present completeness as a checklist of missing actions rather than a single score.
- Add `Sync profile` and per-field error/retry states.
- Keep the public website builder link, but clarify that it manages the branch's public site.

### 11. WebsiteBuilderScreen

**Current role:** generate, edit SEO settings, publish/unpublish, preview, and delete the branch public website.

**Issues:** this is a deep workflow reached from the drawer, with destructive delete and publish controls that need stronger confirmation; loading and preview states are not aligned with the rest of the app.

**Planned changes:**

- Add a clear branch identity and current publish status at the top.
- Separate content generation from publishing and show a preview before publish.
- Add unsaved-change protection and a stronger destructive confirmation.
- Show public URL copy/open actions with accessible labels.
- Expose website performance in Impact only when real analytics are connected.

### 12. SettingsScreen and AppSideDrawer

**Current role:** account, billing, preferences, alerts, AI tone, profile, website, and logout.

**Issues:** settings are mostly local state and several save actions show success without persistence; billing and automation language can distract a single-branch owner; drawer business switching risks suggesting a franchise workflow even though this request is branch-only.

**Planned changes:**

- Keep the drawer's current branch context and do not add or redesign franchise features.
- Group settings into Account, Branch profile, Notifications, AI preferences, Subscription, and Help.
- Clearly distinguish account settings from branch settings.
- Persist preference changes or show them as unavailable until connected.
- Add notification preferences for the new progress/impact summaries.
- Add a data freshness/help entry explaining where metrics come from.

### 13. CmoChatDrawer and shared components

**Current role:** context-aware AI assistant available from every major screen.

**Issues:** the welcome message still references Marketing Health; suggested actions are numerous; route actions are not always visibly connected to the current context; errors fall back to generic advice.

**Planned changes:**

- Change the welcome message to explain current measurable progress and next action, without making unsupported claims.
- Limit suggested actions to three context-specific choices.
- Add structured response blocks for `what changed`, `why`, and `next step`.
- Show source/date when the answer uses analytics.
- Add retry and offline wording that does not look like a successful analysis.

## Analytics and Data Contract Plan

### Metrics for the first release

Use a small set of metrics that a branch owner can understand:

- Google Business Profile discovery/search views
- Profile actions: calls, website clicks, direction requests
- Review count, average rating, new reviews, and reply coverage
- Local keyword average rank and Top 3 keyword count
- Content/campaign activity: drafts, published posts, and measurable campaign actions where supported

### Required period fields

Every analytics response should include:

- `period_start`
- `period_end`
- `comparison_period_start`
- `comparison_period_end`
- `source`
- `is_estimated`
- `last_synced_at`
- `data_quality` or `availability_reason`

### Baseline and attribution

Add a branch-level baseline concept, preferably captured when onboarding completes or when the first trusted GBP sync succeeds:

- `baseline_started_at`
- Baseline values for the metrics above
- Data source and confidence
- App activation date

For each later period, calculate absolute and percentage change against an equivalent prior period. Keep these concepts separate:

- **Observed change:** measured difference in Google/website data.
- **OptigoAI activity:** actions completed in the app.
- **Attributed influence:** only used when a campaign or action has a defensible source link.
- **Estimated value:** clearly labelled and based on user-configured average order value, never a fixed backend constant.

### Mobile implementation surfaces

Planned mobile additions:

- `mobile/lib/data/models/analytics_model.dart`
- `mobile/lib/data/repositories/analytics_repository.dart`
- `mobile/lib/presentation/home/widgets/metric_summary_card.dart`
- `mobile/lib/presentation/home/widgets/period_comparison_chart.dart`
- `mobile/lib/presentation/impact/impact_screen.dart` or an equivalent detail route

The Home screen should consume one branch dashboard response where possible instead of independently assembling multiple synthetic summaries.

### Backend work required before impact claims

- Replace fixed values in `RoiAnalyticsService` with dated `BusinessAnalytics` aggregates.
- Add explicit baseline/activation data and equivalent-period queries.
- Return real trend series rather than one current snapshot.
- Return data quality and unavailable states.
- Add campaign/action event linkage if attribution is required.
- Keep franchise endpoints untouched; branch analytics must filter by the selected `business_id` and organization ownership.

## Visual and Interaction System

- Preserve the light OptigoAI palette, but reduce repeated blue gradient hero cards.
- Use one strong accent for primary actions and semantic colors only for positive, warning, and critical states.
- Prefer compact surfaces, dividers, charts, and whitespace over stacked decorative cards.
- Use consistent 7D, 30D, and 90D segmented controls.
- Every chart needs a title, unit, period, comparison, empty state, and accessible summary.
- Avoid auto-scrolling content. Let users swipe or tap `View details`.
- Use minimum 44px touch targets and meaningful semantics labels for charts and icons.
- Avoid truncating business-critical copy; allow expansion for long recommendation explanations.
- Add skeleton loading for initial content and section-level retry for failed data sources.

## Recommended Delivery Phases

### Phase 1: Trust and navigation foundation

- Remove Home health-score hero and score-derived values.
- Remove fabricated mobile empty-state values.
- Standardize loading, error, empty, sync freshness, and retry states.
- Simplify Home into Today, What changed, Progress, and Next action.
- Keep franchise behavior untouched.

### Phase 2: Branch analytics foundation

- Add mobile analytics model/repository.
- Connect `/analytics/dashboard-summary` and dated analytics data.
- Replace fixed ROI values with real branch-period aggregates.
- Add baseline capture and data-quality metadata.

### Phase 3: Impact and comparison experience

- Add the Impact detail destination.
- Implement before/after and current-vs-previous charts.
- Show OptigoAI activity alongside observed business movement.
- Add user-configured average order value only if estimated value is required.

### Phase 4: Screen-specific simplification

- Refine Grow, Studio, Visibility, Reviews, profile, settings, and AI assistant using the screen plans above.
- Remove or wire simulated actions.
- Improve accessibility, responsive layout, copy, and confirmation states.

### Phase 5: Validation and polish

- Add widget tests for Home states, period comparison, empty analytics, errors, and baseline labels.
- Add repository tests for branch isolation and period calculations.
- Test on the screenshot-sized Android viewport and a smaller device.
- Run `flutter analyze` and the mobile test suite.
- Validate backend analytics tests without modifying franchise behavior.

## Acceptance Criteria

- Home no longer presents Marketing Health Score as its primary hero metric.
- No displayed business metric is derived from health score or silently substituted with a sample value.
- Empty, loading, stale, estimated, and failed analytics states are visually distinct.
- A branch owner can understand current performance, change versus the previous period, and the available before/after baseline from Home.
- The user can reach a detailed Impact view without adding a crowded sixth bottom tab.
- Each major chart identifies its metric, unit, period, comparison, and source.
- Recommendations show one clear next step and return to the correct branch feature.
- Review replies, content publishing, profile sync, and analytics sync communicate their real persistence/provider state.
- Branch data remains isolated by `business_id` and organization ownership.
- Franchise screens and franchise behavior remain unchanged.

## Approval Checkpoints Before Code Changes

1. Approve the Home information hierarchy and removal of the score hero.
2. Approve the baseline and before/after metric definitions.
3. Approve whether Impact is a full-screen route or a Home detail sheet.
4. Approve backend changes needed to remove synthetic analytics values.
5. Approve Phase 1 implementation before any Dart code is changed.
