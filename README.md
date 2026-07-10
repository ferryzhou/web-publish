# web-publish

Publish my GitHub Pages content to somewhere else, like [surge.sh](https://surge.sh).

GitHub Pages is the primary host. This repo mirrors the same content to a secondary host so the sites stay reachable if github.io is slow, blocked, or down.

## Sites

The list of mirrored sites lives in the `matrix.include` block of
[`.github/workflows/publish.yml`](.github/workflows/publish.yml):

| Source repo           | Published at                    |
|-----------------------|---------------------------------|
| `ferryzhou/web-apps`  | https://ferryzhou.surge.sh      |

To mirror another repo, add an entry to the matrix with its own `domain`
(any `*.surge.sh` name works), e.g.:

```yaml
- repo: ferryzhou/ferryzhou.github.io
  domain: ferryzhou-blog.surge.sh
```

## How it works

For each site in the matrix:

1. The source repo is cloned.
2. If it is a Jekyll site (`_config.yml` present), it is built the same way GitHub Pages builds it. Otherwise the files are deployed as-is.
3. A `CNAME` file, if any, is stripped (it would override the surge domain).
4. The result is pushed to surge with the [surge CLI](https://surge.sh/help/).

The workflow runs on a daily schedule, on demand (`workflow_dispatch`), and on pushes to `main`.

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

Configuration is via environment variables (all optional):

| Variable        | Default                | Meaning                         |
|-----------------|------------------------|---------------------------------|
| `SOURCE_REPO`   | `ferryzhou/web-apps`   | GitHub repo that holds the site |
| `SOURCE_BRANCH` | repo default branch    | Branch to publish from          |
| `SURGE_DOMAIN`  | `ferryzhou.surge.sh`   | Target surge domain             |

If you are already logged in to surge locally, `SURGE_LOGIN`/`SURGE_TOKEN` are not needed.

## Publishing elsewhere

surge is the first target, but the same shape works for other static hosts — swap the final deploy step for `netlify deploy`, `vercel deploy`, `firebase deploy`, etc. The build half of `scripts/publish.sh` is host-agnostic.
