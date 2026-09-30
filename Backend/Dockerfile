# syntax=docker/dockerfile:1

# ---- Build stage --------------------------------------------------------
FROM eclipse-temurin:21-jdk AS build
WORKDIR /app

# Cache Gradle downloads separately from the source tree so an app-code-only
# change doesn't re-download the world.
COPY gradlew settings.gradle.kts build.gradle.kts ./
COPY gradle ./gradle
RUN ./gradlew --no-daemon dependencies || true

COPY src ./src
RUN ./gradlew --no-daemon bootJar -x test

# ---- Runtime stage --------------------------------------------------------
FROM eclipse-temurin:21-jre
WORKDIR /app

RUN useradd --system --create-home --shell /usr/sbin/nologin camfix
COPY --from=build /app/build/libs/api.jar app.jar
USER camfix

EXPOSE 8081
ENTRYPOINT ["java", "-jar", "app.jar"]
