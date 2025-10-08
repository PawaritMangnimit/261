#!/usr/bin/env bash
set -euo pipefail

# เติม spring-boot-starter-validation ถ้ายังไม่มี
if ! grep -q 'spring-boot-starter-validation' pom.xml; then
  perl -0777 -pe 's|</dependencies>|  <dependency>\n      <groupId>org.springframework.boot</groupId>\n      <artifactId>spring-boot-starter-validation</artifactId>\n    </dependency>\n  </dependencies>|' -i pom.xml
  echo "✅ Added spring-boot-starter-validation to pom.xml"
else
  echo "ℹ️  spring-boot-starter-validation already present"
fi

# ล้าง target เพื่อ build ใหม่สะอาด ๆ
rm -rf target || true
