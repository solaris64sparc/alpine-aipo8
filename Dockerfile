FROM alpine:3.12.1

RUN echo "http://dl-cdn.alpinelinux.org/alpine/v3.12/community" >> /etc/apk/repositories
RUN apk update

RUN apk add --no-cache nmap lsof readline-dev zlib-dev lsof bison coreutils flex gcc libc-dev libedit-dev libxml2-dev libxslt-dev linux-headers llvm10-dev clang g++ make openssl-dev perl-utils  util-linux-dev zlib-dev icu-dev openjdk8-jre bash sudo curl

RUN wget -O - 'https://osdn.jp/frs/redir.php?f=/aipo/64847/aipo-8.1.1-linux-x64.tar.gz' | tar zxf -
RUN cd aipo-* && \
sed -i -e 's/useradd ${POSTGRES_USER} -g ${POSTGRES_USER}/adduser ${POSTGRES_USER} -G ${POSTGRES_USER} -D/' bin/postgresql.sh && \
sed -i -e 's/groupadd/addgroup/' bin/postgresql.sh && \
sed -i -e 's/userdel -r/deluser --remove-home/' bin/func.conf && \
sed -i -e 's|/usr/sbin/lsof|/usr/bin/lsof|' bin/validate.sh

RUN cd aipo-*/dist/ && wget https://archive.apache.org/dist/tomcat/tomcat-7/v7.0.106/bin/apache-tomcat-7.0.106.tar.gz
RUN cd aipo-*/dist/ && wget https://ftp.postgresql.org/pub/source/v9.3.25/postgresql-9.3.25.tar.gz
RUN cd aipo-*/dist/ && wget https://jdbc.postgresql.org/download/postgresql-9.3-1104.jdbc41.jar

RUN cd aipo-* && \
sed -i -e 's/apache-tomcat-7.0.68/apache-tomcat-7.0.106/' bin/install.conf && \
sed -i -e 's/SRC=postgresql-9.3.11/SRC=postgresql-9.3.25/' bin/install.conf && \
sed -i -e 's/postgresql-9.3.11$/postgresql-9.3.25/' bin/install.conf && \
sed -i -e 's/postgresql-9.3-1103.jdbc41.jar/postgresql-9.3-1104.jdbc41.jar/' bin/install.conf

RUN cd aipo-* && bash installer.sh /usr/local/aipo

RUN rm -rf /usr/local/aipo/jre  && \
cp -rp /usr/lib/jvm/java-1.8-openjdk/jre /usr/local/aipo/

RUN rm -rf aipo-*

RUN echo '#!/bin/sh' >> /usr/local/aipo/bin/aipo-wrapper.sh && \
echo 'DATA=//usr/local/aipo/postgres/data' >> /usr/local/aipo/bin/aipo-wrapper.sh && \
echo 'if [ -d "$DATA.new" ]; then' >> /usr/local/aipo/bin/aipo-wrapper.sh && \
echo '  if [ ! "$(ls -A $DATA)" ]; then' >> /usr/local/aipo/bin/aipo-wrapper.sh && \
echo '    cp -a "$DATA.new/." "$DATA/"' >> /usr/local/aipo/bin/aipo-wrapper.sh && \
echo '  fi' >> /usr/local/aipo/bin/aipo-wrapper.sh && \
echo '  rm -fr "$DATA.new"' >> /usr/local/aipo/bin/aipo-wrapper.sh && \
echo 'fi' >> /usr/local/aipo/bin/aipo-wrapper.sh && \
echo '/usr/local/aipo/bin/startup.sh' >> /usr/local/aipo/bin/aipo-wrapper.sh && \
echo 'tail -f /dev/null' >> /usr/local/aipo/bin/aipo-wrapper.sh

RUN chmod +x /usr/local/aipo/bin/aipo-wrapper.sh

RUN cp -a /usr/local/aipo/postgres/data /usr/local/aipo/postgres/data.new

RUN sed -i -e 's/lsof -i:${1}/netstat -natp | grep ${1} ; sleep 10/' /usr/local/aipo/bin/func.conf

EXPOSE 80
CMD /usr/local/aipo/bin/aipo-wrapper.sh
