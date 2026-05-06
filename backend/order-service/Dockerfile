FROM eclipse-temurin:17-jre
WORKDIR /app
COPY target/order-service-0.1.0.jar app.jar
EXPOSE 8084
ENTRYPOINT ["java","-jar","/app/app.jar"]

