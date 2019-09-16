# AUTHOR: Phuong "grokkerzz" Nguyen
# DESCRIPTION: Airflow and Enbulk container
# BUILD: docker build --rm -t airflow_embulk .
# SOURCE: https://github.com/grokkerzz/airflow_embulk

FROM ubuntu:16.04
LABEL MAINTAINER phuong.nguyenhuucse@gmail.com

# Set ENV:
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
ENV JAVA_PATH=${JAVA_HOME}/bin:$JAVA_PATH
ENV WORK_DIR=/palmer/

# Install dependencies:
RUN apt-get -y update
RUN apt-get -y install openjdk-8-jdk libssl-dev openssl wget telnet git pigz \
    build-essential python3 python3-pip python3-dev libffi-dev libpq-dev

# Install Embulk
ENV EMBULK_VERSION 0.9.7
RUN wget "https://dl.embulk.org/embulk-latest.jar" -O /usr/bin/embulk && chmod +x /usr/bin/embulk

# Embulk puglins:
RUN embulk gem install embulk-input-mysql
RUN embulk gem install embulk-output-postgresql
RUN embulk gem install embulk-parser-csv_with_schema_file


COPY script/entrypoint.sh /entrypoint.sh
COPY config/airflow.cfg ${AIRFLOW_USER_HOME}/airflow.cfg

RUN chown -R airflow: ${AIRFLOW_USER_HOME}
RUN chmod +x /entrypoint.sh

EXPOSE 8080 5555 8793

# USER airflow
WORKDIR ${AIRFLOW_USER_HOME}
ENTRYPOINT ["/entrypoint.sh"]
CMD ["webserver"] # set default arg for entrypoint
