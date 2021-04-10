[Intro]
docker image: blacklist_sqlite 仅有一个sqlite的alphine镜像 唯一的作用就是更新blacklist.db的内容 进行云安防

镜像需要做两个文件映射 一个是blacklist.sql 一个是blacklist.db
其中.sql是预写好的 在已经存在名为blacklist.db的数据库 初始脚本就会直接导入 不会发生冲突
blacklist.db是已经存在的历史记录 不会冲突

!!!假如整个集群是新建立 一定不要放置blacklist.db文件 不然镜像启动回无法创建数据库

[Structure]
当前文件夹下需要的材料
1. blacklist.db                     [sqlite3数据库]
2. blacklist.sql                    [sqlite3数据库dump]
3. Dockerfile                       [docker file to build sqlite3]
4. log_monitor.py                   [ip monitor]
5. scripts/docker-entrypoint.sh     [docker container entry script]

构建镜像时 3 & 5必须在同一目录下
执行镜像时 1 & 2 & 4 必须在同一目录下

[Dockerfile_sqlite]
构建名字为blacklist_sqlite的镜像
docker build -t blacklist_sqlite .

[Docker args]
-idt
-v $PWD/blacklist.sql:/etc/sqlite/docker_sqlite_db/blacklist.sql
   $PWD/blacklist.db:/etc/sqlite/docker_sqlite_db/blacklist.db
-n blacklist_sqlite
--rm

[docker-entrypoint.sh]
作为当前container 1号进程启动 启动时务必detach mode因为是1号进程 如果不detach就会停在没有输出的状态
因为/bash/sh是作为2号进程进入的container

trap了信号SIGTERM SIGINT SIGKILL触发cleanup机制
写回并更新blacklist.db到blacklist.sql
之后退出

[Starting Script]
sqlite3 blacklist.db < blacklist.sql 导入                     // 写成entrypoint
sqlite3 blacklist.db .dump > blacklist.sql 导出               // 写成hooker
