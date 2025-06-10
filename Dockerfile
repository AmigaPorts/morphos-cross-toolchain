FROM amigadev/docker-base:latest as build-env
ARG BUILDDATE
WORKDIR /work

COPY . .

RUN mkdir -p /opt && \
	git clone --depth 1 https://github.com/NetBSD/pkgsrc /work/pkgsrc && \
	cd /work/pkgsrc/bootstrap && \
	./bootstrap --prefix /opt --make-jobs $(nproc) && \
	export PATH="/opt/sbin:/opt/bin:$PATH" && \
	cd /work/pkgsrc/cross/ppc-morphos-gcc-11 && \
	printf "ACCEPTABLE_LICENSES+= morphos-sdk-license\nACCEPTABLE_LICENSES+= lha-license\n" >> /opt/etc/mk.conf && \
	sed -e 's|\${PREFIX}/gg|\${PREFIX}/ppc-morphos|' -i /work/pkgsrc/cross/ppc-morphos-gcc-11/Makefile && \
	sed -e 's|gg/|ppc-morphos/|' -i /work/pkgsrc/cross/ppc-morphos-gcc-11/PLIST && \
	sed -e 's|\${PREFIX}/gg|\${PREFIX}/ppc-morphos|' -i /work/pkgsrc/cross/ppc-morphos-binutils/Makefile && \
	sed -e 's|gg/|ppc-morphos/|' -i /work/pkgsrc/cross/ppc-morphos-binutils/PLIST && \
	sed -e 's|\${PREFIX}/gg|\${PREFIX}/ppc-morphos|' -i /work/pkgsrc/cross/ppc-morphos-sdk/Makefile && \
	sed -e 's|gg/|ppc-morphos/|' -i /work/pkgsrc/cross/ppc-morphos-sdk/PLIST && \
	bmake MAKE_JOBS=$(nproc) install clean-depends clean && \
	ln -s /opt/ppc-morphos/bin/ppc-morphos-gcc-11 /opt/ppc-morphos/bin/ppc-morphos-gcc && \
	ln -s /opt/ppc-morphos/bin/ppc-morphos-g++-11 /opt/ppc-morphos/bin/ppc-morphos-g++ && \
	ln -s /opt/ppc-morphos/bin/ppc-morphos-c++-11 /opt/ppc-morphos/bin/ppc-morphos-c++ && \
	ln -s /opt/ppc-morphos/bin/ppc-morphos-cpp-11 /opt/ppc-morphos/bin/ppc-morphos-cpp && \
	ln -s /opt/ppc-morphos/bin/ppc-morphos-gcov-11 /opt/ppc-morphos/bin/ppc-morphos-gcov && \
	rm -rf /work/*

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
