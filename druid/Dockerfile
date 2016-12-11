FROM azul/zulu-openjdk:8

MAINTAINER mciz

RUN apt-get -y update && apt-get -y upgrade

RUN apt-get -y install build-essential

RUN apt-get -y update

ENV DRUID_VER 0.8.3

WORKDIR /druid

RUN curl -L "http://static.druid.io/artifacts/releases/druid-services-$DRUID_VER-bin.tar.gz" \
  | tar -xzvf - --strip=1


# Expose ports:
# - 8081: HTTP (coordinator)
# - 8082: HTTP (broker)
# - 8083: HTTP (historical)
# - 8083: HTTP (historical)


EXPOSE 8081
EXPOSE 8082
EXPOSE 8083

COPY entrypoint.sh /druid/entrypoint.sh

RUN chmod +x /druid/entrypoint.sh

ENTRYPOINT ["/druid/entrypoint.sh"]

#CMD export HOSTIP="$(resolveip -s $HOSTNAME)" && /etc/init.d/supervisord start
