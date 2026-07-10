#!/usr/bin/env bash
# Publish GitHub Pages content to surge.sh under one domain:
#
#   https://SURGE_DOMAIN/           landing page (root/index.html in this repo)
#   https://SURGE_DOMAIN/web-apps/  WEB_APPS_REPO, deployed as-is
#   https://SURGE_DOMAIN/blog/      BLOG_REPO, built with Jekyll (baseurl /blog)
#
# Requires: git, node/npx, and ruby with jekyll plus the blog's theme/plugins
# (minima, jekyll-feed, jekyll-sitemap).
#
# Auth: either be logged in to surge already, or set SURGE_LOGIN and
# SURGE_TOKEN in the environment.
set -euo pipefail

WEB_APPS_REPO="${WEB_APPS_REPO:-ferryzhou/web-apps}"
BLOG_REPO="${BLOG_REPO:-ferryzhou/ferryzhou.github.io}"
SURGE_DOMAIN="${SURGE_DOMAIN:-ferryzhou.surge.sh}"

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT
site="$workdir/site"
mkdir -p "$site"

echo "==> Cloning ${WEB_APPS_REPO} -> /web-apps/"
git clone --depth 1 "https://github.com/${WEB_APPS_REPO}.git" "$workdir/web-apps"
rm -rf "$workdir/web-apps/.git"
cp -a "$workdir/web-apps" "$site/web-apps"

echo "==> Cloning ${BLOG_REPO} -> /blog/"
git clone --depth 1 "https://github.com/${BLOG_REPO}.git" "$workdir/blog"
if [ -f "$workdir/blog/_config.yml" ]; then
  echo "==> Building blog with Jekyll (baseurl /blog)"
  if [ -f "$workdir/blog/Gemfile" ]; then
    (cd "$workdir/blog" && bundle install --quiet && bundle exec jekyll build --baseurl /blog --destination "$site/blog")
  else
    (cd "$workdir/blog" && jekyll build --baseurl /blog --destination "$site/blog")
  fi
else
  rm -rf "$workdir/blog/.git"
  cp -a "$workdir/blog" "$site/blog"
fi

# The blog templates hardcode some root-absolute asset paths (e.g. /js/...)
# that bypass Jekyll's baseurl; rewrite them to live under /blog/.
find "$site/blog" -name '*.html' -exec perl -pi -e \
  's{((?:href|src)=")/(?!blog/|/)}{${1}/blog/}g' {} +

echo "==> Adding landing page"
cp "$repo_root/root/index.html" "$site/index.html"

# CNAME files point at GitHub Pages custom domains; surge would treat one at
# the root as the deploy target, and they are noise elsewhere.
find "$site" -name CNAME -delete

for f in index.html web-apps/index.html blog/index.html; do
  [ -f "$site/$f" ] || { echo "error: missing $f in built site; refusing to deploy" >&2; exit 1; }
done

echo "==> Deploying to https://${SURGE_DOMAIN}"
npx --yes surge "$site" "$SURGE_DOMAIN"

echo "==> Done:"
echo "    https://${SURGE_DOMAIN}/"
echo "    https://${SURGE_DOMAIN}/web-apps/"
echo "    https://${SURGE_DOMAIN}/blog/"
