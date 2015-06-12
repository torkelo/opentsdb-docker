#Basic update/upgrade/setup and install packages needed in other sections at once to save on number of apt-get instantiations
FROM ubuntu
RUN if [ ! $(grep universe /etc/apt/sources.list) ]; then sed 's/main$/main universe/' -i /etc/apt/sources.list && apt-get update; fi
RUN DEBIAN_FRONTEND=noninteractive apt-get -y update
RUN DEBIAN_FRONTEND=noninteractive apt-get -y upgrade
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y curl build-essential git-core python python-dev openjdk-6-jdk supervisor openssh-server automake gnuplot unzip nginx-light
RUN mkdir -p /opt/sei-bin/

#Install HBase and scripts
RUN mkdir -p /data/hbase
RUN mkdir -p /root/.profile.d
WORKDIR /opt
ADD http://www.apache.org/dist/hbase/hbase-0.94.27/hbase-0.94.27.tar.gz /opt/downloads/
RUN tar xzvf /opt/downloads/hbase-*gz && rm /opt/downloads/hbase-*gz
RUN ["/bin/bash","-c","mv hbase-* /opt/hbase"]
ADD start_hbase.sh /opt/sei-bin/
ADD hbase-site.xml /opt/hbase/conf/
EXPOSE 60000
EXPOSE 60010
EXPOSE 60030

#Install OpenTSDB and scripts
RUN git clone -b master --single-branch git://github.com/OpenTSDB/opentsdb.git /opt/opentsdb

RUN cd /opt/opentsdb && bash ./build.sh
ADD start_opentsdb.sh /opt/sei-bin/
ADD create_tsdb_tables.sh /opt/sei-bin/
EXPOSE 4242

#Install SUpervisord
RUN mkdir -p /var/log/supervisor
ADD supervisor-hbase.conf /etc/supervisor/conf.d/hbase.conf
ADD supervisor-system.conf /etc/supervisor/conf.d/system.conf
ADD supervisor-tsdb.conf /etc/supervisor/conf.d/tsdb.conf

#Configure SSHD properly
ADD supervisor-sshd.conf /etc/supervisor/conf.d/sshd.conf
RUN mkdir -p /root/.ssh
RUN chmod 0600 /root/.ssh
RUN sed -ri 's/UsePAM yes/#UsePAM yes/g; s/#UsePAM no/UsePAM no/g;' /etc/ssh/sshd_config
RUN mkdir -p /var/run/sshd
RUN chown 0:0 /var/run/sshd
RUN chmod 0744 /var/run/sshd
ADD create_ssh_key.sh /opt/sei-bin/

#nginx
ADD	./nginx.conf /etc/nginx/nginx.conf

RUN mkdir -p /etc/opentsdb
ADD	./opentsdb.conf /etc/opentsdb/opentsdb.conf

VOLUME ["/data/hbase"]

CMD ["/usr/bin/supervisord"]

