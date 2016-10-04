FROM centos:7
MAINTAINER Prashanth Pai <ppai@redhat.com>

# centos-release-openstack-kilo package resides in the extras repo.
# All subsequent actual packages come from the CentOS Cloud SIG repo:
# http://mirror.centos.org/centos/7/cloud/x86_64/

# epel-release is needed to install supervisor.
# Traditionally a docker container runs a single process when it is launched.
# When you want to run more than one process in a container, you can use an
# external process management tool such as the supervisor (supervisord.org)

# Install PACO servers and S3 middleware.
# Install supervisor
# Install gluster-swift dependencies. To be removed when RPMs become available.
# Clean downloaded packages and index

RUN yum --setopt=tsflags=nodocs -y update && \
    yum --setopt=tsflags=nodocs -y install \
        centos-release-openstack-kilo \
        epel-release && \
    yum --setopt=tsflags=nodocs -y install \
        openstack-swift openstack-swift-{proxy,account,container,object,plugin-swift3} \
        supervisor \
        git memcached python-prettytable && \
    yum -y clean all

# Install gluster-swift from source.
# TODO: When gluster-swift is shipped as RPM, just use that.
RUN git clone git://review.gluster.org/gluster-swift /tmp/gluster-swift && \
    cd /tmp/gluster-swift && \
    python setup.py install && \
    cd -

# Gluster volumes will be mounted *under* this directory.
VOLUME /mnt/gluster-object

# Configure supervisord
RUN mkdir -p /etc/supervisor /var/log/supervisor
COPY supervisord.conf /etc/supervisor/supervisord.conf

# If any of the processes run by supervisord dies, kill supervisord
# as well, thus terminating the container.
COPY supervisor_suicide.py /usr/local/bin/supervisor_suicide.py
RUN chmod +x /usr/local/bin/supervisor_suicide.py

# Copy script. This will check and generate ring files and will invoke
# supervisord which starts the required gluster-swift services.
COPY swift-start.sh /usr/local/bin/swift-start.sh
RUN chmod +x /usr/local/bin/swift-start.sh

# Replace openstack swift conf files with local gluster-swift ones
COPY etc/swift/* /etc/swift/

# The proxy server listens on port 8080
EXPOSE 8080

CMD /usr/local/bin/swift-start.sh
