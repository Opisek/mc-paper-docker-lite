FROM eclipse-temurin:25 AS build

WORKDIR /app

RUN apt-get update
RUN apt-get install -y bash curl gosu jq

COPY entrypoint.sh .
RUN chmod +x entrypoint.sh
ENTRYPOINT [ "bash", "entrypoint.sh" ]
