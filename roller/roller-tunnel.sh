#!/usr/bin/env bash
export ROLLER_IP=10.98.159.91
ssh  -p 2222 -i ../.vagrant/machines/k8s1/virtualbox/private_key ubuntu@localhost -L 8080:$ROLLER_IP:8080

