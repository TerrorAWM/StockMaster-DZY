FROM eclipse-temurin:17-jre
WORKDIR /app
COPY target/eureka-service-0.1.0.jar app.jar
EXPOSE 8761
ENTRYPOINT ["java","-jar","/app/app.jar"]

