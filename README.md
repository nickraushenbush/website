# nickraushenbush.com

Personal static site: `index.html`, `site.css`, and `blog/`.

Hosted on **GitHub Pages**; custom domain is set in `CNAME` (`www.nickraushenbush.com`).

## Blog posts (Markdown → HTML)

1. Add or edit a file in **`sources/`** (see **`sources/_TEMPLATE.md`** for the exact format).
2. Filename = URL slug, e.g. `my-post.md` → `blog/my-post.html`.
3. From the repo root, run:

   ```bash
   ruby scripts/build_posts.rb
   ```

   That regenerates **`blog/*.html`** and the **Thoughts** list on the homepage (between HTML comments `POST_LIST_START` / `POST_LIST_END`).

4. **Commit and push** to publish.

**With Cursor:** describe a new post or paste rough notes and ask the agent to add it; the project rule **blog-publishing** describes the workflow (or `@` mention that rule).
