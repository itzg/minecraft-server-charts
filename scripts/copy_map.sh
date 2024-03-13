kubectl cp ./"$1" $(kubectl get pods -n minecraft | grep mine | awk '{print $1}'):/data/worlds -n minecraft
