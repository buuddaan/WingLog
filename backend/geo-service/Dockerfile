FROM eclipse-temurin:25-jdk AS build
WORKDIR /build

RUN apt-get update && apt-get install -y wget && \
    wget -q https://archive.apache.org/dist/maven/maven-3/3.9.6/binaries/apache-maven-3.9.6-bin.tar.gz && \
    tar xzf apache-maven-3.9.6-bin.tar.gz -C /opt && \
    ln -s /opt/apache-maven-3.9.6/bin/mvn /usr/local/bin/mvn && \
    rm apache-maven-3.9.6-bin.tar.gz

COPY pom-geo.xml pom.xml
COPY shared/ ./shared/
COPY geo-service/ ./geo-service/

RUN mvn -pl shared install -DskipTests
RUN mvn -pl geo-service package spring-boot:repackage -DskipTests

FROM eclipse-temurin:25-jre
WORKDIR /app
COPY --from=build /build/geo-service/target/*SNAPSHOT.jar app.jar
EXPOSE 8085
ENTRYPOINT ["java", "-jar", "app.jar"]