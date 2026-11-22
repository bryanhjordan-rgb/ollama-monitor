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
tmpdir=""
trap '[[ -n "$tmpdir" ]] && rm -rf "$tmpdir"' EXIT

if [[ "${1:-}" == "--snapshot" ]]; then
  out=$(swift build --package-path "$here" --scratch-path "$scratch" 2>&1) || { echo "$out"; exit 1; }
  [[ -n "$out" ]] && printf '%s\n' "$out" | grep -E "error|warning:" || true
  exec "$scratch/debug/$name" --snapshot "${2:?usage: ./build.sh --snapshot DIR}"
fi

# Apple Development certificate when there is one, else ad hoc (fine for your own Mac).
identity="${SIGN_IDENTITY:-}"
[[ -n "$identity" ]] || identity=$(security find-identity -v -p codesigning 2>/dev/null | grep -m1 -o '"Apple Development: [^"]*"' | tr -d '"' || true)
[[ -n "$identity" ]] || identity=-

out=$(swift build -c release --package-path "$here" --scratch-path "$scratch" 2>&1) || { echo "$out"; exit 1; }
[[ -n "$out" ]] && printf '%s\n' "$out" | grep -E "error|warning:" || true
bin="$scratch/release/$name"
[[ -x "$bin" ]] || { echo "build failed"; exit 1; }

app="$HOME/Applications/$name.app"
osascript -e "quit app id \"com.bryanjordan.$name\"" 2>/dev/null || true
pkill -x "$name" 2>/dev/null || true # the older Go build has no bundle id to quit by
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$bin" "$app/Contents/MacOS/$name"
sed -e "s/__BUILD__/$(date +%Y%m%d%H%M)/" "$here/Info.plist.in" > "$app/Contents/Info.plist"

# App icon from the blue tray PNG.
tmpdir=$(mktemp -d)
iconset="$tmpdir/AppIcon.iconset"
mkdir -p "$iconset"
for s in 16 32 128 256 512; do
  sips -s format png -z $s $s "$here/../monitor/icons/icon_blue.png" --out "$iconset/icon_${s}x${s}.png" >/dev/null
  sips -s format png -z $((s*2)) $((s*2)) "$here/../monitor/icons/icon_blue.png" --out "$iconset/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns "$iconset" -o "$app/Contents/Resources/AppIcon.icns"

xattr -cr "$app"
out=$(codesign --force --sign "$identity" "$app" 2>&1) || { echo "$out"; exit 1; }
[[ -n "$out" ]] && printf '%s\n' "$out" | grep -v "replacing existing signature" || true
echo "installed $app (signed: $identity)"

[[ " $* " == *" --open "* ]] && open "$app"
exit 0
