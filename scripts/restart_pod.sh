kubectl delete pod $(kubectl get pods -n minecraft | grep mine | awk '{print $1}') -n minecraft 
