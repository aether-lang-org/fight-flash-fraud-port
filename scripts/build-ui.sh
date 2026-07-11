#!/bin/sh
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
AETHER_UI_DIR="${AETHER_UI_DIR:-/home/paul/scm/aether-ui}"
AE="${AE:-ae}"
AETHERC="${AETHERC:-aetherc}"
SOURCE="${1:-app/fight_flash_fraud.ae}"
OUTPUT="${2:-build/fight_flash_fraud}"
C_FILE="${OUTPUT}.c"

cd "$ROOT"
mkdir -p "$(dirname "$OUTPUT")"

AETHER_INCLUDES="$("$AE" cflags 2>/dev/null | tr ' ' '\n' | grep -E '^-I' | tr '\n' ' ' || true)"
if [ -z "$AETHER_INCLUDES" ]; then
    AETHER_INCLUDES="-I/usr/local/include/aether/runtime -I/usr/local/include/aether/runtime/actors -I/usr/local/include/aether/std -I/usr/local/include/aether/std/collections"
fi

AETHER_LIBS="$("$AE" cflags --libs 2>/dev/null || true)"
AETHER_LIB_PATH="$(printf '%s\n' "$AETHER_LIBS" | tr ' ' '\n' | grep -E '^-L' | head -1 | sed 's/^-L//' || true)"
if [ -z "$AETHER_LIB_PATH" ]; then
    AETHER_LIB_PATH="/usr/local/lib/aether"
fi

echo "Compiling $SOURCE -> $C_FILE"
"$AETHERC" --lib "$AETHER_UI_DIR" --lib "$ROOT/src" "$SOURCE" "$C_FILE"

OS="$(uname -s)"
case "$OS" in
    Linux|FreeBSD)
        if ! pkg-config --exists gtk4 2>/dev/null; then
            echo "Error: GTK4 dev libraries not found." >&2
            exit 1
        fi
        CC_BIN="${CC:-gcc}"
        LIBNOTIFY_CFLAGS=""
        LIBNOTIFY_LIBS=""
        if pkg-config --exists libnotify 2>/dev/null; then
            LIBNOTIFY_CFLAGS="-DAEUI_HAVE_LIBNOTIFY=1 $(pkg-config --cflags libnotify)"
            LIBNOTIFY_LIBS="$(pkg-config --libs libnotify)"
        fi
        "$CC_BIN" -O0 -g -pipe \
            $(pkg-config --cflags gtk4) \
            $AETHER_INCLUDES \
            $LIBNOTIFY_CFLAGS \
            "$C_FILE" \
            "$AETHER_UI_DIR/backend/aether_ui_gtk4.c" \
            "$AETHER_UI_DIR/backend/aether_ui_system_extras.c" \
            "$AETHER_UI_DIR/backend/aether_ui_sni.c" \
            -L"$AETHER_LIB_PATH" -laether \
            -o "$OUTPUT" \
            -pthread -lm $(pkg-config --libs gtk4) $LIBNOTIFY_LIBS $AETHER_LIBS
        ;;
    Darwin)
        clang -O0 -g -fobjc-arc \
            $AETHER_INCLUDES \
            "$C_FILE" \
            "$AETHER_UI_DIR/backend/aether_ui_macos.m" \
            "$AETHER_UI_DIR/backend/aether_ui_system_extras.c" \
            -L"$AETHER_LIB_PATH" -laether \
            -o "$OUTPUT" \
            -framework AppKit -framework Foundation -framework QuartzCore -pthread -lm \
            $AETHER_LIBS
        ;;
    *)
        echo "Error: unsupported platform '$OS'" >&2
        exit 1
        ;;
esac

echo "Built: $OUTPUT"
