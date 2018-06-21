#! /bin/sh
#docker build -t "dockerhub.ucop.io/mobile/mgserver-build:1.0.0" -f "Dockerfile-onbuild" .
#docker push dockerhub.ucop.io/mobile/mgserver-build:1.0.0
#有点脏的实现方式，需要在docker启动环境变量中加两个对外的端口 loginport=8002 gateport=18001 loginport是固定的 gateport根据不同的游戏不同
#这是因为我们的游戏的配置在数据库中，而nginx从外部动态配置只能是环境变量
#必须的环境变量 nodeid, NODETYPE,  如果是生产环境的话额外有个RUNENV=product环境变量 如果没有的话默认为开发环境
docker build -t "mgserver" .
echo "------------------------------------"
echo "run lobby server, nodeid must already registered in system"
echo "------------------------------------"
echo "docker run --rm -it -p 5100:5100 -p 8002:8002 -p 18001:8003 -e NODETYPE=lobby -e nodeid=2 mgserver"

echo "------------------------------------"
echo "run game server, nodeid must already registered in system"
echo "------------------------------------"
echo "docker run --rm -it -p 5102:5102 -p 18002:8003 -e NODETYPE=MJGame/suzhoumj -e nodeid=1 mgserver"
echo "docker run --rm -it -p 5101:5101 -p 18003:8003 -e NODETYPE=MJGame/nanjingmj -e nodeid=9 mgserver"
echo "docker run --rm -it -p 5103:5103 -p 18004:8003 -e NODETYPE=MJGame/wuhumj -e nodeid=16 mgserver"
echo "docker run --rm -it -p 5104:5104 -p 18005:8003 -e NODETYPE=MJGame/changshumj -e nodeid=17 mgserver"
echo "docker run --rm -it -p 5101:5101 -p 18001:8003 -e NODETYPE=MJGame/hongzhongmj -e nodeid=30 -e RUNENV=develop mgserver"
echo "docker run --rm -it -p 5101:5101 -p 18001:8003 -e NODETYPE=MJGame/wujiangmj -e nodeid=34 -e RUNENV=develop mgserver local test service."