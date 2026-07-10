#!/usr/bin/env bash
# Publish a GitHub Pages site to surge.sh.
#
# Clones SOURCE_REPO, builds it with Jekyll when it looks like a Jekyll site
# (otherwise uses the files as-is), and deploys the result to SURGE_DOMAIN.
#
# Requires: git, node/npx. For Jekyll sources: ruby with jekyll (and bundler
# if the source repo has a Gemfile).
#
# Auth: either be logged in to surge already, or set SURGE_LOGIN and
# SURGE_TOKEN in the environment.
set -euo pipefail

SOURCE_REPO="${SOURCE_REPO:-ferryzhou/web-apps}"
SOURCE_BRANCH="${SOURCE_BRANCH:-}"
SURGE_DOMAIN="${SURGE_DOMAIN:-ferryzhou.surge.sh}"

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

echo "==> Cloning ${SOURCE_REPO}${SOURCE_BRANCH:+ (branch ${SOURCE_BRANCH})}"
git clone --depth 1 ${SOURCE_BRANCH:+--branch "$SOURCE_BRANCH"} \
  "https://github.com/${SOURCE_REPO}.git" "$workdir/source"

site_dir="$workdir/source"

if [ -f "$workdir/source/_config.yml" ]; then
  echo "==> Jekyll site detected, building"
  site_dir="$workdir/site"
  if [ -f "$workdir/source/Gemfile" ]; then
    (cd "$workdir/source" && bundle install --quiet && bundle exec jekyll build --destination "$site_dir")
  else
    (cd "$workdir/source" && jekyll build --destination "$site_dir")
  fi
else
  echo "==> No _config.yml, deploying files as-is"
fi

# A CNAME file points at the GitHub Pages custom domain; surge would try to
# use it as the deploy target, so drop it. .git must not be uploaded either.
rm -rf "$site_dir/.git" "$site_dir/CNAME"

if [ ! -f "$site_dir/index.html" ]; then
  echo "error: no index.html in the built site; refusing to deploy" >&2
  exit 1
fi

echo "==> Deploying to https://${SURGE_DOMAIN}"
npx --yes surge "$site_dir" "$SURGE_DOMAIN"

echo "==> Done: https://${SURGE_DOMAIN}"
