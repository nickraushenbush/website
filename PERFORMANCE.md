# Performance notes

This site is static HTML + one stylesheet, with no runtime JS bundles or web fonts in the critical path.

## Stylesheet

- **Source:** [`site.css`](site.css) — edit this file.
- **Served:** [`site.min.css`](site.min.css) — minified output linked from pages. Regenerate after any `site.css` change:

  ```bash
  npm install
  ruby scripts/minify_css.rb
  ```

  (Requires Node.js; `clean-css-cli` is installed from [`package.json`](package.json) into `node_modules/`.)

## When to split “critical” CSS

The whole layout currently fits in a **single small stylesheet**, which keeps requests and cache behavior simple.

**Threshold:** If uncompressed [`site.css`](site.css) grows beyond **~15 KB** (roughly 2–3× today’s size), consider:

- Inlining a minimal “above the fold” block in `<head>`, and
- Loading the rest asynchronously or as a second file for non-critical rules.

Until then, one minified file is the right tradeoff.

## Mobile

- Blog post HTML loads **`theme-init.js`** in `<head>` (avoids theme flash) and **`theme-toggle.js`** at the **end of `<body>`** so `<main>` parses earlier.
- Entry animations are disabled for **viewports ≤640px** and for **`prefers-reduced-motion: reduce`**.

## Measuring

Use Lighthouse (mobile throttling) or WebPageTest on the homepage and a long blog post; track **FCP** and **LCP** before/after changes.

### Sample run (local, mobile emulation)

Served with `python3 -m http.server 8765 --bind 127.0.0.1` from the repo root, then:

```bash
npx lighthouse@11 http://127.0.0.1:8765/ \
  --only-categories=performance --screenEmulation.mobile \
  --chrome-flags="--headless=new --no-sandbox"
```

| Page (local) | FCP | LCP | TBT | Perf score |
|--------------|-----|-----|-----|------------|
| `/` (home) | ~0.75s | ~0.90s | ~0ms | 1.0 |
| `/blog/y-combinator-application-breakdown-and-guide.html` | ~0.90s | ~1.05s | ~0ms | 1.0 |

Figures vary by machine and Chrome version; use the same command to compare before/after changes.
