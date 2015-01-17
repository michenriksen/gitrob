#================#
#   BASIC INFO   #
#================#

FROM debian:wheezy
MAINTAINER aykit "code@aykit.org"


#=========================#
#   INSTALL DEPENDENCIES  #
#=========================#

RUN apt-get update && \
	apt-get -y install postgresql

RUN service postgresql start && \
	su - postgres -c "createuser -s gitrob" && \
	su - postgres -c "createdb -O gitrob gitrob"

USER postgres

COPY pg_hba.conf /etc/postgresql/9.1/main/
COPY postgresql.conf /etc/postgresql/9.1/main/


#=====================#
#   FUN WITH DOCKER   #
#=====================#

EXPOSE 5432

CMD ["/usr/lib/postgresql/9.1/bin/postgres", "-D", "/var/lib/postgresql/9.1/main", "-c", "config_file=/etc/postgresql/9.1/main/postgresql.conf"]
