# basic
FROM debian:latest

ENV TERM xterm
WORKDIR /

# RUN echo " \
# deb http://ftp.cn.debian.org/debian/ $(. /etc/os-release && echo ${VERSION_CODENAME}) main \
# deb http://ftp.cn.debian.org/debian/ $(. /etc/os-release && echo ${VERSION_CODENAME})-updates main \
# deb http://ftp.cn.debian.org/debian-security/ $(. /etc/os-release && echo ${VERSION_CODENAME})/updates main \
# " > /etc/apt/sources.list

RUN apt-get update && apt-get install -y --no-install-recommends \
        curl \
        htop \
        less \
        nano \
        procps \
        telnet \
        vim-tiny \
        make \
    && rm -rf /var/lib/apt/lists/*
    
# compile skynet
WORKDIR /server
COPY skynet skynet
RUN BUILD_DEP=" \
        autoconf \
        libreadline-dev \
        libssl-dev \
        libtool \
        make \
        git \
    " \
    && apt-get update && apt-get install -y --no-install-recommends ${BUILD_DEP} \
    && cd skynet && make -j4 linux TLS_MODULE=ltls \
    && make --assume-old=clean cleanall \
    && rm -rf /var/lib/apt/lists/*

# compile custom luaclib
# COPY luaclib luaclib
# RUN BUILD_DEP=" \
#         g++ \
#         libtool \
#         libzip-dev \
#         make \
#     " \
#     && apt-get update && apt-get install -y --no-install-recommends ${BUILD_DEP} \
#         librdkafka-dev \
#         libxml2-dev \
#     && ln -s /usr/include/libxml2/libxml /usr/include/libxml \
#     && cd luaclib && make -j4 linux \
#     && apt-get purge --autoremove -y ${BUILD_DEP} \
#     && rm -rf /var/lib/apt/lists/*

# install dev tools
RUN apt-get update && apt-get install -y --no-install-recommends \
        gdb \
    && rm -rf /var/lib/apt/lists/*

# copy other files
COPY . .

# setup entry point
EXPOSE 8000 8024
