#
#  Dockerfile for a GPDB SNE Sandbox Base Image
#

FROM gaos1/gpdb-docker
MAINTAINER sgao@pivotal.io

# install gptext
COPY gptext/* /tmp/

RUN yum update -y; yum install -y nc lsof \
    && tar zxf /tmp/greenplum-text-2.0.0-rhel5_x86_64.tar.gz -C /tmp/ \
    && rm /tmp/greenplum-text-2.0.0-rhel5_x86_64.tar.gz \
    && sed -i s/"more << EOLICENSE"/"cat << EOLICENSE"/g /tmp/greenplum-text-2.0.0-rhel5_x86_64.bin \
    && mkdir /usr/local/greenplum-text-2.0.0 \
    && chmod 755 /usr/local/greenplum-text-2.0.0 \
    && chown -R gpadmin:gpadmin /usr/local/greenplum-text-2.0.0 \
    && mkdir -p /data/primary \
    && chown -R gpadmin: /data/primary \
    && mkdir -p /data/master \
    && chown -R gpadmin: /data/master 
#RUN curl --insecure --junk-session-cookies --location --remote-name --silent --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u92-b14/jre-8u92-linux-x64.rpm
RUN yum localinstall -y /tmp/jre-8u92-linux-x64.rpm && \
    rm /tmp/jre-8u92-linux-x64.rpm && \
    yum clean all
ENV JAVA_HOME /usr/java/jre1.8.0_92/ \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8
RUN echo "export JAVA_HOME=/usr/java/jre1.8.0_92/" >> ~/.bashrc \
    && echo "export PATH=$JAVA_HOME/bin:$PATH" >> ~/.bashrc
RUN service sshd start; su gpadmin -l -c "/usr/local/bin/run.sh"; su gpadmin -l -c 'echo -e "yes\n\nyes\n\yes\n" | /tmp/greenplum-text-2.0.0-rhel5_x86_64.bin -c /tmp/gptext_install_config'
RUN rm /tmp/greenplum-text-2.0.0-rhel5_x86_64.bin

EXPOSE 5432 22 40000 40001

# VOLUMES CANNOT BE DEFINED IN BASE IMAGE IF CHANGES WILL BE MADE UP THE LINE
#VOLUME /gpdata
# Set the default command to run when starting the container

CMD echo "127.0.0.1 $(cat ~/orig_hostname)" >> /etc/hosts \
        && su gpadmin -l -c "/usr/local/bin/run.sh" \
        && su gpadmin -l -c "source /usr/local/greenplum-text-2.0.0/greenplum-text_path.sh; gptext-installsql gpadmin; gptext-start" \
        && /bin/bash
