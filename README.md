# 0、拉取官方镜像

```bash
sudo docker pull pytorch/pytorch
```

> 有必要时设置好镜像源

# 1、修改容器的root密码

在Dockerfile里，第十行：`RUN echo "root:@设置密码" | chpasswd`

# 2、设置容器信息

- 在docker-compose.yml里，services里设置容器名
- 设置对外的端口号，这里是从.env中读取的，也可以直接设置
- 在volunms设置挂载的文件夹

> 可以设置多个不同的容器

# 3、启动容器

```bash
docker-compose up -d
```

# 4、ssh连接容器

```bash
ssh@root//@服务器ip:@步骤2里设置的端口号
```
