FROM alpine:3.12.1

ENV TIMEZONE Asia/Tokyo

RUN echo "http://dl-cdn.alpinelinux.org/alpine/v3.12/community" >> /etc/apk/repositories
RUN apk update && apk upgrade

RUN apk add --no-cache nmap lsof readline-dev zlib-dev lsof bison coreutils flex gcc libc-dev libedit-dev libxml2-dev libxslt-dev linux-headers llvm10-dev clang g++ make openssl-dev perl-utils  util-linux-dev zlib-dev icu-dev openjdk8-jre bash sudo

RUN wget -O - 'https://osdn.jp/frs/redir.php?f=/aipo/64847/aipo-8.1.1-linux-x64.tar.gz' | tar zxf -
RUN cd aipo-* && \
sed -i -e 's/useradd ${POSTGRES_USER} -g ${POSTGRES_USER}/adduser ${POSTGRES_USER} -G ${POSTGRES_USER} -D/' bin/postgresql.sh && \
sed -i -e 's/groupadd/addgroup/' bin/postgresql.sh && \
sed -i -e 's/userdel -r/deluser --remove-home/' bin/func.conf && \
sed -i -e 's|/usr/sbin/lsof|/usr/bin/lsof|' bin/validate.sh

RUN cd aipo-* && bash installer.sh /usr/local/aipo

RUN mv /usr/local/aipo/jre /usr/local/aipo/jre_old && \
cp -rp /usr/lib/jvm/java-1.8-openjdk/jre /usr/local/aipo/


RUN echo '''#!/bin/sh \
/usr/local/aipo/bin/startup.sh \
tail -f /dev/null ''' > /usr/local/aipo/aipo-wrapper.sh



EXPOSE 80
CMD /usr/local/aipo/bin/aipo-wrapper.sh
