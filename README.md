手游新服务器项目

GAMENAME		NODEID  	GAMEID
德州扑克		   1          10
南京麻将           2           1
苏州麻将		   3           2
芜湖麻将           4           4
合肥麻将		   5           3
二人麻将          12          12
兴化麻将           8           5
马鞍山麻将         7           6
斗地主             99          99   --- 数据库尚无 斗地主
镇江麻将           10          9
无锡麻将           6           8
泰州麻将           9           7
节点启动
docker run --rm -it -p 8001:8001 -p 8080:8080 -p 5000:5000 -p 8002:8002 -e NODETYPE=platform -e ConsulAddr=192.168.20.102:8500 -e publichost=192.168.26.32 -e groupid=zxdevel mgserver

游戏启动时的groupip就是节点的groupid

二人麻将启动
docker run --rm -it -p 18012:18012 -p 5012:5012 -e NODETYPE=MJGame/errenmj -e ConsulAddr=192.168.20.102:8500 -e publichost=192.168.26.32 -e groupid=zxdevel mgserver

南京麻将启动
docker run --rm -it -p 18001:18001 -p 5001:5001 -e NODETYPE=MJGame/nanjingmj -e ConsulAddr=192.168.20.102:8500 -e publichost=192.168.26.32 -e groupid=zxdevel mgserver

马安山麻将启动
docker run --rm -it -p 18006:18006 -p 5106:5106 -e NODETYPE=MJGame/maanshanmj -e ConsulAddr=192.168.20.102:8500 -e publichost=192.168.26.32 -e groupid=zxdevel mgserver