#!/bin/bash

if ! [[ -f /etc/swift/account.ring.gz && -f /etc/swift/container.ring.gz && -f /etc/swift/object.ring.gz ]]; then
    echo "Ring files not present at /etc/swift. Checking for GLUSTER_VOLUMES env variable."
    if [ -z "$GLUSTER_VOLUMES" ]; then
	echo "You need to set GLUSTER_VOLUMES env variable OR bind mount /etc/swift containing ring files."
        exit 1
    else
        echo "GLUSTER_VOLUMES env variable is set. Exporting the following gluster volumes:"
	echo $GLUSTER_VOLUMES
        gluster-swift-gen-builders $GLUSTER_VOLUMES
    fi
else
    echo "Ring files found at /etc/swift. Using those."
fi

# TODO: Validate volume names present in ring files and compare them with
# those mountpoint directories present under /mnt/gluster-object.

# Let supervisord start swift services
echo "Starting gluster-swift services..."
/usr/bin/supervisord -c /etc/supervisor/supervisord.conf
