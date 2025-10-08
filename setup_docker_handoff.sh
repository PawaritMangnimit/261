#!/usr/bin/env bash
set -euo pipefail

echo "==> Create .env for DB & app flags"
cat > .env <<'E'
DB_USER=campus
DB_PASSWORD=campus123
DB_NAME=campusjobs

# เปิด/ปิด seeder (ตัวอย่างงาน) เมื่อรันผ่าน Docker
APP_SEED_ENABLED=false
E

echo "==> Write docker-compose.yml (profiles: dev, prod)"
cat > docker-compose.yml <<'YML'
services:
  db:
    image: postgres:15
    container_name: uni-jobs-portal-db-1
    environment:
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: ${DB_NAME}
    ports:
      - "5432:5432"
    volumes:
      - db_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER} -d ${DB_NAME}"]
      interval: 3s
      timeout: 2s
      retries: 20

  # โปรไฟล์ dev: ให้เพื่อนแก้ UI แล้วเห็นผลทันที
  app-dev:
    profiles: ["dev"]
    image: maven:3.9-eclipse-temurin-17
    working_dir: /workspace
    command: mvn -DskipTests spring-boot:run -Dspring-boot.run.profiles=dev
    ports:
      - "8080:8080"
    environment:
      SPRING_DATASOURCE_URL: jdbc:postgresql://db:5432/${DB_NAME}
      SPRING_DATASOURCE_USERNAME: ${DB_USER}
      SPRING_DATASOURCE_PASSWORD: ${DB_PASSWORD}
      APP_SEED_ENABLED: ${APP_SEED_ENABLED}
    depends_on:
      db:
        condition: service_healthy
    volumes:
      - .:/workspace
      - m2:/root/.m2

  # โปรไฟล์ prod: รันด้วย JAR ที่ build จาก Dockerfile
  app:
    profiles: ["prod"]
    build: .
    image: uni-jobs-portal-app:latest
    ports:
      - "8080:8080"
    environment:
      SPRING_DATASOURCE_URL: jdbc:postgresql://db:5432/${DB_NAME}
      SPRING_DATASOURCE_USERNAME: ${DB_USER}
      SPRING_DATASOURCE_PASSWORD: ${DB_PASSWORD}
      APP_SEED_ENABLED: ${APP_SEED_ENABLED}
    depends_on:
      db:
        condition: service_healthy

volumes:
  db_data:
  m2:
YML

echo "==> Write multi-stage Dockerfile (for prod)"
cat > Dockerfile <<'DF'
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /build
COPY . .
RUN mvn -q -DskipTests package

FROM eclipse-temurin:17-jre
WORKDIR /app
COPY --from=build /build/target/campusjobs-0.0.1-SNAPSHOT.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java","-jar","/app/app.jar"]
DF

echo "==> Ensure application-dev.properties (dev profile for docker dev)"
mkdir -p src/main/resources
cat > src/main/resources/application-dev.properties <<'P'
spring.application.name=campusjobs
spring.datasource.url=jdbc:postgresql://db:5432/${DB_NAME:campusjobs}
spring.datasource.username=${DB_USER:campus}
spring.datasource.password=${DB_PASSWORD:campus123}
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=true

# ช่วย dev UI
spring.thymeleaf.cache=false
spring.web.resources.cache.period=0

# ปิด security csrf บางส่วนถ้าจำเป็นต่อการทดสอบ form (คงค่าเดิมหากตั้งที่ SecurityConfig แล้ว)
# server.port=8080

# Seeder toggle via env (APP_SEED_ENABLED)
app.seed.enabled=${APP_SEED_ENABLED:false}
P

echo "==> Add devtools dependency if missing (for hot reload)"
if ! grep -q '<artifactId>spring-boot-devtools</artifactId>' pom.xml; then
  awk '1;/<\/dependencies>/{print "    <dependency>\n      <groupId>org.springframework.boot</groupId>\n      <artifactId>spring-boot-devtools</artifactId>\n      <scope>runtime</scope>\n      <optional>true</optional>\n    </dependency>"}' pom.xml > pom.xml.new
  mv pom.xml.new pom.xml
fi

echo "==> Create .dockerignore (speed up build context)"
cat > .dockerignore <<'D'
target
.git
.idea
.vscode
*.iml
node_modules
D

echo "✅ Done. Next:
- DEV  : docker compose --profile dev up
- PROD : docker compose --profile prod up --build -d
"
