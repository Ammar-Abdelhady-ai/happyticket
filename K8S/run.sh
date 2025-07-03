#!/bin/bash

# namespace
kubectl apply -f ./namespace/namespace.yml

# change defoult namespace
kubectl config set-context --current --namespace=happyticket

# Create DataBase resources
kubectl apply -f ./db/pv.yml
kubectl apply -f ./db/pvc.yml
kubectl apply -f ./db/secret.yml
kubectl apply -f ./db/service.yml
kubectl apply -f ./db/statefulset.yml

#  Create API resources
kubectl apply -f ./api/api-appsettings.yml
kubectl apply -f ./api/api-config.yml
kubectl apply -f ./api/api-secret.yml
kubectl apply -f ./api/deployment.yml
kubectl apply -f ./api/service.yml
kubectl apply -f ./api/wwwroot-pv.yml
kubectl apply -f ./api/wwwroot-pvc.yml
kubectl apply -f ./api/hpa.yml

#  Create UI resources
kubectl apply -f ./ui/configmap.yml
kubectl apply -f ./ui/secret.yml
kubectl apply -f ./ui/service.yml
kubectl apply -f ./ui/deployment.yml
kubectl apply -f ./ui/hpa.yml

echo "All Kubernetes resources applied successfully!"
