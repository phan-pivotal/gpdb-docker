#
#  Dockerfile for a GPDB SNE Sandbox Base Image
#

FROM centos:6
MAINTAINER phan@pivotal.io forked from gaos1/gpdb-docker

## May be useful for gdb, not enabled yet.
#cap_add:
#    - SYS_PTRACE
#security_opt:
#    - apparmor:unconfined

ENV VERSION 5.9.0
ENV ZIP_FILE_NAME /tmp/greenplum-db-${VERSION}-rhel6-x86_64.zip
ENV BIN_FILE_NAME /tmp/greenplum-db-${VERSION}-rhel6-x86_64.bin

# For adding gpdb source code to the image. You may use "docker run -v ${gpdb_src_path}:/src" instead.
# ENV GPDB_SRC_FILENAME /tmp/gpdb.tar.gz
# && tar -xzf $GPDB_SRC_FILENAME \
# && rm $GPDB_SRC_FILENAME \
# /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7 

COPY * /tmp/
RUN echo root:password | chpasswd \
        && sed -i 's/enabled=0/enabled=1/g' /etc/yum.repos.d/CentOS-Debuginfo.repo \
        && rpm --import http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-6 && rpm --import http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-Testing-6 &&\
        && yum makecache \
        && yum update -y \
        && yum install -y centos-release-scl epel-release; \ 
        #For GP installation
        yum install -y unzip which tar more util-linux-ng passwd openssh-clients openssh-server ed m4 perl krb5-workstation krb5-libs libcgroup-tools; \
        #For GP Debug
        yum install -y yum-utils devtoolset-6-gdb devtoolset-6-gdb-gdbserver && debuginfo-install -y audit-libs libgcc nss-softokn-freebl pam zlib; \
        #yum install -y git readline-devel apr-devel libevent-devel libxml2-devel libyaml-devel bison flex expat-devel libcurl-devel libuuid-devel json-c-devel libicu cmake3 devtoolset-6-gcc devtoolset-6-gcc-c++ \
        #curl-devel bzip2-devel python-devel openssl-devel perl-ExtUtils-Embed bxml2-devel openldap-devel pam pam-devel perl-devel \
        #wget python27; #For GP Compile  \        
        yum clean all \     
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
        && /usr/sbin/groupadd -g 3030 gpadmin \
        && /usr/sbin/useradd gpadmin -u 3030 -g gpadmin -G wheel -m \
        && echo "password"|passwd --stdin gpadmin \
        && echo "gpadmin        ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers \
        && mv /tmp/bash_profile /home/gpadmin/.bash_profile \
        && chown -R gpadmin: /home/gpadmin \
        && mkdir -p /gpdata/master /gpdata/segments \
        && chown -R gpadmin: /gpdata \
        && chown -R gpadmin: /usr/local/green* \
        && service sshd start \
        && su gpadmin -l -c "source /usr/local/greenplum-db/greenplum_path.sh;gpssh-exkeys -f /tmp/gpdb-hosts"  \
        && su gpadmin -l -c "source /usr/local/greenplum-db/greenplum_path.sh;gpinitsystem -a -c  /tmp/gpinitsystem_singlenode -h /tmp/gpdb-hosts; exit 0 "\
        && su gpadmin -l -c "export MASTER_DATA_DIRECTORY=/gpdata/master/gpseg-1;source /usr/local/greenplum-db/greenplum_path.sh;psql -d template1 -c \"alter user gpadmin password 'password'\"; createdb gpadmin;  exit 0"

EXPOSE 5432 22 40000 40001

# VOLUMES CANNOT BE DEFINED IN BASE IMAGE IF CHANGES WILL BE MADE UP THE LINE
# VOLUME /gpdata
# Set the default command to run when starting the container

CMD echo "127.0.0.1 $(cat ~/orig_hostname)" >> /etc/hosts \
        && service sshd start \
#        && sysctl -p \
        && su gpadmin -l -c "/usr/local/bin/run.sh" \
        && /bin/bash