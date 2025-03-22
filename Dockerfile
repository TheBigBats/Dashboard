# Étape 1 : Construction avec Gradle
FROM gradle:7.6.1-jdk17 AS build
WORKDIR /app
COPY build.gradle settings.gradle ./
COPY gradlew gradlew.bat ./
COPY gradle ./gradle
COPY src ./src
RUN ./gradlew clean build -x test

# Étape 2 : Image finale avec OpenJDK
FROM openjdk:17-jdk-slim
WORKDIR /app
COPY --from=build /app/build/libs/*.jar app.jar
COPY src/main/resources/application.properties ./
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]

