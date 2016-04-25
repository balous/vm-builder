FROM debian:jessie

ENV PACKER_VERSION 0.8.6

ENV OVFTOOL_BUNDLE VMware-ovftool-4.1.0-2459827-lin.x86_64.bundle
ENV OVFTOOL_URL https://swarchive.samepage.in/vmware-ovftool/${OVFTOOL_BUNDLE}

RUN apt-get -y update ; apt-get install -y curl unzip ruby ruby-dev make g++ zlib1g-dev patch expect

RUN gem install rbvmomi

RUN mkdir /tmp/packer \
    && cd /tmp/packer \
    && curl -O -sS -L https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip \
    && unzip packer_${PACKER_VERSION}_linux_amd64.zip \
    && rm packer_${PACKER_VERSION}_linux_amd64.zip \
    && strip -S packer* \
    && mv packer* /usr/local/bin \
    && rm -rf /var/cache/apk/* \
    && rm -rf /tmp/packer

COPY ovftool.expect /tmp/ovftool.expect

RUN mkdir -p /tmp/ovftool \
    && cd /tmp/ovftool \
    && curl -O -sS -L "${OVFTOOL_URL}" \
    && chmod +x ./*.bundle \
    && /tmp/ovftool.expect \
    && rm -r /tmp/ovftool /tmp/ovftool.expect

CMD ["bash", "-c", "packer version; ovftool --version"]
