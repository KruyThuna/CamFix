FROM eclipse-temurin:21-jre
WORKDIR /app

RUN useradd --system --create-home --shell /usr/sbin/nologin camfix
COPY build/libs/api.jar app.jar
USER camfix

EXPOSE 8081
ENTRYPOINT ["java", "-jar", "app.jar"]
