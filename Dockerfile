# Dockerfile
FROM ubuntu:24.04

# install dependencies
RUN apt update && apt install -y openssh-server openssh-client iproute2 net-tools tcpdump vim

# root pass (for demo)
RUN echo 'root:password' | chpasswd

# Create SSH folder
RUN mkdir /var/run/sshd

# allow root login for demo
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]
