kubectl exec -it $(kubectl get pods -n minecraft | grep mine | awk '{print $1}') -n minecraft -- /bin/rm -rf /data/worlds/$1
