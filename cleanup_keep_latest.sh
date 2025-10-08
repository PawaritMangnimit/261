#!/usr/bin/env bash
set -euo pipefail

echo "==> Backup current project (src, pom.xml, resources) ..."
STAMP="$(date +%Y%m%d_%H%M%S)"
mkdir -p backups
tar -czf "backups/backup_${STAMP}.tar.gz" src pom.xml docker-compose.yml Dockerfile || true
echo "   backup at backups/backup_${STAMP}.tar.gz"

# Known stray/legacy files that previously caused conflicts
echo "==> Remove known stray Java files ..."
# Old HomeController in wrong package (caused bean name conflict before)
rm -f src/main/java/com/example/campusjobs/HomeController.java || true

# Any Java file that still references CSV export (we removed feature)
echo "==> Remove any Java files that still implement CSV export ..."
CSV_JAVA_FILES=$(grep -RIl --exclude-dir=target --include='*.java' 'approved\.csv\|buildCsv\(' src/main/java || true)
if [ -n "${CSV_JAVA_FILES}" ]; then
  echo "${CSV_JAVA_FILES}" | xargs -r rm -f
fi

# Sanitize templates: remove any leftover CSV links if any
echo "==> Sanitize templates (remove CSV links if left) ..."
for f in \
  src/main/resources/templates/teacher_jobs.html \
  src/main/resources/templates/teacher_applications.html \
  src/main/resources/templates/index.html \
  src/main/resources/templates/job_detail.html
do
  [ -f "$f" ] || continue
  sed -i.bak '/approved\.csv/d' "$f" || true
  rm -f "${f}.bak" || true
done

# Ensure only current controllers exist (allowlist)
echo "==> Keep only current controllers (allowlist) ..."
ALLOWED_CONTROLLERS=(
  src/main/java/com/example/campusjobs/controller/AuthController.java
  src/main/java/com/example/campusjobs/controller/HomeController.java
  src/main/java/com/example/campusjobs/controller/JobsController.java
  src/main/java/com/example/campusjobs/controller/TeacherJobController.java
  src/main/java/com/example/campusjobs/controller/StudentController.java
)
if [ -d src/main/java/com/example/campusjobs/controller ]; then
  find src/main/java/com/example/campusjobs/controller -type f -name '*.java' | while read -r f; do
    keep=false
    for k in "${ALLOWED_CONTROLLERS[@]}"; do
      [ "$f" = "$k" ] && keep=true && break
    done
    if [ "$keep" = false ]; then
      echo "   removing stale controller: $f"
      rm -f "$f"
    fi
  done
fi

# Ensure only current models exist (allowlist)
echo "==> Keep only current models (allowlist) ..."
ALLOWED_MODELS=(
  src/main/java/com/example/campusjobs/model/Job.java
  src/main/java/com/example/campusjobs/model/Application.java
  src/main/java/com/example/campusjobs/model/ApplicationStatus.java
)
if [ -d src/main/java/com/example/campusjobs/model ]; then
  find src/main/java/com/example/campusjobs/model -type f -name '*.java' | while read -r f; do
    keep=false
    for k in "${ALLOWED_MODELS[@]}"; do
      [ "$f" = "$k" ] && keep=true && break
    done
    if [ "$keep" = false ]; then
      echo "   removing stale model: $f"
      rm -f "$f"
    fi
  done
fi

# Ensure only current repos exist (allowlist)
echo "==> Keep only current repositories (allowlist) ..."
ALLOWED_REPOS=(
  src/main/java/com/example/campusjobs/repo/JobRepository.java
  src/main/java/com/example/campusjobs/repo/ApplicationRepository.java
)
if [ -d src/main/java/com/example/campusjobs/repo ]; then
  find src/main/java/com/example/campusjobs/repo -type f -name '*.java' | while read -r f; do
    keep=false
    for k in "${ALLOWED_REPOS[@]}"; do
      [ "$f" = "$k" ] && keep=true && break
    done
    if [ "$keep" = false ]; then
      echo "   removing stale repository: $f"
      rm -f "$f"
    fi
  done
fi

# Ensure only current configs/util exist (allowlist)
echo "==> Keep only current config/util (allowlist) ..."
ALLOWED_CONFIGS=(
  src/main/java/com/example/campusjobs/config/SecurityConfig.java
  src/main/java/com/example/campusjobs/config/DataSeeder.java
)
if [ -d src/main/java/com/example/campusjobs/config ]; then
  find src/main/java/com/example/campusjobs/config -type f -name '*.java' | while read -r f; do
    keep=false
    for k in "${ALLOWED_CONFIGS[@]}"; do
      [ "$f" = "$k" ] && keep=true && break
    done
    if [ "$keep" = false ]; then
      echo "   removing stale config: $f"
      rm -f "$f"
    fi
  done
fi

ALLOWED_UTILS=( src/main/java/com/example/campusjobs/util/SecUtil.java )
if [ -d src/main/java/com/example/campusjobs/util ]; then
  find src/main/java/com/example/campusjobs/util -type f -name '*.java' | while read -r f; do
    keep=false
    for k in "${ALLOWED_UTILS[@]}"; do
      [ "$f" = "$k" ] && keep=true && break
    done
    if [ "$keep" = false ]; then
      echo "   removing stale util: $f"
      rm -f "$f"
    fi
  done
fi

# Remove editor/OS junk files
echo "==> Remove editor/OS junk files ..."
find . -type f \( -name '*.orig' -o -name '*.rej' -o -name '*~' -o -name '._*' \) -delete || true

# Clean Maven target to ensure a fresh build
echo "==> Clean build outputs ..."
rm -rf target || true

# Quick sanity checks
echo "==> Sanity checks ..."
if grep -R "approved\.csv" -n src 2>/dev/null; then
  echo "   WARNING: found leftover CSV references"
else
  echo "   OK: no CSV references remain"
fi

if [ -f src/main/java/com/example/campusjobs/HomeController.java ]; then
  echo "   WARNING: stray HomeController in root package still exists"
else
  echo "   OK: no stray HomeController in root package"
fi

echo "✅ Cleanup done. Next step: docker compose up --build"
