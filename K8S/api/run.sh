kubectl apply -f wwwroot-pv.yml
kubectl apply -f wwwroot-pvc.yml

kubectl apply -f api-appsettings.yml
kubectl apply -f api-config.yml
kubectl apply -f api-secret.yml

kubectl apply -f deployment.yml
kubectl apply -f service.yml
kubectl apply -f hpa.yml