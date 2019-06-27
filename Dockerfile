FROM ubuntu:19.04

RUN dpkg --add-architecture i386 && apt-get update && apt-get install -y \
	autoconf \
	bison \
	flex \
	g++ \
	gcc \
	gcc-multilib \
	g++-multilib \
	gettext \
	git \
	lhasa \
	libgmpxx4ldbl \
	libgmp-dev \
	libmpfr6 \
	libmpfr-dev \
	libmpc3 \
	libmpc-dev \
	libncurses-dev \
	make \
	rsync \
	texinfo\
	wget \
	python \
	libc6:i386 \
	libstdc++6:i386

WORKDIR /work

COPY ./ /work/

RUN git config --global user.email "you@example.com" && \
	git config --global user.name "Your Name"

RUN ./toolchain-morphos 
