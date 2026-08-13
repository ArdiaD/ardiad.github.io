# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

David Ardia's personal academic website — **three hand-written static pages** with no build step, framework, or dependencies to install: `index.html` (Home), `research.html`, `teaching.html`, plus `styles.css` + `img/`. Everything else (`robots.txt`, `sitemap.xml`, `BingSiteAuth.xml`, `CNAME`, favicons) is SEO / hosting plumbing.

**Multi-page upkeep:** the `<head>`, the `<header>` nav and the `<footer>` are duplicated in all three files — change one, change all three. Each page needs its own `<title>`, `<meta description>`, `canonical` and `og:url`; the nav marks the current page with `class="active"`. Adding a page also means adding it to `sitemap.xml`.

Hosted on **GitHub Pages** from the repo root on the `master` branch (remote: `ArdiaD/ardiad.github.io`), served at the custom domain in `CNAME` (**davidardia.com**). There is no CI: pushing `master` triggers the Pages rebuild (~1 min). Convention in this repo: **commit on `master` locally and let the owner `git push`** — don't push unless asked.

There are no tests, linters, or build commands. "Running" the site means opening `index.html` in a browser.

## Local preview (read this — two real gotchas)

1. **The repo path is unreadable to sandboxed tools.** This repo lives under `~/Library/CloudStorage/Dropbox-Personal/...`; macOS TCC blocks sandboxed processes (including the preview server) from reading it (`Operation not permitted`). **Work around it by serving a copy from `/tmp`:**
   ```bash
   mkdir -p /tmp/siteweb-preview && cp index.html research.html teaching.html styles.css /tmp/siteweb-preview/ && cp -R img /tmp/siteweb-preview/
   # serve: cd /tmp/siteweb-preview && python3 -m http.server 4173
   ```
   Re-copy the edited HTML/`styles.css` into `/tmp/siteweb-preview/` after every edit and hard-reload (the browser caches `styles.css`). If the portrait/background go missing in the preview, re-copy `img/` too. To check the live deploy, `curl` the davidardia.com URLs directly.

2. **The headless preview browser does not fire `IntersectionObserver` or `requestAnimationFrame` callbacks, and does not reflect programmatic `input.checked = true` into the `:checked` CSS state.** This bites any JS verification:
   - Scroll-spy / lazy logic must use plain `scroll`/`resize` listeners (see below), not IO/RAF, or it can't be tested here. After a programmatic `window.scrollTo`, dispatch a synthetic `new Event('scroll')` so the listener fires before you read state.
   - To verify the mobile menu, trigger a **real click** on `label.nav-burger` (the preview click tool) rather than setting `.checked` — only a real click flips `:checked`.
   - The screenshot tool is flaky on mid-page scroll positions (often returns a blank frame); restart the preview server and capture at the top of the page, or just verify via DOM reads (`getComputedStyle`, `getBoundingClientRect`).

## Page structure

Every page = sticky navy `<header>` nav (Home · Research · Teaching, linking to the three files) + `<main>` of white cards + shared footer.

- **index.html** — `hero` → `about` → `publications` (Selected publications + a link to research.html) → `impact`
- **research.html** — `research` (interests, search, working papers, all publications with the tabs) → `software`
- **teaching.html** — `teaching` → `students`

There is no Contact section: the obfuscated email and address live in the footer, which carries `id="contact"` so the `#contact` links (About envelope icon, the two Students links) still resolve. Several sections bundle subsections under one `<h2>`:
- **About** — 3 paragraphs; the last names the Sentometrics Research and FAME initiatives inline (Projects was folded in here — there is no separate Projects section).
- **Research** (research.html) — `<h3>` subsections: *Research interests*, *Working papers*, *Other publications* (the tabbed list). *Selected publications* is a separate short section on the **home** page.
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
`index.html` references the stylesheet as `./styles.css?v=N`. **Bump `N` whenever you change `styles.css`** so returning visitors fetch the new CSS. Currently `?v=26`, and the reference must be bumped in **all three** HTML files. (HTML changes need no bump — Pages serves it fresh.)

### Sections are white cards on a grey page
`main > section` is styled as a white rounded card on the `--page` grey background, so the two legacy structures now look identical and the old grey/white banding no longer matters:
- `<section id="x" class="wrap section">…</section>` (content directly inside), or
- `<section id="x" class="band"><div class="wrap">…</div></section>` (extra `.wrap` div — mismatching its `</div>` is the most common breakage here). `main > section > .wrap` has its max-width/padding neutralised so the card controls the width.

After structural edits, run an HTML tag-balance check.

