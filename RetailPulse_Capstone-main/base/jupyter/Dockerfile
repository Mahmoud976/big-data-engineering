FROM fjardim/jupyter-spark

USER root

RUN sed -i \
        -e 's|deb.debian.org/debian|archive.debian.org/debian|g' \
        -e 's|security.debian.org/debian-security|archive.debian.org/debian-security|g' \
        -e 's|security.debian.org|archive.debian.org/debian-security|g' \
        -e '/stretch-updates/d' \
        /etc/apt/sources.list \
    && apt-get -o Acquire::Check-Valid-Until=false update \
    && apt-get -o APT::Get::Assume-Yes=true --allow-unauthenticated install -y --no-install-recommends \
        g++ libsasl2-dev libsasl2-modules \
    && rm -rf /var/lib/apt/lists/* \
    && /opt/anaconda3/bin/python3 -m pip install --no-cache-dir 'pip<22' 'setuptools<61' wheel \
    && /opt/anaconda3/bin/python3 -m pip install --no-cache-dir \
        PyHive==0.6.5 \
        thrift==0.13.0 \
        thrift-sasl==0.4.3 \
        pure-sasl==0.6.2 \
        sasl==0.3.1

