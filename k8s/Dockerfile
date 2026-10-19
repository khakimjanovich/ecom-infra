# One image per deployable: the Gradle-built jar on the plain JRE, run as a non-root user. The
# limits and JVM options come from the cluster (base/*.yaml), not from the image.
#   docker build -f k8s/Dockerfile -t ecom/app:dev ../ecom/app/build/libs --build-arg JAR=app.jar
FROM eclipse-temurin:25-jre
ARG JAR
COPY ${JAR} /opt/ecom/service.jar
USER 10001
ENTRYPOINT ["java", "-jar", "/opt/ecom/service.jar"]
