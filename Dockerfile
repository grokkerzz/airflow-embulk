FROM ubuntu:18.04
LABEL MAINTAINER frank.tran <trananhcuong1991@gmail.com>

# Set ENV
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64
ENV PATH $JAVA_HOME/bin:$PATH
ENV REPO_FOLDER /usr/local/airflow
ENV PYTHONPATH "${PYTHONPATH}:${REPO_FOLDER}"
ENV EMBULK_VERSION 0.9.23
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV LC_CTYPE en_US.UTF-8
ENV LC_MESSAGES en_US.UTF-8
ENV GOOGLE_CLOUD_SUPPRESS_RUBY_WARNINGS True
ENV PYTHON_VERSION 3.7


# Install dependencies
RUN apt-get clean -yqq && apt-get remove -yqq
RUN apt-get update -yqq && apt-get upgrade -yqq
RUN apt-get -y install curl
# RUN apt-get -y install build-essential python3.7 && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.7 1 && apt-get remove python3-apt -yqq
RUN apt-get -yqq install software-properties-common
RUN apt-get -y install openjdk-8-jdk libssl-dev openssl wget telnet git pigz vim \
    python3-pip python3-apt python-dev python3-dev libffi-dev libpq-dev libxml2-dev libxslt1-dev zlib1g-dev \
    freetds-dev libkrb5-dev libsasl2-dev freetds-bin apt-utils curl rsync \
    netcat locales libmariadb-client-lgpl-dev apt-transport-https ca-certificates unixodbc-dev \
    && ln -s /usr/bin/mariadb_config /usr/bin/mysql_config \
    && sed -i 's/^# en_US.UTF-8 UTF-8$/en_US.UTF-8 UTF-8/g' /etc/locale.gen \
    && locale-gen \
    && update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 \
    && useradd -ms /bin/bash -d ${REPO_FOLDER} airflow
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
RUN apt-add-repository https://packages.microsoft.com/ubuntu/18.04/prod
RUN apt-get update -y
RUN ACCEPT_EULA=Y apt-get install -y msodbcsql17 mssql-tools 

# Install embulk
ENV TMPDIR=/root/jruby/tmp
ENV TMP=/root/jruby/tmp
ENV TEMP=/root/jruby/tmp
RUN mkdir -p /root/jruby/tmp && chmod o+t /root/jruby/tmp
RUN wget "https://dl.bintray.com/embulk/maven/embulk-${EMBULK_VERSION}.jar" -O /usr/bin/embulk && chmod +x /usr/bin/embulk
RUN embulk gem update --system
RUN embulk gem install bundler
SHELL ["/bin/bash", "-c"]

# Embulk addition package for plugin

RUN embulk gem install google-cloud-env -v 1.2.1 && embulk gem install google-cloud-core -v 1.3.0

# Embulk Input
RUN embulk gem install embulk-input-mysql \
                       embulk-input-postgresql \
                       embulk-input-s3 \
                       embulk-input-mongodb \
                       embulk-input-sftp \
                       embulk-input-command \
                       embulk-input-sqlserver \
                       embulk-input-google_spreadsheets \
                       embulk-input-oracle \
                       embulk-input-bigquery \
                       --source http://rubygems.org

# Embulk parser
RUN embulk gem install embulk-parser-csv_guessable \
                       embulk-parser-jsonpath \
                       embulk-parser-poi_excel \
                       --source http://rubygems.org

# Embulk output
RUN embulk gem install embulk-output-mysql \
                       embulk-output-postgresql \
                       embulk-output-s3 \
                       embulk-output-mongodb_nest \
                       embulk-output-redshift \
                       embulk-output-bigquery \
                       embulk-output-command \
                       embulk-output-sqlserver \
                       embulk-output-sftp \
                       embulk-output-oracle \
                       --source http://rubygems.org

# Install python env
COPY requirements.txt /tmp/requirements.txt
RUN python3 -m pip install --force-reinstall pip && python3 -m pip install --upgrade pip
RUN pip3 install --trusted-host pypi.org --trusted-host files.pythonhosted.org --default-timeout=100 --upgrade pip setuptools
RUN pip3 install --default-timeout=100 wheel pytz pyOpenSSL ndg-httpsclient pyasn1
RUN pip3 install --default-timeout=100 -r /tmp/requirements.txt --use-feature=2020-resolver && rm -rf /tmp/requirements.txt

# Install mongoexport
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 656408E390CFB1F5
RUN wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | apt-key add -
RUN echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu $(lsb_release -sc)/mongodb-org/4.2 multiverse" |  tee /etc/apt/sources.list.d/mongodb-org-4.2.list
RUN apt-get update -y
RUN apt-get install -y mongodb-org-tools=4.2.5



