# 构建pytorch多卡训练Docker镜像

以下以cuda12.4为例，其他cuda版本的操作类似。

## 0.进入 `cuda124`的路径下

```bash
cd pytorch-in-docker/cuda124
```

## 1.下载cuda镜像

查看cuda版本

```
nvidia-smi
```

在[nvidia/cuda - Docker Image | Docker Hub](https://hub.docker.com/r/nvidia/cuda)中，根据cuda版本，选择cuda镜像，以cuda=12.4，ubuntu=22.04为例：

```
docker pull nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04
```

## 2.编辑Dockerfile

> 这一步将在cuda镜像的基础上，安装ssh服务（用于远程连接），安装conda（用于python版本管理）

需要做的事：

- 修改FROM的 `镜像名:标签`
- 修改root的 `初始密码`。

```
# 上一步下载的cuda镜像
FROM nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04 

# 安装 OpenSSH 服务
RUN apt-get update && apt-get install -y openssh-server

# 创建 SSH 目录
RUN mkdir /var/run/sshd

# 设置 root 初始密码
RUN echo "root:defaultpwd" | chpasswd

# 允许 root 登录和密码认证
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config

# 暴露 22 端口
EXPOSE 22

RUN mkdir -p ~/miniconda3
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3/miniconda.sh
RUN bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3
RUN rm ~/miniconda3/miniconda.sh

# 激活conda
# RUN /opt/conda/bin/conda init
RUN ~/miniconda3/bin/conda init


# 启动 SSH 服务
CMD ["/usr/sbin/sshd", "-D"]
```

## 3.根据Dockerfile构建镜像

```
docker build -t conda-with-cuda124:v2024.10.15 .
```

> 注意：这里的镜像名、标签可以自己定义，但需要和下一步的docker-compose.yml中的镜像名对应。

## 4.编辑docker-compose.yml

需要修改的地方：

- 挂载目录
- ssh端口，这里用的是12126，注意防火墙里要开放这个端口
- 容器里可以使用的显卡数量

可以修改的地方：

- 容器名字
- 共享内存大小
- 网络模式
- 其他端口映射

```yaml
version: '3.8'

services:
  cuda124:
    image: conda-with-cuda124:v2024.10.15  # 替换为实际的镜像名称，这里使用的是上一步中构建的镜像
    container_name: py310.2024.10.15 # 容器名字
    restart: always # 自动重启
    shm_size: '48G' # 共享内存大小，如果设置太小，显卡之间将无法通信
    # network_mode: none # 网络模式，设置为none，则容器内的网络不受外部影响
    volumes: # 设置挂载目录，格式为：- 宿主机目录src:容器目录dst
      - $src:$dst
    ports: # 端口映射，格式为：- 宿主机端口:容器端口
      - 12126:22 # ssh 端口映射，这里的12126可以自己定义，后面根据这个端口连接容器
    deploy:
      resources:
        reservations:
          devices:
            - capabilities: [gpu]
              driver: nvidia
              count: 10  # 使用的 GPU 数量，根据实际情况调整
```

## 5.使用docker-compose创建容器

```bash
docker-compose up -d
```

## 6.连接容器

```bash
ssh root@localhost -p 12126
```

> 注意：
>
> - 这里的端口号需要和docker-compose.yml中设置的端口号一致。
> - root密码为：defaultpwd，可以修改为自己喜欢的密码。
> - 连接成功后，可以输入 `nvidia-smi`查看显卡信息。
> - localhost是宿主机的地址，如果在其他机器上，需要修改为实际的IP地址。

## 7.安装pytorch

### 7.1 创建conda环境

```bash
conda create -n py310 python=3.10
```

### 7.2 安装pytorch

```bash
conda activate py310
pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124
```

### 7.3 检查cuda是否可以用

```bash
python -c "import torch; print(torch.cuda.is_available()); print(torch.cuda.device_count())"
```

## 8.保存容器到镜像

```bash
docker commit py310.2024.10.15 py310-cuda124:v2024.10.15
```

> docker commit @CONTAINER_NAME @IMAGE_NAME:TAG
>
> - @CONTAINER_NAME: 容器名,对应docker-compose.yml中的container_name，可以用docker ps查看
> - @IMAGE_NAME: 镜像名
> - :TAG: 镜像标签，可以自己定义

## 9.保存镜像到本地
```bash
docker save -o py310-cuda124.tar py310-cuda124:v2024.10.15
```

## 10.导入镜像到其他机器
```bash
docker load -i py310-cuda124.tar
```