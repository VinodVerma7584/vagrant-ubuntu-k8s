# How to deploy Roller on Kubernetes

This directory contains scripts and YAML files needed to Roller and
MySQL to the Kubernetes cluster that is created by this repo.

This README explains what I did to get Roller running in Kubernetes.

## Checkout 'roller' branch of vagrant-k8s-ubuntu

This repo is a fork of David Bainbridge's k8s-playground repo. This
'roller' directory is ony found in the 'roller' branch of this fork.

    https://github.com/davidkbainbridge/k8s-playground

To get started, you should clone this repo and checkout the 'roller'
branch, like so:

    $ git clone https://github.com/snoopdave/vagrant-ubuntu-k8s.git
    $ cd vagrant-ubuntu-k8s
    $ git checkout roller

## Start vagrant-k8s-ubuntu

Follow the instructions in the README.md in the directory above this
one to start a Vagrant-based three-node Kubernetes cluster. Once the
cluster has started, you can move on with the rest of the instructions
below.

## Install NFS server on node k8s1

The Kubernetes cluster you started has three Nodes, of which one is a
Controller and two are Worker Nodes available for running Pods. We'll
only be running one instance of MySQL and one instance of Roller, but we
don't know on which worker nodes MySQL and Roller will run. So we need
to use NFS to make sure that the MySQL and Roller data directories
are available on both workers.

Install NFS server software on the Controller Node, k8s1. First, shell
into the controller:

    $ vagrant ssh k8s1

Then on that machine install NFS:

    $ sudo apt-get update
    $ sudo apt-get install nfs-kernel-server

Create a directory that will be exported by NFS, name it `/var/nfs`:

    $ sudo mkdir /var/nfs

Then edit (or create) an `/etc/exports` file to export your NFS drive to
the worker Nodes. Ensure the file contains these lines:

    /var/nfs                    172.42.42.1(rw,sync,no_subtree_check) \
		        172.42.42.2(rw,sync,no_subtree_check) \
		        172.42.42.3(rw,sync,no_subtree_check)

You don't need to setup the NFS client software on the Worker Nodes
because Kubernetes has built-in support for NFS. But you might want to
do so just so you can test and see if you have NFS setup right.

I used this article to help me get NFS up and running and it explains
how to setup both NFS server and client software:
[How to setup an NFS mount on Ubuntu](https://www.digitalocean.com/community/tutorials/how-to-set-up-an-nfs-mount-on-ubuntu-14-04)

## Setup Kubectl

Before you can use the Kubernetes command line tool, you need to set it
up by running `kubectl-config.sh` on one of the three nodes of the
cluster. For example, login to k8s2:

    $ vagrant ssh k8s2

And run the config:

    $ cd /vagrant/roller
    $ ./kubectl-config.sh

## Deploy and setup MySQL

The YAML file
[https://github.com/snoopdave/vagrant-ubuntu-k8s/blob/roller/roller/mysql.yaml](mysql.yaml)
defines a Kubernetes Deployment for MySQL which deploys MariaDB
(a workalike fork of MySQL) and mounts the NFS drive we created above
as `/var/lib/mysql` -- where MySQL stores its data.

You can deploy MySQL by using the following command:

    kubectl create -f mysql.yaml

Once MySQL is deployed, you should be able to see it running as a
service:

    $ kubectl get services | grep mysql
    mysql-app    10.104.25.245   <none>        3306/TCP   22h

If you login to k8s1, you should be able to see the MySQL data present
in the NFS drive:

    $ vagrant ssh k8s1
    ubuntu@k8s1:~$ ls /var/nfs
    aria_log.00000001  ib_buffer_pool  ib_logfile0  ibtmp1             mysql
    aria_log_control   ibdata1         ib_logfile1  multi-master.info  performance_schema  tc.log

Next, you need to login to MySQL and create the *rollerdb* database for
Roller. First you need to find the machine where MySQL is running.
Login to k8s2 and k8s3 and try this command:

    $ docker ps | grep mysql

 If you see output like this then you have found MySQL:

    6bec2e610f91        0ff2b852d8bf                               "docker-entrypoint.sh"   22 hours ago        Up 22 hours                             k8s_mysql_mysql-dep-3604430423-rzglm_default_20c57c44-7d00-11e7-ba68-021f970fe273_0
    a3cd1062e6fd        gcr.io/google_containers/pause-amd64:3.0   "/pause"                 22 hours ago        Up 22 hours                             k8s_POD_mysql-dep-3604430423-rzglm_default_20c57c44-7d00-11e7-ba68-021f970fe273_0

Shell into the MySQL container and create the Roller database:

    ubuntu@k8s3:/vagrant/roller$ docker exec -it 6bec2e610f91 bash
    I have no name!@mysql-dep-3604430423-rzglm:/$ mysql -u root -p
    Enter password:
    Welcome to the MariaDB monitor.  Commands end with ; or \g.
    Your MariaDB connection id is 35
    Server version: 10.2.7-MariaDB-10.2.7+maria~jessie mariadb.org binary distribution

    Copyright (c) 2000, 2017, Oracle, MariaDB Corporation Ab and others.

    Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

    MariaDB [(none)]>

These are the commands to create the database:

    create database rollerdb;
    grant all on rollerdb.* to scott@'%' identified by 'tiger';
    grant all on rollerdb.* to scott@localhost identified by 'tiger';

## Deploy Roller

The YAML file
[https://github.com/snoopdave/vagrant-ubuntu-k8s/blob/roller/roller/roller.yaml](roller.yaml)
defines a Kubernetes Deployment for Roller based on the Docker image
docker-roller [https://github.com/snoopdave/roller-docker](roller-docker)

You can deploy it like so:

    kubectl create -f mysql.yaml

Once Roller is deploy, you should be able to see it running as a service:

    ubuntu@k8s2:/vagrant/roller$ kubectl get services | grep roller
    roller       10.98.159.91    <none>        8080/TCP   20h

Make a note of that IP address, you'll need it in the next step.

## Use SSL tunnel to access the Roller web UI

To access Roller, you can use an SSL tunnel. The following ssh command
must be exectued from within the `roller` directory (because of the
relative path to the key):

    ssh  -p 2222 -i ../.vagrant/machines/k8s1/virtualbox/private_key ubuntu@localhost -L 8080:$ROLLER_IP:8080

Once you've done that you should be able to access Roller at http://localhost:8080
and complete the Roller setup.
