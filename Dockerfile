FROM ubuntu:16.04

WORKDIR /app

RUN apt-get update

RUN mkdir output
CMD ["bash", "docker_script.sh"]

