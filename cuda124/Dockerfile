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
