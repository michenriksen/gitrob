FROM ruby:2.2
MAINTAINER Shane Starcher <shanestarcher@gmail.com>

RUN \
	apt-get update && \
    apt-get install -y postgresql-server-dev-9.4 postgresql-client && \
    apt-get -y clean

RUN \
	wget https://github.com/jwilder/dockerize/releases/download/v0.0.3/dockerize-linux-amd64-v0.0.3.tar.gz &&\
	tar -C /usr/local/bin -xzvf dockerize-linux-amd64-v0.0.3.tar.gz

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app
COPY . /usr/src/app
RUN echo 'user accepted' > /usr/src/app/agreement

RUN bundle install

ENV DB_USERNAME postgres
ENV DB_PASSWORD ''
ENV DB_URL postgres
ENV DB_PORT 5432
ENV DB_DB postgres
ENV ACCESS_TOKEN ''
ENV ORG ''

EXPOSE 9393

ENTRYPOINT ["/bin/bash"]
CMD ["/usr/src/app/docker/start"]