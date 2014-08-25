FROM ubuntu:14.04
MAINTAINER Evan Callicoat <apsu@propter.net>

# Make apt quiet
ENV DEBIAN_FRONTEND noninteractive

# Update, upgrade and install deps for RPC
RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y curl git python python-pip python-dev ssh-client

# Install ansible
RUN pip install ansible

# Add entrypoint script
ADD job.sh /root/job.sh

# Add ssh config
ADD ssh_config /root/.ssh/config

# Shell entry-point
CMD ["/root/job.sh"]
