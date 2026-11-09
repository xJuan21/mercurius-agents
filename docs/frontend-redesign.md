# Frontend redesign — 2026-11-09

Dark navy and blue theme based on Juan's supplied Sign In and Dashboard references. The supplied JPEG logo is used unchanged; CSS frames it for each layout. `web/public/particle-wave.svg` is a replaceable procedural decoration pending final artwork.

- Sign-in retains IRIS JWT authentication and adds an accessible password visibility toggle.
- Dashboard is the default authenticated route. Counts come from `/summary` and `/agents`; recent proposals and executions use existing APIs. Refresh is manual and labelled. Errors retain the last successful snapshot.
- Agent status means configured Enabled/Disabled, not live runtime availability. Pending reviews counts proposed actions; open conflicts is separate.
- Review links open the existing detail workflow before approving actions. Proposal previews are limited by the existing latest-100 endpoint; an explicit message handles pending actions outside that window.
- Existing Chat, Agents, Review, Inbox, Memory, History and Knowledge layouts are retained with dark tokens and surfaces. The dashboard alone omits the agent detail sidebar.
- Only ObjectScript change: image/jpeg and image/png MIME types in `Mercurius.API.Web`. No runtime or authentication changes.

## Deployment

Source: `dev` on iris01, `~/mercurius-agents`. Deployed only to `mercurius-agents-iris-1`, port **52775**, by copying the production Angular build into `/usr/irissys/csp/mercurius/` and compiling `Mercurius.API.Web`. Pre-change static files are in `/tmp/mercurius-ui-backup` on iris01. No container recreation or data reset. Future Docker builds include these sources via the existing build stage.

## Validation

Production Angular build passes. Existing `Mercurius.Test.Acceptance.Run()` passes all 16 checks (this suite writes its normal test fixtures). Browser checks cover anonymous API rejection, wrong-password feedback, password visibility, real API/dashboard count equality, session reload, all seven existing routes, a benign Sentinel chat through the production, agent editor, refresh failure/recovery, 390px navigation and layout, sign-out and zero page exceptions.

Browser script: `web/e2e/frontend-smoke.cjs`. Requires Playwright 1.49.1 and its Chromium browser. Supply `TEST_USER` and `TEST_PASSWORD` in the process environment; optional `TEST_URL` and `SCREENSHOT_DIR`. Credentials must not be committed. The script submits one benign Sentinel message, so use a development instance. Browser-only mock tests supplement live data for empty and populated dashboard states.
