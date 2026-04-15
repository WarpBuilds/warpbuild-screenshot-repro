#!/usr/bin/env bash
# Single shared probe script. Both `warpbuild` and `github-hosted-control` jobs
# invoke this so the only variable is the runner that executes it.
set -euo pipefail

echo "=== sysctl ==="
sysctl -n hw.model hw.ncpu hw.memsize machdep.cpu.brand_string

echo "=== sw_vers ==="
sw_vers

echo "=== gui session ==="
launchctl print gui/$(id -u) 2>&1 | head -12 || echo "no gui session"

echo "=== WindowServer ==="
pgrep -l WindowServer || echo "no WindowServer process"

echo "=== display ==="
/usr/sbin/system_profiler SPDisplaysDataType 2>&1 | head -25 || true

echo "=== screencapture probe ==="
mkdir -p /tmp/probe
open -a TextEdit
sleep 4
pgrep -fl TextEdit || echo "TextEdit didn't start"
screencapture -x /tmp/probe/desktop.png
ls -la /tmp/probe/desktop.png

python3 -m pip install --quiet --break-system-packages Pillow 2>&1 | tail -3

python3 - <<'PY'
from PIL import Image
im = Image.open('/tmp/probe/desktop.png')
pixels = list(im.getdata())
mean = sum(sum(p[:3]) for p in pixels) / (len(pixels) * 3)
print(f'Mean pixel brightness: {mean:.2f}/255 (0=pure black, 255=white)')
print(f'Image size: {im.size}')
w, h = im.size
body = im.crop((0, 30, w, h))
bp = list(body.getdata())
bmean = sum(sum(p[:3]) for p in bp) / (len(bp) * 3)
print(f'Body region (excluding menu bar) mean brightness: {bmean:.2f}/255')
PY
