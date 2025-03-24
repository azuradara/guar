# guar

A self-hosted &amp; containerized github-actions runner using the [Sysbox](https://github.com/nestybox/sysbox) container runtime.

Sysbox provides stronger isolation among GHA runner instances and between runners and the host. It also allows the execution of Docker binaries (and plugins) within a container without resorting to privileged containers, meaning it can be used to host multiple GHA runners within the same machine.

> [!WARNING]
> Do not use self-hosted runners on public repositories.
> Forks of a public repo can potentially execute dangerous code on your machine by creating a PR that triggers an action.

## Installation

Download the latest Sysbox package from the [Sysbox releases](https://github.com/nestybox/sysbox/releases) page:

```shell
wget https://downloads.nestybox.com/sysbox/releases/v0.6.6/sysbox-ce_0.6.6-0.linux_amd64.deb
```

If Docker is running on the host, stop and remove all containers as follows:

```shell
docker rm $(docker ps -a -q) -f
```

Install the Sysbox package and follow the installer instructions, `jq` is needed by the installer:

```shell
sudo apt-get install jq
sudo apt-get install ./sysbox-ce_0.6.6-0.linux_amd64.deb
```

Verify that Sysbox's Systemd units have been properly installed, and associated daemons are properly running:

```shell
$ systemctl status sysbox -n20
● sysbox.service - Sysbox container runtime
     Loaded: loaded (/lib/systemd/system/sysbox.service; enabled; vendor preset: enabled)
     Active: active (running) since Sun 2024-11-17 18:44:48 UTC; 16min ago
       Docs: https://github.com/nestybox/sysbox
   Main PID: 2949 (sh)
      Tasks: 2 (limit: 4613)
     Memory: 356.0K
        CPU: 24ms
     CGroup: /system.slice/sysbox.service
             ├─2949 /bin/sh -c "/usr/bin/sysbox-runc --version && /usr/bin/sysbox-mgr --version && /usr/bin/sysbox-fs --version && /bin/sleep infinity"
             └─2968 /bin/sleep infinity

Nov 17 18:44:48 testing.lon3.youcancorp.com systemd[1]: Started Sysbox container runtime.
Nov 17 18:44:48 testing.lon3.youcancorp.com sh[2950]: sysbox-runc
Nov 17 18:44:48 testing.lon3.youcancorp.com sh[2950]:         edition:         Community Edition (CE)
Nov 17 18:44:48 testing.lon3.youcancorp.com sh[2950]:         version:         0.6.5
Nov 17 18:44:48 testing.lon3.youcancorp.com sh[2950]:         commit:         1b440ff266841f3d2d296e664122a9e29ceb9fd8
Nov 17 18:44:48 testing.lon3.youcancorp.com sh[2950]:         built at:         Sat Nov  9 06:09:34 UTC 2024
Nov 17 18:44:48 testing.lon3.youcancorp.com sh[2950]:         built by:         Rodny Molina
Nov 17 18:44:48 testing.lon3.youcancorp.com sh[2950]:         oci-specs:         1.1.0+dev
Nov 17 18:44:48 testing.lon3.youcancorp.com sh[2957]: sysbox-mgr
Nov 17 18:44:48 testing.lon3.youcancorp.com sh[2957]:         edition:         Community Edition (CE)
Nov 17 18:44:48 testing.lon3.youcancorp.com sh[2957]:         version:         0.6.5
Nov 17 18:44:48 testing.lon3.youcancorp.com sh[2957]:         commit:         1159d228eac8402efa63bd2cb18cdf9e404ea130
Nov 17 18:44:48 testing.lon3.youcancorp.com sh[2957]:         built at:         Sat Nov  9 06:10:05 UTC 2024
Nov 17 18:44:48 testing.lon3.youcancorp.com sh[2957]:         built by:         Rodny Molina
Nov 17 18:44:48 testing.lon3.youcancorp.com sh[2963]: sysbox-fs
Nov 17 18:44:48 testing.lon3.youcancorp.com sh[2963]:         edition:         Community Edition (CE)
Nov 17 18:44:48 testing.lon3.youcancorp.com sh[2963]:         version:         0.6.5
Nov 17 18:44:48 testing.lon3.youcancorp.com sh[2963]:         commit:         aeba775e52cc6385fa4807c594fc7ee164ad624c
Nov 17 18:44:48 testing.lon3.youcancorp.com sh[2963]:         built at:         Sat Nov  9 06:10:01 UTC 2024
Nov 17 18:44:48 testing.lon3.youcancorp.com sh[2963]:         built by:         Rodny Molina
```

Grab a Github runner token by following the steps in this [guide](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/adding-self-hosted-runners#adding-a-self-hosted-runner-to-a-repository), and then clone this repo and execute the `guar.sh` script with the following params:

```shell
./guar.sh <runner-name> <org> <repo-name> <runner_token>
```

Have fun
