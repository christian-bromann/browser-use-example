#!/usr/bin/env bash
#
# Baked once into the sandbox recipe snapshot: installs Node.js (if needed),
# Google Chrome and the WebdriverIO CLI so the agent can run `wdio session`
# right away.
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
SUDO=""
if [ "$(id -u)" -ne 0 ]; then SUDO="sudo"; fi

if [ "$(dpkg --print-architecture)" != "amd64" ]; then
  echo "Google Chrome for Linux is only published for amd64" >&2
  exit 1
fi

$SUDO apt-get update
# `unzip` is how WebdriverIO unpacks the chromedriver it downloads.
$SUDO apt-get install -y --no-install-recommends ca-certificates curl gnupg unzip xz-utils

# `wdio session` needs Node.js >= 22.19. Install Node 24 from nodejs.org when
# the template has none or an older one.
NODE_VERSION="v24.9.0"
node_ok() {
  command -v node >/dev/null 2>&1 &&
    node -e 'const [a,b]=process.versions.node.split(".").map(Number);process.exit(a>22||(a===22&&b>=19)?0:1)'
}
if ! node_ok; then
  tmp="$(mktemp -d)"
  tarball="node-${NODE_VERSION}-linux-x64.tar.xz"
  curl -fsSL -o "$tmp/$tarball" "https://nodejs.org/dist/${NODE_VERSION}/${tarball}"
  curl -fsSL -o "$tmp/SHASUMS256.txt" "https://nodejs.org/dist/${NODE_VERSION}/SHASUMS256.txt"
  (cd "$tmp" && grep " ${tarball}\$" SHASUMS256.txt | sha256sum -c -)
  $SUDO tar -xJf "$tmp/$tarball" -C /usr/local --strip-components=1
  rm -rf "$tmp"
  hash -r
fi

# Google Chrome from Google's signed apt repository. It pulls in every shared
# library Chrome needs; the fonts make pages render like a desktop browser.
curl -fsSL https://dl.google.com/linux/linux_signing_key.pub \
  | $SUDO gpg --dearmor --yes -o /usr/share/keyrings/google-chrome.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main" \
  | $SUDO tee /etc/apt/sources.list.d/google-chrome.list >/dev/null
$SUDO apt-get update
$SUDO apt-get install -y --no-install-recommends \
  google-chrome-stable fonts-liberation fonts-noto-color-emoji
$SUDO rm -rf /var/lib/apt/lists/*

# `wdio` runs @wdio/cli, which ships `wdio session`.
$SUDO env "PATH=$PATH" npm install -g wdio@10.0.2

# Open and close a session once: this checks the setup and caches the
# matching chromedriver in the snapshot.
wdio session open chrome about:blank --arg=--no-sandbox --arg=--disable-dev-shm-usage
wdio session close

echo "browser sandbox ready: node $(node --version), $(google-chrome --version), wdio $(wdio --version)"
