FROM apache/airflow:master-python3.7-ci-slim
USER root

ENV EMBULK_VERSION 0.9.7

# Install Java 7
RUN apt-get install software-properties-common \
    && add-apt-repository "deb http://ppa.launchpad.net/webupd8team/java/ubuntu xenial main" \
    && apt-get install oracle-java8-installer

# Install Embulk
RUN apk --update add --virtual build-dependencies \
    curl \
    && mkdir /embulk \
    && curl -o  /embulk/embulk -L "https://dl.bintray.com/embulk/maven/embulk-$EMBULK_VERSION.jar" \
    && chmod +x /embulk/embulk \
    && apk del build-dependencies
# Install libc6-compat for Embulk Plugins to use JNI
# cf : https://github.com/jruby/jruby/wiki/JRuby-on-Alpine-Linux
RUN apk --update add libc6-compat

# Define commonly used JAVA_HOME variable
ENV JAVA_HOME /usr/lib/jvm/java-7-oracle
