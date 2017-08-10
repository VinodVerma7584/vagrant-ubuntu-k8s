#!/usr/bin/env bash
kubectl -n kube-system delete deployment kubernetes-dashboard
kubectl -n kube-system delete service kubernetes-dashboard
kubectl create -f dashboard.yaml

