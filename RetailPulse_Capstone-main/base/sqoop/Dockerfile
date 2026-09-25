FROM fjardim/namenode_sqoop

ARG POSTGRESQL_JDBC_VERSION=42.7.5

ENV PATH=/usr/lib/sqoop/bin:${PATH}

RUN rm -f /usr/lib/sqoop/lib/postgresql-*.jar /usr/lib/sqoop/lib/postgresql-jdbc.jar \
    && curl --fail --location --retry 3 \
        --output /usr/lib/sqoop/lib/postgresql-${POSTGRESQL_JDBC_VERSION}.jar \
        https://jdbc.postgresql.org/download/postgresql-${POSTGRESQL_JDBC_VERSION}.jar \
    && mkdir -p /opt/sqoop-work \
    && curl --fail --location --retry 3 \
        --output /opt/sqoop-work/global-bundle.pem \
        https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem

WORKDIR /opt/sqoop-work