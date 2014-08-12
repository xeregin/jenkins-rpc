FROM ubuntu:14.04
MAINTAINER Evan Callicoat <apsu@propter.net>

# Make apt quiet
ENV DEBIAN_FRONTEND noninteractive

# Update and grab curl and make sure we can apt over https
RUN apt-get update
RUN apt-get install -y curl apt-transport-https

# Jenkins repo and key -- per jenkins installation page
RUN echo deb http://pkg.jenkins-ci.org/debian binary/ > /etc/apt/sources.list.d/jenkins.list
RUN curl -s http://pkg.jenkins-ci.org/debian/jenkins-ci.org.key | apt-key add -

# Docker repo and key -- per docker installation page
RUN echo deb https://get.docker.io/ubuntu docker main > /etc/apt/sources.list.d/docker.list
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9

# Update again
RUN apt-get update

# Upgrade and install things
RUN apt-get upgrade -y
RUN apt-get install -y jenkins lxc-docker git ssh-client apparmor

# Wrapdocker wrapper and volume per https://github.com/jpetazzo/dind via CloudBees
ADD ./wrapdocker /usr/local/bin/wrapdocker
RUN chmod +x /usr/local/bin/wrapdocker
VOLUME /var/lib/docker

# Use volume for Jenkins home
ENV JENKINS_HOME /opt/jenkins
VOLUME /opt/jenkins

# Make sure we exec to pass on signals correctly
CMD wrapdocker && exec java -jar /usr/share/jenkins/jenkins.war
