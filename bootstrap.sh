#!/usr/bin/env bash
# One-command casual-dev bootstrap for fight_flash_fraud.
#
# This repo expects sibling checkouts:
#   ../aether      Aether compiler/std library
#   ../aether-ui   GTK UI library and AetherUIDriver helpers
#   ../aeocha      Aether BDD test framework
#
# The script creates missing sibling checkouts, builds Aether if needed, then
# builds this app and runs the pure + UI tests.
#
# Env overrides:
#   SCM_DIR        parent checkout dir              (default: ~/scm/AetherThings)
#   AETHER_REF     branch/tag/SHA for clone/update   (default: main)
#   AETHER_UI_REF  branch/tag/SHA for clone/update   (default: main)
#   AEOCHA_REF     branch/tag/SHA for clone/update   (default: main)
#   AE             explicit ae binary               (default: ~/scm/AetherThings/aether/build/ae)
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SCM_DIR="${SCM_DIR:-$HOME/scm/AetherThings}"
AETHER_DIR="$SCM_DIR/aether"
AETHER_UI_DIR="$SCM_DIR/aether-ui"
AEOCHA_DIR="$SCM_DIR/aeocha"
AETHER_REF="${AETHER_REF:-main}"
AETHER_UI_REF="${AETHER_UI_REF:-main}"
AEOCHA_REF="${AEOCHA_REF:-main}"
AE="${AE:-$AETHER_DIR/build/ae}"

say() { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
die() { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

ensure_checkout() {
    local dir="$1" url="$2" ref="$3"
    if [ -d "$dir/.git" ]; then
        say "$(basename "$dir") already checked out"
    else
        mkdir -p "$(dirname "$dir")"
        say "cloning $url -> $dir"
        git clone "$url" "$dir"
    fi
    say "$(basename "$dir"): checkout $ref"
    git -C "$dir" fetch --all --tags --prune
    git -C "$dir" checkout "$ref"
}

command -v git >/dev/null 2>&1 || die "git is required"
command -v make >/dev/null 2>&1 || die "make is required"
command -v cc >/dev/null 2>&1 || command -v gcc >/dev/null 2>&1 || command -v clang >/dev/null 2>&1 \
    || die "a C compiler is required"

ensure_checkout "$AETHER_DIR" "https://github.com/aether-lang-org/aether.git" "$AETHER_REF"
ensure_checkout "$AETHER_UI_DIR" "https://github.com/aether-lang-org/aether-ui.git" "$AETHER_UI_REF"
ensure_checkout "$AEOCHA_DIR" "https://github.com/aether-lang-org/aeocha.git" "$AEOCHA_REF"

if [ ! -x "$AE" ]; then
    say "building Aether compiler"
    make -C "$AETHER_DIR"
fi
[ -x "$AE" ] || die "ae was not built at $AE"

say "building app"
cd "$HERE"
AE="$AE" AETHER_UI_DIR="$AETHER_UI_DIR" make app

say "running tests"
AE="$AE" AEOCHA_DIR="$AEOCHA_DIR" AETHER_UI_DIR="$AETHER_UI_DIR" make test
