#!/usr/bin/env bash
set -euo pipefail

# กำหนดรีโมตปลายทาง
REMOTE_URL="https://github.com/PawaritMangnimit/261.git"

# โฟลเดอร์โปรเจกต์ (ถ้าไม่ได้ส่งพาธมา จะใช้โฟลเดอร์ปัจจุบัน)
REPO_DIR="${1:-$(pwd)}"

echo "=> Using repo dir: $REPO_DIR"
cd "$REPO_DIR"

# ถ้ายังไม่ใช่ git repo ให้ init
if [ ! -d .git ]; then
  echo "=> Initializing git repo"
  git init
fi

# ให้ branch ปัจจุบันเป็น main
current_branch="$(git symbolic-ref --short HEAD 2>/dev/null || echo '')"
if [ -z "$current_branch" ]; then
  git checkout -B main
elif [ "$current_branch" != "main" ]; then
  git branch -M main
fi

# stage และ commit ถ้ามีไฟล์ค้างอยู่
git add -A
git commit -m "Initial push to origin main" || echo "=> Nothing to commit"

# ตั้งค่า remote origin
if git remote | grep -q '^origin$'; then
  git remote set-url origin "$REMOTE_URL"
else
  git remote add origin "$REMOTE_URL"
fi

# push ขึ้น origin main
git push -u origin main

echo "✅ Done: pushed to $REMOTE_URL (branch: main)"
