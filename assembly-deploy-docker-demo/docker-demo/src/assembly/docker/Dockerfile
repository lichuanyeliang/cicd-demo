# Dockerfile for spring-boot demo
# 1. ./scripts/build.sh
# 2. Build with: mvn docker:build
# 3. Run with: docker run --name docker-demo -itd -p 8081:8081 sunyard/docker-demo:0.0.1-SNAPSHOT
FROM openjdk8:sunyard
MAINTAINER shunl.li <shunl.li@sunyard.com>

ARG SERVICE_NAME_ARG
ARG SERVICE_FULL_NAME_ARG

WORKDIR /app/service

ENV RUN_MODE "Docker"
# 服务名称：如docker-demo
ENV SERVICE_NAME_DOCKER=${SERVICE_NAME_ARG}
# 服务全称：如docker-demo-0.0.1-SNAPSHOT
ENV SERVICE_FULL_NAME_DOCKER=${SERVICE_FULL_NAME_ARG}
ENV SERVER_PORT 8080

#RUN echo "http://mirrors.aliyun.com/alpine/v3.8/main" > /etc/apk/repositories \
#    && echo "http://mirrors.aliyun.com/alpine/v3.8/community" >> /etc/apk/repositories \
#    && apk update upgrade \
#    && apk add --no-cache procps unzip curl bash tzdata \
#    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
#    && echo "Asia/Shanghai" > /etc/timezone

COPY target/${SERVICE_FULL_NAME_ARG}.jar lib/${SERVICE_FULL_NAME_ARG}.jar
COPY src/assembly/bin/ bin/
COPY src/main/resources/ config/

RUN chmod +x bin/startup.sh \
    && chmod +x lib/${SERVICE_FULL_NAME_JAR_ARG} \
    && chmod 644 config/log4j2.xml

EXPOSE 8000-8100
CMD ["/app/service/bin/startup.sh"]