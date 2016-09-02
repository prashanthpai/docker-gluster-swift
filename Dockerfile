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

# Configure supervisor
RUN mkdir -p /etc/supervisor /var/log/supervisor
COPY supervisord.conf /etc/supervisor/supervisord.conf

# Install gluster-swift from source.
# TODO: When gluster-swift is shipped as RPM, just use that.
RUN git clone git://review.gluster.org/gluster-swift /tmp/gluster-swift && \
    cd /tmp/gluster-swift && \
    python setup.py install && \
    cd -

# Replace openstack swift conf files with local gluster-swift ones
COPY etc/swift/* /etc/swift/

# Prepare ring files. This will "export listed volumes over object interface"
# TODO: Make providing this list of volume names dynamic i.e during run time.
RUN mkdir -p /mnt/gluster-object && gluster-swift-gen-builders test test2

# Gluster volumes will be mounted under this directory
VOLUME /mnt/gluster-object

# The proxy server listens on port 8080
EXPOSE 8080

# Let supervisord start swift services
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
