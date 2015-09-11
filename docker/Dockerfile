FROM debian:jessie

ENV PACKER_VERSION 0.8.6

RUN apt-get -y update ; apt-get install -y curl unzip ruby ruby-dev make g++ zlib1g-dev patch

RUN gem install rbvmomi

RUN mkdir /tmp/packer \
    && cd /tmp/packer \
    && curl -O -sS -L https://dl.bintray.com/mitchellh/packer/packer_${PACKER_VERSION}_linux_amd64.zip \
    && unzip packer_${PACKER_VERSION}_linux_amd64.zip \
    && rm packer_${PACKER_VERSION}_linux_amd64.zip \
    && strip -S packer* \
    && mv packer* /usr/local/bin \
    && rm -rf /var/cache/apk/* \
    && rm -rf /tmp/packer

CMD ["bash", "-c", "packer version"]
