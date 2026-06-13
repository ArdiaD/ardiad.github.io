# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

David Ardia's personal academic website — a **single static page** with no build step, framework, or dependencies to install. The whole site is `index.html` + `styles.css` + `img/`. Everything else (`robots.txt`, `sitemap.xml`, `BingSiteAuth.xml`, `CNAME`, favicons) is SEO / hosting plumbing.

Hosted on **GitHub Pages** from the repo root on the `master` branch (remote: `ArdiaD/ardiad.github.io`), served at the custom domain in `CNAME` (**davidardia.com**). There is no CI: pushing `master` triggers the Pages rebuild (~1 min). Convention in this repo: **commit on `master` locally and let the owner `git push`** — don't push unless asked.

There are no tests, linters, or build commands. "Running" the site means opening `index.html` in a browser.

## Local preview (read this — two real gotchas)

1. **The repo path is unreadable to sandboxed tools.** This repo lives under `~/Library/CloudStorage/Dropbox-Personal/...`; macOS TCC blocks sandboxed processes (including the preview server) from reading it (`Operation not permitted`). **Work around it by serving a copy from `/tmp`:**
   ```bash
   mkdir -p /tmp/siteweb-preview && cp index.html styles.css -R img /tmp/siteweb-preview/
   # serve: cd /tmp/siteweb-preview && python3 -m http.server 4173
   ```
   Re-copy `index.html`/`styles.css` into `/tmp/siteweb-preview/` after every edit and hard-reload (the browser caches `styles.css`). If the portrait/background go missing in the preview, re-copy `img/` too. To check the live deploy, `curl` the davidardia.com URLs directly.

2. **The headless preview browser does not fire `IntersectionObserver` or `requestAnimationFrame` callbacks, and does not reflect programmatic `input.checked = true` into the `:checked` CSS state.** This bites any JS verification:
   - Scroll-spy / lazy logic must use plain `scroll`/`resize` listeners (see below), not IO/RAF, or it can't be tested here. After a programmatic `window.scrollTo`, dispatch a synthetic `new Event('scroll')` so the listener fires before you read state.
   - To verify the mobile menu, trigger a **real click** on `label.nav-burger` (the preview click tool) rather than setting `.checked` — only a real click flips `:checked`.
   - The screenshot tool is flaky on mid-page scroll positions (often returns a blank frame); restart the preview server and capture at the top of the page, or just verify via DOM reads (`getComputedStyle`, `getBoundingClientRect`).

## Page structure

Body = sticky `<header>` nav + `<main>` with these sections in order, then footer:

`hero` → `about` → `research` → `software` → `impact` → `teaching` → `students` → `contact`

The 7 `.nav-links` anchors mirror every section except `hero` and **must stay in sync** with the section order. 7 items is about the comfortable maximum for the nav width (see Layout). Several sections bundle subsections under one `<h2>`:
- **About** — 3 paragraphs; the last names the Sentometrics Research and FAME initiatives inline (Projects was folded in here — there is no separate Projects section).
- **Research** — `<h3>` subsections: *Selected publications*, *Working papers*, *Other publications*.
- **Software** — a flat list of CRAN R packages (linked to `CRAN.R-project.org/package=…`).
- **Impact** — `<h3>` subsections: *Awards* and *Media* (formerly two separate sections).
- **Teaching** — short intro + graduate courses by term (French/English sections).
- **Students** — a labelled PhD/MSc intro `<p>` then `<h3>` subsections: *Postdoctoral researchers*, *PhD students*, *MSc theses*, *Supervised projects*.

## Architecture & conventions (the non-obvious parts)

### `<head>` is SEO-critical — keep two parallel "Person" descriptions valid
- A **JSON-LD `Person`** block (`<script type="application/ld+json">`) with `sameAs` (Scholar, ORCID, LinkedIn, GitHub, SSRN) and **no `email`** field (see email obfuscation). After editing near it, confirm it still `json.loads()`-parses.
- A **microdata `Person`** on the hero `<section>` (`itemscope`/`itemprop="name"|"image"|"sameAs"`); the visible hero social icons carry the `itemprop="sameAs"` links.
- Plus `<link rel="canonical">`, Open Graph (`og:*`), Twitter cards, `robots`. `canonical`/`og:url` point at `https://davidardia.com/` (NOT the github.io origin).
- `<title>` is the browser tab text **and** the primary SEO headline — same element, can't be separated (currently "David Ardia — Full IVADO Professor").

### CSS cache-busting
`index.html` references the stylesheet as `./styles.css?v=N`. **Bump `N` whenever you change `styles.css`** so returning visitors fetch the new CSS. Currently `?v=21`. (HTML changes need no bump — Pages serves it fresh.)

