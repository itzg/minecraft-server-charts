helm install mc-router \
  --set replicaCount=1 \
  --set services.minecraft.type="LoadBalancer" \
  --set services.minecraft.port=19132 \
  --set minecraftRouter.connectionRateLimit=4 \
itzg/mc-router -n minecraft
