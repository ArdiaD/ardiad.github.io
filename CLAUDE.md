# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

David Ardia's personal academic website — a **single static page** with no build step, framework, or dependencies to install. The entire site is `index.html` + `styles.css` + `img/`. Everything else (`robots.txt`, `sitemap.xml`, `BingSiteAuth.xml`, `CNAME`, favicons) is SEO / hosting plumbing.

Hosted on **GitHub Pages** from the repo root on the `master` branch (remote: `ArdiaD/ardiad.github.io`), served at the custom domain in `CNAME` (**davidardia.com**). There is no CI: pushing `master` triggers the Pages rebuild (~1 min). Convention in this repo has been to **commit on `master` locally and let the owner `git push`** — don't push unless asked.

There are no tests, linters, or build commands. "Running" the site means opening `index.html` in a browser.

## Local preview (important gotcha)

This repo lives under `~/Library/CloudStorage/Dropbox-Personal/...`. macOS TCC blocks sandboxed processes (including the preview server) from reading that path, so a server pointed at the repo dir fails with `Operation not permitted`. **Work around it by serving a copy from `/tmp`:**

```bash
mkdir -p /tmp/siteweb-preview && cp index.html styles.css -R img /tmp/siteweb-preview/
# then serve: cd /tmp/siteweb-preview && python3 -m http.server 4173
```

Re-copy `index.html`/`styles.css` to `/tmp/siteweb-preview/` after each edit, and hard-reload the page (the browser caches `styles.css`). To verify the live deploy, `curl` the davidardia.com URLs directly.

## Architecture & conventions (the non-obvious parts)

### `<head>` is SEO-critical — keep two parallel "Person" descriptions valid
- A **JSON-LD `Person`** block (`<script type="application/ld+json">`) with `sameAs` (Scholar, ORCID, LinkedIn, GitHub, SSRN). After any edit near it, confirm it still `json.loads()`-parses.
- A **microdata `Person`** on the hero `<section>` (`itemscope`/`itemprop="name"|"image"|"sameAs"`). The visible hero social icons carry the `itemprop="sameAs"` links. These two must stay consistent and valid.
- Plus `<link rel="canonical">`, Open Graph (`og:*`), Twitter cards, and `robots`. `canonical`/`og:url` point at `https://davidardia.com/` (NOT the github.io origin).
- The `<title>` is the browser tab text *and* the primary SEO headline — they're the same element, there's no way to separate them.

### CSS cache-busting
`index.html` references the stylesheet as `./styles.css?v=N`. **Bump `N` whenever you change `styles.css`** so returning visitors fetch the new CSS instead of a cached copy. (Currently `?v=15`.)

### Section banding — alternate grey/white
Content sections alternate two structures; preserve the alternation when adding/reordering sections:
- **White:** `<section id="x" class="wrap section">…</section>` (content directly inside).
- **Grey band:** `<section id="x" class="band"><div class="wrap">…</div></section>` (note the extra `.wrap` div — easy to mismatch its `</div>` when editing).

Current order: hero → about (white) → projects (grey) → research (white) → awards (grey) → students (white) → media (grey) → contact (white). The top nav (`.nav-links`) anchor links mirror this order and must be kept in sync.

### Collapsible lists ("Show more") + publication search
Long lists collapse to the first **5** items behind a toggle button, driven by inline `<script>` at the bottom of `index.html`:
- Pattern: a `<ul id="…List">` followed by `<button id="toggle…" class="show-more-btn" hidden>`. The awards/theses/projects toggles share one generalized loop (config array of `{btn, list, label}`); add a new collapsible list by adding an entry there.
- **Research is special:** `#pubSearch` filters across *all* publication `<li>` (title/journal/year/co-author), reveals matches even inside the collapsed tail, and hides the toggle while a query is active. Its render function unifies search + collapse — edit that function rather than adding a separate handler.

### Email is obfuscated on purpose
No plain `mailto:` / address anywhere in source: Contact shows `david.ardia [at] hec.ca` as text, the hero envelope icon links to `#contact`, and the JSON-LD has no `email` field. Don't reintroduce a scrapeable address.

### Images
`img/background.jpg` (web-optimized ~300 KB) is the hero background referenced in CSS; `img/background.png` is the heavy source. Favicons are `img/icon.png` (180²) and `img/icon-192.png`. Regenerate optimized JPEGs with `sips -s format jpeg -s formatOptions <q> in.png --out out.jpg` (plain `sips` without `-s format` silently writes JPEG bytes into a `.png` name — always set the format explicitly).

### External assets (CDN, no local copies)
Open Sans (Google Fonts), Academicons **1.9.4** (the academic icons incl. SSRN/ORCID — older 1.8.x lacks the SSRN glyph), Font Awesome 5.4.1, and Bootstrap 4 (now only used by the footer's `.container`/`.float-right`). Styling lives in `styles.css`, which uses CSS custom properties in `:root` (e.g. `--accent` for the link/accent blue).

## SEO / webmaster context
Verified in Google Search Console (DNS TXT) and Bing Webmaster Tools (`BingSiteAuth.xml`). `robots.txt` points to `sitemap.xml` (single URL). Structured data can be checked at validator.schema.org; note `Person` is **not** a rich-result type, so Google's Rich Results Test correctly reports "no items" (that is not an error).
