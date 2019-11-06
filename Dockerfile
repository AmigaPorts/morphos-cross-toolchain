FROM amigadev/docker-base:latest as build-env

WORKDIR /work

COPY ./ /work/

RUN ./toolchain-morphos && rm -rf /work/* 

FROM amigadev/docker-base:latest

COPY --from=build-env /opt/ppc-morphos /opt/ppc-morphos

RUN apt purge -y python-pip \
        genisoimage \
        rsync \
        wget \
        curl \
        git \
        make \
        automake \
        nano \
        autoconf \
        pkg-config \
        unzip \
        gawk \
        bison \
        flex\
        netpbm \
        cmake \
        gperf \
        gettext \
        texinfo\
        python \
        python-mako \
        g++ \
        gcc \
        gcc-multilib \
        g++-multilib \
        libtool \
        zlib1g-dev \
        zlib1g \
        libpng-dev \
        libx11-dev \
        libxcursor-dev \
        libgl1-mesa-dev \
        libgmpxx4ldbl \
        libgmp-dev \
        libmpfr6 \
        libmpfr-dev \
        libmpc3 \
        libmpc-dev \
        libncurses-dev \
        libswitch-perl \
        libasound2-dev \
        libc6:i386 \
        libstdc++6:i386 \
        libsdl1.2-dev ; \
    apt autoremove -y ; \
    rm -rf /var/lib/apt/lists/* ; \
    apt clean