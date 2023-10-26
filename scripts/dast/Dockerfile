FROM openjdk:11-jre-slim
COPY todo/target/todo-0.0.1.jar /app.jar
ENV PORT=80
ENV SPRING_PROFILES_ACTIVE=local
ENV SPRING_DATASOURCE_SHOW_SQL=true


ENTRYPOINT ["java","-jar","/app.jar"]