### Layout width — nav aligns to the text column
Content sections use `.wrap` (`max-width: var(--maxw)`, currently 880px, centered, 24px padding). `.nav-inner` uses the **same** `--maxw` + padding so the nav links share the exact horizontal bounds as the body text; the links use `justify-content: space-between` so the first/last align to the text edges. There is **no brand/wordmark** in the header (removed). Don't widen the nav past `--maxw` or it overflows the text column on wide screens.

### Colors / accent
`:root` custom properties drive the palette, modelled on tintin.hec.ca/pages/tolga.cenesizoglu: `--navy` `#001f4d` (header bar, headings), `--accent` `#003d7a` (links), `--page` `#f7f7f9` (page background behind the white cards), `--line` `#e0e0e0`, `--maxw`. Both blues clear **WCAG AA** on white by a wide margin; keep any replacement at least as dark. The hero portrait is a **square with 12px rounded corners**, not a circle.

### Collapsible lists ("Show more") + topic tabs + search — one shared inline `<script>`
All client JS lives in a single `<script>` at the bottom of each page (identical copy in all three), as several IIFEs. Each collapsible list collapses to the first **5** items behind a `<button class="show-more-btn" hidden>` toggle whose label/visibility the JS sets:
- **Impact:** `#toggleAwards` toggles `#awardList` (the awards list). The button sits at the **bottom** of the Impact section (below the Media subsection) on purpose; its label is "Show all impact" / "Show fewer".
- **Students:** `#toggleTheses` collapses `#thesisList` (MSc theses). Postdocs and PhD students are short lists, always fully shown; *Supervised projects* is no longer a list of 67 titles but a curated set of six research themes.
- **Research:** `#otherPubList` collapses behind `#togglePubs`, **and** `#pubSearch` filters across *all* publication `<li>` (title/journal/year/co-author), revealing matches even inside the collapsed tail and hiding the toggle while a query is active. Search + collapse share one render function — edit that function rather than adding a separate handler.
- **Publication topics:** each `<li>` in `#otherPubList` carries a `data-topic` (`risk`, `nlp`, `portfolio`, `methods`, `software`, `climate`, `micro`). The `#pubTabs` buttons switch between the chronological list and `#pubByTopic`, which the JS fills by **moving** (not cloning) the `<li>` nodes into per-topic lists — so search keeps working in both views. New publications need a `data-topic` or they vanish from the topic view.

The same `<script>` block is copied into all three pages; every IIFE returns early when its elements are missing, so it is safe everywhere. The nav's current page is marked with `class="active"` in the HTML (there is no scroll-spy any more).

### Email is obfuscated on purpose
No plain `mailto:` / address anywhere in source: Contact shows `david.ardia [at] hec.ca` as text, the hero envelope icon links to `#contact`, and the JSON-LD has no `email` field. Don't reintroduce a scrapeable address.

### Content entry conventions
Publications/packages/awards/courses/students are hand-authored `<li>`s.
- **Publications** (Research): `<a>Title</a>, <em>Journal</em> YEAR, with Co-authors [Code/Data]`, newest first; the search reads each `<li>`'s text.
- **Software:** `<a>package</a> — short description.` (CRAN links; verify a package resolves before linking — `curl -sIL https://CRAN.R-project.org/package=NAME`).
- **Awards** (Impact): link only the award name (year/affiliation stay plain text); awards without a source URL stay plain.
- **Students:** Postdocs → PhD → MSc theses listed as `<em>Title</em>, Name (details)`, newest first; *Supervised projects* is a themed summary, not a list.
Escape `&` (e.g. `S&amp;P`, `R&amp;D`) and verify HTML tag balance after large list edits.

### Images
`img/background.jpg` (web-optimized ~300 KB) is the hero background referenced in CSS; `img/background.png` is the heavy source. The hero portrait is `img/Dave.jpg` (200px circle). Favicons are `img/icon.png` (180²) and `img/icon-192.png`. Regenerate optimized JPEGs with `sips -s format jpeg -s formatOptions <q> in.png --out out.jpg` — **always set the format explicitly**; plain `sips` without `-s format` silently writes JPEG bytes into a `.png` filename.

### External assets (CDN, no local copies)
Open Sans (Google Fonts), Academicons **1.9.4** (academic icons incl. SSRN/ORCID — older 1.8.x lacks the SSRN glyph), Font Awesome 5.4.1, Bootstrap 4 (now only the footer's `.container`/`.float-right` use it).

## SEO / webmaster context
Verified in Google Search Console (DNS TXT) and Bing Webmaster Tools (`BingSiteAuth.xml`). `robots.txt` points to `sitemap.xml`, which lists the three page URLs. Validate structured data at validator.schema.org; note `Person` is **not** a rich-result type, so Google's Rich Results Test correctly reports "no items" — that is not an error.
