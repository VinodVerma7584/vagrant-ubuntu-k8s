#!/usr/bin/env bash
ssh  -p 2222 -i .vagrant/machines/k8s1/virtualbox/private_key ubuntu@localhost -L 8001:127.0.0.1:8001
