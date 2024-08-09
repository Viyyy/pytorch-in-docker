FROM pytorch/pytorch

# 安装 OpenSSH 服务
RUN apt-get update && apt-get install -y openssh-server

# 创建 SSH 目录
RUN mkdir /var/run/sshd

# 设置 root 密码
RUN echo "root:@设置密码" | chpasswd

# 允许 root 登录和密码认证
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config

# 暴露 22 端口
EXPOSE 22

# 激活conda
RUN /opt/conda/bin/conda init

# 启动 SSH 服务
CMD ["/usr/sbin/sshd", "-D"]