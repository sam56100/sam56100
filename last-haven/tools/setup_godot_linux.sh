#!/usr/bin/env bash
# Developer-only helper for Linux CLOUD/CI sessions: gets a headless Godot 4 binary when the
# official download hosts are blocked, so tools/check.py can run there.
#
# It downloads the `godot` package published in the Ubuntu 25.10 ("questing") archive plus its
# dependencies and unpacks them into a private folder. Nothing is installed system-wide.
#
# IMPORTANT: this is Godot 4.4.1 (the version packaged by Ubuntu), used only to catch errors early
# in an environment without the official build. The reference for playing and for releases is the
# official Godot you installed on Windows. Headless = no rendering: it can never judge visuals.
#
# Usage:  tools/setup_godot_linux.sh [install_dir]     (default: ~/.cache/last-haven/godot)
#         export GODOT_BIN=<install_dir>/godot
#         python3 tools/check.py
set -euo pipefail

PREFIX="${1:-$HOME/.cache/last-haven/godot}"
WORK="$PREFIX/.apt"
ROOT="$PREFIX/root"
mkdir -p "$WORK/state/lists/partial" "$WORK/cache/archives/partial" "$ROOT"
: > "$WORK/status"
echo "deb http://archive.ubuntu.com/ubuntu questing main universe" > "$WORK/sources.list"

APT=(apt-get
  -o "Dir::Etc::sourcelist=$WORK/sources.list" -o "Dir::Etc::sourceparts=/dev/null"
  -o "Dir::State=$WORK/state" -o "Dir::State::status=$WORK/status"
  -o "Dir::Cache=$WORK/cache" -o "APT::Architecture=amd64" -o "Debug::NoLocking=1")

"${APT[@]}" update -qq
"${APT[@]}" install -d -y -qq --no-install-recommends godot

for deb in "$WORK"/cache/archives/*.deb; do
  case "$(basename "$deb")" in
    libc6_*|libc-bin_*) continue ;;   # keep the host C library
  esac
  dpkg-deb -x "$deb" "$ROOT"
done

cat > "$PREFIX/godot" <<EOF
#!/bin/sh
export LD_LIBRARY_PATH="$ROOT/usr/lib/x86_64-linux-gnu:$ROOT/lib/x86_64-linux-gnu:$ROOT/usr/lib:\${LD_LIBRARY_PATH:-}"
exec "$ROOT/usr/bin/godot" "\$@"
EOF
chmod +x "$PREFIX/godot"

echo "Installed: $("$PREFIX/godot" --headless --version)"
echo "Next: export GODOT_BIN=$PREFIX/godot"
