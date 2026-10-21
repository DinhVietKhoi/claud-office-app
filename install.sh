#!/bin/sh
set -eu

REPO="DinhVietKhoi/claud-office-app"
PORT="${OFFICE_PORT:-4777}"

say() { printf '%s\n' "$*"; }
fail() {
  printf 'Lỗi: %s\n' "$*" >&2
  exit 1
}

command -v curl >/dev/null 2>&1 || fail "cần có curl"

case "$(uname -s)" in
  Darwin) platform=mac; ext=zip ;;
  Linux) platform=linux; ext=tar.gz ;;
  *) fail "hệ điều hành $(uname -s) chưa được hỗ trợ, trên Windows hãy dùng lệnh PowerShell" ;;
esac
case "$(uname -m)" in
  arm64 | aarch64) cpu=arm64 ;;
  x86_64 | amd64) cpu=x64 ;;
  *) fail "chip $(uname -m) chưa được hỗ trợ" ;;
esac
[ "$platform" = linux ] && [ "$cpu" != x64 ] && fail "bản Linux hiện chỉ có cho x64"

version="${CLAUDE_OFFICE_VERSION:-}"
if [ -z "$version" ]; then
  latest=$(curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/$REPO/releases/latest") || fail "không kết nối được GitHub"
  version="${latest##*/v}"
fi
case "$version" in
  [0-9]*.[0-9]*.[0-9]*) ;;
  *) fail "không tìm được bản phát hành mới nhất" ;;
esac

name="Claude-Office-$version-$platform-$cpu.$ext"
base="https://github.com/$REPO/releases/download/v$version"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT INT TERM

say "↓ Tải Claude Office v$version ($platform-$cpu)"
curl -fL --progress-bar -o "$work/$name" "$base/$name" || fail "tải $name không được"
expected=$(curl -fsSL "$base/$name.sha256" | awk '{print $1}')
if command -v sha256sum >/dev/null 2>&1; then
  actual=$(sha256sum "$work/$name" | awk '{print $1}')
else
  actual=$(shasum -a 256 "$work/$name" | awk '{print $1}')
fi
[ -n "$expected" ] && [ "$expected" = "$actual" ] || fail "file tải về không khớp checksum, hãy chạy lại lệnh"

if curl -fs -o /dev/null -m 2 -X POST -H 'X-Office: 1' "http://127.0.0.1:$PORT/api/shutdown"; then
  say "• Tắt Claude Office đang chạy (các phòng sẽ tự mở lại)"
  for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
    curl -fs -o /dev/null -m 1 "http://127.0.0.1:$PORT/style.css" || break
    sleep 0.5
  done
fi

mkdir -p "$work/out"
if [ "$platform" = mac ]; then
  ditto -x -k "$work/$name" "$work/out"
  target="${CLAUDE_OFFICE_DIR:-/Applications}"
  if ! mkdir -p "$target" 2>/dev/null || [ ! -w "$target" ]; then target="$HOME/Applications"; fi
  mkdir -p "$target"
  app="$target/Claude Office.app"
  rm -rf "$app"
  mv "$work/out/Claude Office.app" "$app"
  xattr -dr com.apple.quarantine "$app" 2>/dev/null || true
  say "✓ Đã cài vào $app"
  if [ -n "${CLAUDE_OFFICE_NO_OPEN:-}" ]; then
    "$app/Contents/Resources/node" "$app/Contents/Resources/app/bin/office.mjs" start
  else
    open "$app"
  fi
else
  tar -xzf "$work/$name" -C "$work/out"
  target="${CLAUDE_OFFICE_DIR:-$HOME/.local/opt}"
  mkdir -p "$target"
  dir="$target/claude-office"
  rm -rf "$dir"
  mv "$work/out/claude-office" "$dir"
  menu="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
  mkdir -p "$menu"
  cat > "$menu/claude-office.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Claude Office
Comment=Văn phòng pixel cho Claude Code
Exec="$dir/claude-office"
Icon=$dir/app/assets/icon.png
Terminal=false
Categories=Development;
EOF
  say "✓ Đã cài vào $dir, có lối tắt Claude Office trong menu ứng dụng"
  if [ -n "${CLAUDE_OFFICE_NO_OPEN:-}" ]; then
    "$dir/claude-office" start
  else
    "$dir/claude-office" open
  fi
fi

say "Lần đầu mở app, tick Kết nối Claude Code ở màn thiết lập để văn phòng thấy Claude đang làm gì."
