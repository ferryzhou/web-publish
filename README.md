# web-publish

Publish my GitHub Pages content to somewhere else, like [surge.sh](https://surge.sh).

GitHub Pages is the primary host. This repo mirrors the same content to a secondary host so the sites stay reachable if github.io is slow, blocked, or down.

## Layout

Everything is published under one surge domain:

| URL                                  | Source                            |
|--------------------------------------|-----------------------------------|
| https://ferryzhou.surge.sh/          | landing page ([`root/index.html`](root/index.html)) |
| https://ferryzhou.surge.sh/web-apps/ | `ferryzhou/web-apps`, deployed as-is |
| https://ferryzhou.surge.sh/christian-film-reviews/ | `ferryzhou/christian-film-reviews`, deployed as-is |
| https://ferryzhou.surge.sh/blog/     | `ferryzhou/ferryzhou.github.io`, built with Jekyll |

## How it works

`scripts/publish.sh` composes a single site directory and deploys it:

1. Clone each repo in `STATIC_REPOS` into a folder named after it
   (plain static files, no build). Adding another static repo to the
   mirror is a one-word change to the `STATIC_REPOS` default (plus a
   link in `root/index.html`).
2. Clone the blog, build it with Jekyll using `--baseurl /blog` so its links
   resolve under the subpath, into `blog/`. Hardcoded root-absolute asset
   paths in the built HTML (which bypass Jekyll's baseurl) are rewritten to
   `/blog/...`.
3. Copy the landing page to the site root and strip any `CNAME` files
   (surge would treat one as the deploy target).
4. Push the whole directory to surge with the [surge CLI](https://surge.sh/help/).

The GitHub Actions workflow (`.github/workflows/publish.yml`) runs the same
script on a daily schedule, on demand (`workflow_dispatch`), and on pushes
to `main`.

## Setup (GitHub Actions)

1. Get surge credentials on a machine with node:

   ```sh
   npm install --global surge
   surge login    # log in or create an account
   surge token    # prints your token
   ```

2. In this repo's **Settings → Secrets and variables → Actions**, add:

   | Secret        | Value                                |
   |---------------|--------------------------------------|
   | `SURGE_LOGIN` | the email you used for `surge login` |
   | `SURGE_TOKEN` | the output of `surge token`          |

3. Run the **Publish to surge.sh** workflow from the Actions tab (or wait for the daily run).

## Local usage

```sh
SURGE_LOGIN=you@example.com SURGE_TOKEN=xxxx ./scripts/publish.sh
```

Requires git, node, and ruby with the blog's Jekyll dependencies
(`gem install jekyll minima jekyll-feed jekyll-sitemap`).

Configuration is via environment variables (all optional):

| Variable       | Default                                            | Meaning                                    |
|----------------|----------------------------------------------------|--------------------------------------------|
| `STATIC_REPOS` | `ferryzhou/web-apps ferryzhou/christian-film-reviews` | Space-separated repos published at `/<name>/` |
| `BLOG_REPO`    | `ferryzhou/ferryzhou.github.io`                    | Repo published at `/blog/`                 |
| `SURGE_DOMAIN` | `ferryzhou.surge.sh`                               | Target surge domain                        |

If you are already logged in to surge locally, `SURGE_LOGIN`/`SURGE_TOKEN` are not needed.

## Publishing elsewhere

surge is the first target, but the same shape works for other static hosts — swap the final deploy step for `netlify deploy`, `vercel deploy`, `firebase deploy`, etc. The build half of `scripts/publish.sh` is host-agnostic.
