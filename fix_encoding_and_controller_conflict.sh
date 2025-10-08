#!/usr/bin/env bash
set -euo pipefail

echo "==> 1) ลบ HomeController ตัวเก่าที่ชนชื่อกับตัวใหม่"
rm -f src/main/java/com/example/campusjobs/HomeController.java || true

echo "==> 2) ตั้งค่า Maven ให้ใช้ UTF-8 (แก้ unmappable character)"
# ถ้ามี properties อยู่แล้ว จะเติม encoding ให้; ถ้าไม่มีก็แทรกให้
if ! grep -q "<project.build.sourceEncoding>" pom.xml; then
  # แทรกเข้าไปในส่วน <properties> หรือสร้างใหม่ถ้าไม่มี
  if grep -q "<properties>" pom.xml; then
    perl -0777 -pe 's|<properties>|<properties>\n    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>\n    <project.reporting.outputEncoding>UTF-8</project.reporting.outputEncoding>|' -i pom.xml
  else
    perl -0777 -pe 's|</parent>|</parent>\n\n  <properties>\n    <java.version>17</java.version>\n    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>\n    <project.reporting.outputEncoding>UTF-8</project.reporting.outputEncoding>\n  </properties>|' -i pom.xml
  fi
fi

# เพิ่ม maven-compiler-plugin (encoding UTF-8) ถ้ายังไม่มี
if ! grep -q "<artifactId>maven-compiler-plugin</artifactId>" pom.xml; then
  perl -0777 -pe 's|</plugins>|  <plugin>\n        <groupId>org.apache.maven.plugins</groupId>\n        <artifactId>maven-compiler-plugin</artifactId>\n        <version>3.11.0</version>\n        <configuration>\n          <source>17</source>\n          <target>17</target>\n          <encoding>UTF-8</encoding>\n        </configuration>\n      </plugin>\n    </plugins>|' -i pom.xml
fi

echo "==> 3) เคลียร์ target ให้ build ใหม่หมด"
rm -rf target || true

echo "==> 4) เสร็จแล้ว ลอง build/run ด้วย Docker Compose ได้เลย"
echo "คำสั่งต่อไปที่ให้รัน: docker compose up --build"
