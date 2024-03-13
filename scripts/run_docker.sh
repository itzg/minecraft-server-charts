sudo docker run -it -d --name=minecraft-phantom\
    --net=host\
    --restart=unless-stopped\
    -e SERVER=192.168.2.51:19132
    nrenes/phantom-linux-arm8:latest
