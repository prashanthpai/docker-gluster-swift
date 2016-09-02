# docker-gluster-swift
Run gluster-swift inside a docker container.

# Building

As of now, you'll need to specify the names of volumes to be exported over
object interface during build time itself by editing `Dockerfile` and changing
arguments to `gluster-swift-gen-builders` command. This will be made dynamic
or configurable during runtime later.

```bash
# docker build --rm --tag prashanthpai/gluster-swift:dev .
```

## Running

On the host machine, mount one or more volumes under `/mnt/gluster-object`
directory. For example, if you have two volumes named `test` and `test2`, they
should be mounted at `/mnt/gluster-object/test` and `/mnt/gluster-object/test2`
respectively. This directory on the host machine containing all the individual
glusterfs mounts is then bind-mounted inside the container. This avoids having
to bind mount individual glusterfs volumes.

```bash
# docker run -d -p 8080:8080 -v /mnt/gluster-object:/mnt/gluster-object prashanthpai/gluster-swift:dev
```

**Note:**

~~~
-d : Runs the container in the background.
-p : Publishes the container's port to the host port. They need not be the same.
     If host port is omitted, a random port will be mapped. So you can run
     multiple instances of the container, each serving on a different port on
     the host machine.
-v : Bind mount a host path inside the container.
~~~

### Troubleshooting

**SELinux**

When a volume is bind mounted inside the container, you'll need blessings of
SELinux on the host machine. Otherwise, the application inside the container
won't be able to access the volume. Example:

```bash
[root@f24 ~]# docker exec -i -t nostalgic_goodall /bin/bash
[root@042abf4acc4d /]# ls /mnt/gluster-object/
ls: cannot open directory /mnt/gluster-object/: Permission denied
```

Ideally, running this command on host machine should work:

```bash
# chcon -Rt svirt_sandbox_file_t /mnt/gluster-object
```

However, glusterfs does not support setting of SELinux contexts [yet][1].
You can always set SELinux to permissive on host machine by running
`setenforce 0` or run container in privileged mode (`--privileged=true`).
I don't like either. A better workaround would be to mount the glusterfs
volumes on host machine as shown in following example:

[1]: https://bugzilla.redhat.com/show_bug.cgi?id=1252627

```bash
mount -t glusterfs -o selinux,context="system_u:object_r:svirt_sandbox_file_t:s0" `hostname`:test /mnt/gluster-object/test
```

**DNS**

This is more like a note to self for my VM environment. Make note of DNS
servers on the host machine listed at `/etc/resolv.conf`.

Edit `/usr/lib/systemd/system/docker.service` file and add those DNS servers
to the command invoking docker service. The docker service process when
invoked by systemd will look like this:

```bash
/usr/bin/docker daemon --exec-opt native.cgroupdriver=systemd --selinux-enabled --log-driver=journald --dns 10.75.5.25 --dns 10.68.5.26 --dns 10.38.5.26
```


### TODO

* Allow specifying list of volumes to be exported during run time.
* Allow bind mounting custom configuration files (including ring files)
  into `/etc/swift` inside the container, thus making it truly stateless.