### Section banding — alternate grey/white
Sections alternate two structures; preserve the alternation when adding/reordering. Current order is grey/white/grey/white/grey/white/grey: about, research, software, impact, teaching, students, contact.
- **White:** `<section id="x" class="wrap section">…</section>` (content directly inside).
- **Grey band:** `<section id="x" class="band"><div class="wrap">…</div></section>` — note the extra `.wrap` div; mismatching its `</div>` when converting a section between the two is the most common breakage here (it once produced a duplicated heading). Inserting one section flips the parity of everything after it, so converting a neighbouring section band↔wrap is usually needed to keep alternation. After structural edits, run an HTML tag-balance check.

### Layout width — nav aligns to the text column
Content sections use `.wrap` (`max-width: var(--maxw)`, currently 880px, centered, 24px padding). `.nav-inner` uses the **same** `--maxw` + padding so the nav links share the exact horizontal bounds as the body text; the links use `justify-content: space-between` so the first/last align to the text edges. There is **no brand/wordmark** in the header (removed). Don't widen the nav past `--maxw` or it overflows the text column on wide screens.

### Colors / accent
`:root` custom properties drive the palette: `--accent` (link/accent blue, currently `#3366ff`), `--accent-dark` (hover), `--maxw`, `--band` (grey). The accent was chosen to meet **WCAG AA contrast** (~4.6:1 on white) — a lighter blue like `#5b86ff` fails AA for body text, so don't lighten it past roughly `#3366ff` without checking contrast.

### Collapsible lists ("Show more") + scroll-spy + search — all in one inline `<script>`
All client JS lives in a single `<script>` at the bottom of `index.html`, as several IIFEs. Each collapsible list collapses to the first **5** items behind a `<button class="show-more-btn" hidden>` toggle whose label/visibility the JS sets:
- **Impact:** `#toggleAwards` toggles `#awardList` (the awards list). The button sits at the **bottom** of the Impact section (below the Media subsection) on purpose; its label is "Show all impact" / "Show fewer".
- **Students:** one `#toggleStudents` button toggles **two** lists together — `#thesisList` (MSc theses) and `#studentList` (supervised projects); clicking it reveals both. The Postdoc and PhD sub-lists are short and always fully shown.
- **Research:** `#otherPubList` collapses behind `#togglePubs`, **and** `#pubSearch` filters across *all* publication `<li>` (title/journal/year/co-author), revealing matches even inside the collapsed tail and hiding the toggle while a query is active. Search + collapse share one render function — edit that function rather than adding a separate handler.
- **Scroll-spy nav highlight:** a `scroll`/`resize` listener (NOT IntersectionObserver — see preview gotcha) adds `.active` to the nav link of the section whose top is under a ~100px line below the header, with a bottom-of-page fallback to the last section (short trailing sections may never reach the line otherwise).

### Email is obfuscated on purpose
No plain `mailto:` / address anywhere in source: Contact shows `david.ardia [at] hec.ca` as text, the hero envelope icon links to `#contact`, and the JSON-LD has no `email` field. Don't reintroduce a scrapeable address.

### Content entry conventions
Publications/packages/awards/courses/students are hand-authored `<li>`s.
- **Publications** (Research): `<a>Title</a>, <em>Journal</em> YEAR, with Co-authors [Code/Data]`, newest first; the search reads each `<li>`'s text.
- **Software:** `<a>package</a> — short description.` (CRAN links; verify a package resolves before linking — `curl -sIL https://CRAN.R-project.org/package=NAME`).
- **Awards** (Impact): link only the award name (year/affiliation stay plain text); awards without a source URL stay plain.
- **Students:** grouped Postdocs → PhD → MSc theses → Supervised projects, formatted `<em>Title</em>, Name (details)`, newest first.
Escape `&` (e.g. `S&amp;P`, `R&amp;D`) and verify HTML tag balance after large list edits.

### Images
`img/background.jpg` (web-optimized ~300 KB) is the hero background referenced in CSS; `img/background.png` is the heavy source. The hero portrait is `img/Dave.jpg` (200px circle). Favicons are `img/icon.png` (180²) and `img/icon-192.png`. Regenerate optimized JPEGs with `sips -s format jpeg -s formatOptions <q> in.png --out out.jpg` — **always set the format explicitly**; plain `sips` without `-s format` silently writes JPEG bytes into a `.png` filename.

### External assets (CDN, no local copies)
Open Sans (Google Fonts), Academicons **1.9.4** (academic icons incl. SSRN/ORCID — older 1.8.x lacks the SSRN glyph), Font Awesome 5.4.1, Bootstrap 4 (now only the footer's `.container`/`.float-right` use it).

## SEO / webmaster context
Verified in Google Search Console (DNS TXT) and Bing Webmaster Tools (`BingSiteAuth.xml`). `robots.txt` points to `sitemap.xml` (single URL). Validate structured data at validator.schema.org; note `Person` is **not** a rich-result type, so Google's Rich Results Test correctly reports "no items" — that is not an error.
