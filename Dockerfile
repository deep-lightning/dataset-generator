FROM ubuntu:16.04

WORKDIR /app

RUN apt-get update
RUN apt-get install -y imagemagick

RUN mkdir output
CMD ["bash", "render.sh", "input", "output"]