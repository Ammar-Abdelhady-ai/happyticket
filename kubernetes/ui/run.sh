kubectl apply -f configmap.yml -n happyticket
kubectl apply -f secret.yml -n happyticket
kubectl apply -f deployment.yml -n happyticket
kubectl apply -f hpa.yml -n happyticket
kubectl apply -f service.yml -n happyticket
