MAP="luckyblock"
#MAP="bluetopia"

echo "remove $MAP map from PVC" ;
kubectl exec -it $(kubectl get pods -n minecraft | grep mine | awk '{print $1}') -n minecraft -- /bin/rm -rf /data/worlds/${MAP}; 


echo "copy $MAP to the minecraft pod $(kubectl get pods -n minecraft | grep mine | awk '{print $1}')."; 
kubectl cp ./${MAP} $(kubectl get pods -n minecraft | grep mine | awk '{print $1}'):/data/worlds -n minecraft;

echo "delete pod $(kubectl get pods -n minecraft | grep mine | awk '{print $1}') and restart."; 
kubectl delete pod $(kubectl get pods -n minecraft | grep mine | awk '{print $1}') -n minecraft
