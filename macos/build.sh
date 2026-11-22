#!/bin/zsh
# Builds the macOS menu-bar app and installs ~/Applications/OllamaMonitor.app.
# Build products live in ~/Library/Developer/OllamaMonitor, outside the repo.
#
# Usage: ./build.sh                 release build, install
#        ./build.sh --open          install, then restart the running copy
#        ./build.sh --snapshot DIR  debug build, render the popover and Settings to DIR, no install
set -euo pipefail
here=${0:A:h}
name="OllamaMonitor"
scratch="$HOME/Library/Developer/$name/build"

if [[ "${1:-}" == "--snapshot" ]]; then
  swift build --package-path "$here" --scratch-path "$scratch" 2>&1 | grep -E "error|warning:" || true
  exec "$scratch/debug/$name" --snapshot "${2:?usage: ./build.sh --snapshot DIR}"
fi

# Apple Development certificate when there is one, else ad hoc (fine for your own Mac).
identity="${SIGN_IDENTITY:-}"
[[ -n "$identity" ]] || identity=$(security find-identity -v -p codesigning 2>/dev/null | grep -m1 -o '"Apple Development: [^"]*"' | tr -d '"' || true)
[[ -n "$identity" ]] || identity=-

swift build -c release --package-path "$here" --scratch-path "$scratch" 2>&1 | grep -E "error|warning:" || true
bin="$scratch/release/$name"
[[ -x "$bin" ]] || { echo "build failed"; exit 1; }
# swift build can report success while an edited file failed to compile.
stale=$(find "$here/Sources" -name '*.swift' -newer "$bin" | head -1)
[[ -z "$stale" ]] || { echo "build failed: binary is older than $stale"; exit 1; }

app="$HOME/Applications/$name.app"
osascript -e "quit app id \"com.bryanjordan.$name\"" 2>/dev/null || true
pkill -x "$name" 2>/dev/null || true # the older Go build has no bundle id to quit by
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$bin" "$app/Contents/MacOS/$name"
sed -e "s/__BUILD__/$(date +%Y%m%d%H%M)/" "$here/Info.plist.in" > "$app/Contents/Info.plist"

# App icon from the repo logo (a PNG inside an .ico wrapper, so convert explicitly).
iconset=$(mktemp -d)/AppIcon.iconset
mkdir -p "$iconset"
for s in 16 32 128 256 512; do
  sips -s format png -z $s $s "$here/../logo.png" --out "$iconset/icon_${s}x${s}.png" >/dev/null
  sips -s format png -z $((s*2)) $((s*2)) "$here/../logo.png" --out "$iconset/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns "$iconset" -o "$app/Contents/Resources/AppIcon.icns"

xattr -cr "$app"
codesign --force --sign "$identity" "$app" 2>&1 | grep -v "replacing existing signature" || true
echo "installed $app (signed: $identity)"

[[ " $* " == *" --open "* ]] && open "$app"
exit 0
