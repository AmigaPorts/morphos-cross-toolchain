FROM amigadev/docker-base:latest

WORKDIR /work

COPY ./ /work/

RUN ./toolchain-morphos 
