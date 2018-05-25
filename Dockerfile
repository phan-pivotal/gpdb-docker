#
#  Dockerfile for a GPDB SNE Sandbox Base Image
#

FROM centos:6
MAINTAINER phan@pivotal.io forked from gaos1/gpdb-docker

ENV VERSION 5.8.0
ENV ZIP_FILE_NAME /tmp/greenplum-db-${VERSION}-rhel6-x86_64.zip
ENV BIN_FILE_NAME /tmp/greenplum-db-${VERSION}-rhel6-x86_64.bin

COPY * /tmp/
RUN echo root:pivotal | chpasswd \
        && yum update -y \
        && yum install -y unzip which tar more util-linux-ng passwd openssh-clients openssh-server ed m4 perl; yum clean all \
        && unzip $ZIP_FILE_NAME -d /tmp/ \
        && rm $ZIP_FILE_NAME \
        && sed -i s/"more << EOF"/"cat << EOF"/g $BIN_FILE_NAME \
        && echo -e "yes\n\nyes\nyes\n" | $BIN_FILE_NAME \
        && rm $BIN_FILE_NAME \
        && cat /tmp/sysctl.conf.add >> /etc/sysctl.conf \
        && cat /tmp/limits.conf.add >> /etc/security/limits.conf \
        && rm -f /tmp/*.add \
        && echo "localhost" > /tmp/gpdb-hosts \
        && chmod 777 /tmp/gpinitsystem_singlenode \
        && hostname > ~/orig_hostname \
        && mv /tmp/run.sh /usr/local/bin/run.sh \
        && chmod +x /usr/local/bin/run.sh \
        && /usr/sbin/groupadd gpadmin \
        && /usr/sbin/useradd gpadmin -g gpadmin -G wheel \
        && echo "pivotal"|passwd --stdin gpadmin \
        && echo "gpadmin        ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers \
        && mv /tmp/bash_profile /home/gpadmin/.bash_profile \
        && chown -R gpadmin: /home/gpadmin \
        && mkdir -p /gpdata/master /gpdata/segments \
        && chown -R gpadmin: /gpdata \
        && chown -R gpadmin: /usr/local/green* \
        && service sshd start \
        && su gpadmin -l -c "source /usr/local/greenplum-db/greenplum_path.sh;gpssh-exkeys -f /tmp/gpdb-hosts"  \
        && su gpadmin -l -c "source /usr/local/greenplum-db/greenplum_path.sh;gpinitsystem -a -c  /tmp/gpinitsystem_singlenode -h /tmp/gpdb-hosts; exit 0 "\
        && su gpadmin -l -c "export MASTER_DATA_DIRECTORY=/gpdata/master/gpseg-1;source /usr/local/greenplum-db/greenplum_path.sh;psql -d template1 -c \"alter user gpadmin password 'pivotal'\"; createdb gpadmin;  exit 0"

EXPOSE 5432 22 40000 40001

# VOLUMES CANNOT BE DEFINED IN BASE IMAGE IF CHANGES WILL BE MADE UP THE LINE
#VOLUME /gpdata
# Set the default command to run when starting the container

CMD echo "127.0.0.1 $(cat ~/orig_hostname)" >> /etc/hosts \
        && service sshd start \
#        && sysctl -p \
        && su gpadmin -l -c "/usr/local/bin/run.sh" \
        && /bin/bash
