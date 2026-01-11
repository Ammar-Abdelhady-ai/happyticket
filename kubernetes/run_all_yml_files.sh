kubectl apply -f ./namespace/namespace.yml
kubectl config set-context --current --namespace=happyticket
kubectl apply -f . --recursive