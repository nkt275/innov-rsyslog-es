# innov-rsyslog-es

Innov-rsyslog-es is a nimble deployment of a small Elastic Stack micro-architecture on CentOS 7-1810 used to ingest syslog and other log data (e.g. network devices, windows event logs via winlogbeat). The deployment assumes an offline environment with no internet access and is designed to provide a quick-reponse log aggregation and analysis solution for engagements in small enclaves. Elastic Stack version is 7.1.1 and Nginx version is 1.16.0.

## Getting Started

The instructions that follow provide a guide on how to setup innov-rsyslog-es.

### Prerequisites

You will need:

* Ansible rpms
* Docker-ce rpms rolled into a tarball called 'docker-ce.tar'
* Docker-compose binary
* Container tarballs for elasticsearch, kibana, logstash, and nginx all rolled into a single tarball called 'images.tar'

### Installation

Install steps are:

Install Ansible

```
rpm -ivh /opt/rsyslog/build/ansible/*.rpm
```

Use Ansible to configure host

```
cd /opt/rsyslog

ansible-playbook -i /etc/ansible/hosts configure.yml
```

Install rsyslog+es components

```
./install.sh
```

## Author

* [nkt275](mailto:nkt275.germanium@gmail.com)

## Acknowledgments & Thanks

* To Roberto Rodriguez [@Cyb3rWard0g](https://twitter.com/Cyb3rWard0g) [@THE_HELK](https://twitter.com/THE_HELK) who provided the build recipe used in this repo. 
* To the [Security Onion](https://github.com/Security-Onion-Solutions) team who provided the load and extract formula.
