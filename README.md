### 使用说明
0. 装机必备
   1. lsof             yum install ..
   2. config ssh
      ssh mac可能出现问题的一步就是ssh-agent or \~/.ssh/known_hosts中太多备选key了 会造成无尽permission denied

1. 架构
全部基于当前Dockerfile构建出来的镜像 没有任何启动语句
docker-compose基于原始镜像同时架起多个containers
因为ss-manager实现的限制 每个os当中只允许出现一个ss-manager 不然后出现的会被先前出现的夺权 所有的ss-server进程都会被删除然后重新根据新的ss-manager配置打开
缘此 docker-compose架起多个container实属一种妥协

当前策略是 单个容器当中可以通过一个ss-manager发起n个ss-server(这n个ss-server的配置参数一致)
         通过docker-compose一台机器可以起多个container 每个container当中所有的ss-server都一致

         所以一台物理机器 按照配置参数分类 能起无数个ss-server

2. 参数配置
注意避免使用 network_mode: host 一用就崩 目前没有查明原因
暂时通过端口mapping代替
使用之前将$PWD更换成ss配置文件所在文件夹 推荐把所有container的需要做卷映射的文件都放在host一个文职进行管理 文件映射必须添加只读 不然默认可读写

在ss配置文件当中第一项"server":[]
除非当前服务器支持ipv6不然绝不能加::0 不支持 强行加 镜像会直接卡死

做好端口映射文件映射之后 直接docker-compose up &

a. ports (需要跟对应的config.json一致)
b. image (基镜像 基本都是一样的)
c. volume(src路径 其实也都一样)

docker-compose: 镜像名必须完整 repo/image:tag

2. 未来构想
- 参数化
- 端口随机化 + 数据可视化
- optimize Dockerfile
- alpine 镜像内核性能优化
- ufw 镜像级防护 ubuntu                                                         [环境部署阶段check]
- ufw 镜像级防护 centos                                                         [环境部署阶段check]
- ufw 云防火墙
- 自动生成二维码
- 输入想要的配置文件个数 以及每个配置文件需要几个
- docker-composer同一镜像启动多个ss-server会造成无法输出日志的问题！！！！！！！！！     [solved需要在yml中加入 stdin_open: true; tty: true]
- 加一个二层vpn解决netflix/邮箱之类的问题
- yum + apt support



3. 当前进度
- ubuntu界面本地ufw端口级别ss防护一键部署       [check tested]
- ssh安全加固                               [check ]
- kernel更新                               [check ]
