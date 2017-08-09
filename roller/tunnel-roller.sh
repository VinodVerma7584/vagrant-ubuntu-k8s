#!/usr/bin/env bash
ssh  -p 2222 -i ../.vagrant/machines/k8s1/virtualbox/private_key ubuntu@localhost -L 8080:10.99.18.238:8080

