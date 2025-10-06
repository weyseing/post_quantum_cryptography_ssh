FROM ubuntu:22.04

RUN apt-get update && apt-get install -y openssh-server

# copy sshd config (PQC KexAlgorithms enabled)
COPY sshd_config /etc/ssh/sshd_config

RUN mkdir /var/run/sshd
EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]
