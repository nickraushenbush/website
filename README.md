# Personal site (GitHub Pages)

Static site: `index.html`, `site.css`, and `blog/`.

## Before you start

1. Pick your **GitHub username** (e.g. `nickraushenbush`).
2. Pick your **domain** (e.g. `nickraushenbush.com`).
3. We use **`www` as the main URL** (recommended with GitHub Pages + GoDaddy).

---

## Part A — Prepare this folder (one-time)

1. **Create `CNAME`** (required for custom domain):
   - Copy `CNAME.example` to a new file named **`CNAME`** (no extension).
   - Open `CNAME` and replace `www.yourdomain.com` with your real domain, e.g. `www.nickraushenbush.com`.
   - Save. The file must contain **only that one line** (no `https://`, no quotes).

2. **Commit everything** (from this folder in Terminal):

   ```bash
   cd /path/to/website
   git add -A
   git commit -m "Initial site for GitHub Pages"
   ```

---

## Part B — GitHub (do these clicks in order)

### B1. New repository

1. Log in at [github.com](https://github.com).
2. Top-right **+** → **New repository**.
3. **Repository name:** e.g. `website` or `nickraushenbush.github.io`  
   - Either name works. If you use `username.github.io`, the default Pages URL is `https://username.github.io` (still add custom domain below if you want your own domain).
4. **Public** (required for free GitHub Pages on personal accounts unless you use GitHub Pro with private repos).
5. **Do not** add README / .gitignore / license (this repo already has files).
6. Click **Create repository**.

### B2. Push your code

On the empty repo page, GitHub shows commands. Use **SSH or HTTPS** — example with `main`:

```bash
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
git branch -M main
git push -u origin main
```

Replace `YOUR_USERNAME` and `YOUR_REPO`. Enter GitHub credentials or use SSH as you normally do.

### B3. Turn on GitHub Pages

1. Open your repo on GitHub.
2. Click **Settings** (repo tabs).
3. Left sidebar → **Pages** (under “Code and automation”).
4. Under **Build and deployment** → **Source**: choose **Deploy from a branch**.
5. **Branch:** `main`, folder **`/ (root)`** → **Save**.
6. Wait 1–3 minutes. Refresh **Pages** — you should see “Your site is live at `https://YOUR_USERNAME.github.io/YOUR_REPO/`” (URL depends on repo name).

### B4. Custom domain + HTTPS

1. Still in **Settings** → **Pages**.
2. Under **Custom domain**, type: **`www.yourdomain.com`** (your real domain).
3. Click **Save**.
4. Check **Enforce HTTPS** when it becomes available (may take a few minutes after DNS is correct).

GitHub may show a DNS check — that’s OK until you finish GoDaddy (Part C).

---

## Part C — GoDaddy DNS (after B3 or B4)

1. Log in at [godaddy.com](https://godaddy.com) → **My Products**.
2. Find your domain → **DNS** or **Manage DNS** (wording varies).
3. Open the **DNS records** / **Records** list for that domain.

### C1. Point `www` to GitHub

1. Find an existing **`www`** record:
   - If it’s **CNAME** → **Edit**.
   - If it’s **A** → **Delete** it (GitHub wants CNAME for `www`).
2. Set:
   - **Type:** `CNAME`
   - **Name / Host:** `www`
   - **Value / Points to:** `YOUR_USERNAME.github.io`  
     (replace with your GitHub username — **no** `https://`, **no** trailing slash)
   - **TTL:** 600 or 1 hour (either is fine)

Save.

### C2. Point the root domain (`@`) to GitHub Pages

1. Find **`@`** or **A** records for the root that point to **Ghost** or old host — **delete or replace** those (only the ones used for the website, not mail).
2. Add **four** **A** records for **`@`** (same host, different IPs):

   | Type | Name | Value           |
   |------|------|-----------------|
   | A    | `@`  | `185.199.108.153` |
   | A    | `@`  | `185.199.109.153` |
   | A    | `@`  | `185.199.110.153` |
   | A    | `@`  | `185.199.111.153` |

   In GoDaddy, “Name” for root is often `@` or blank — use what their UI shows for the apex domain.

Save.

### C3. Do not break email

- **Do not delete** `MX`, `TXT` (SPF), or other records for email unless you know you’re replacing them.

### C4. Wait and verify

- DNS can take **minutes to 48 hours** (often under 30 minutes).
- Visit `https://www.yourdomain.com` — you should see this site.
- In GitHub **Settings** → **Pages**, the custom domain should show as verified; then enable **Enforce HTTPS**.

---

## Order summary (checklist)

1. [ ] Create **`CNAME`** file from `CNAME.example` with your real `www` domain.
2. [ ] `git commit` (and push when remote exists).
3. [ ] GitHub: **New repo** → **Push** → **Settings → Pages** → branch `main`, `/ (root)`.
4. [ ] GitHub: **Custom domain** = `www.yourdomain.com` → Save.
5. [ ] GoDaddy: **`www` CNAME** → `YOUR_USERNAME.github.io`.
6. [ ] GoDaddy: **`@` A records** → four GitHub IPs above.
7. [ ] Wait for DNS → **Enforce HTTPS** on GitHub Pages.

---

## Optional: redirect bare domain to www

If `https://yourdomain.com` doesn’t redirect to `https://www.yourdomain.com`, use GoDaddy **Forwarding** for the root to `https://www.yourdomain.com` (301), **or** rely on GitHub Pages + correct DNS once the custom domain is set to `www` in repo settings.

---

## Local preview

Open `index.html` in a browser, or from this folder:

```bash
python3 -m http.server 8080
```

Then visit `http://localhost:8080`.
