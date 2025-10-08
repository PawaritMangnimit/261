#!/usr/bin/env bash
set -euo pipefail

echo "=> Start minimalizing project (keep only essential files)"

# 1) ลบสคริปต์ช่วยเก่าๆ ที่ไม่จำเป็นต่อการรัน
rm -f \
  init_campus_jobs_portal.sh \
  add_security_config.sh \
  upgrade_jobs_apply_workflow.sh \
  quick_reset_java_ascii.sh \
  purge_jobs_and_applications.sh \
  setup_docker_handoff.sh \
  git_remote_push_main.sh \
  run_local.sh \
  run_dev.sh \
  run_prod.sh \
  *.bak *.orig *.tmp 2>/dev/null || true

# 2) ลบไฟล์ env จริง (ถ้าเผลอ commit มา) แต่คง .env.example
git rm --cached .env 2>/dev/null || true
rm -f .env 2>/dev/null || true

# 3) ทำความสะอาด artifact ที่ไม่ควรอยู่ใน repo
rm -rf target node_modules .mvn .idea .vscode 2>/dev/null || true

# 4) เขียน .gitignore / .dockerignore ให้ปลอดภัย (กันเผลออัพของส่วนตัว)
cat > .gitignore <<'GIT'
# Build
target/
*.log

# IDE/OS
.idea/
.vscode/
.DS_Store

# Node
**/node_modules/

# Docker & local env
db_data/
.env
.env.*
!.env.example
docker-compose.override.yml
GIT

cat > .dockerignore <<'D'
target
.git
.idea
.vscode
*.iml
node_modules
D

# 5) ยืนยันไฟล์สำคัญยังอยู่ครบ (ถ้าบางไฟล์ไม่มี จะไม่ fail)
mkdir -p src/main/resources
touch src/main/resources/application.properties
touch src/main/resources/application-dev.properties

echo "=> Minimalize done."
echo "   Keep files:"
echo "   - pom.xml, Dockerfile, docker-compose.yml, .gitignore, .dockerignore, .env.example"
echo "   - src/main/java/**  src/main/resources/** (templates/static/properties)"
