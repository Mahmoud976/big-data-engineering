FROM flink:1.20.3-scala_2.12-java17

USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends python3 python3-pip python3-dev gcc g++ \
    && python3 -m pip install --no-cache-dir apache-flink==1.20.3 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN ln -s /usr/bin/python3 /usr/local/bin/python

ENV PYFLINK_CLIENT_EXECUTABLE=/usr/bin/python3 \
    PYFLINK_PYTHON=/usr/bin/python3

USER flink
