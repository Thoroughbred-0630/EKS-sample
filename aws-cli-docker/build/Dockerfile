FROM ubuntu:20.04

ARG User
ARG Access_key
ARG Secret_access_key

ENV USER=${User}
ENV ACCESS_KEY=${Access_key}
ENV SECRET_ACCESS_KEY=${Secret_access_key} 

RUN apt update && apt upgrade -y && apt install -y locales && \
    localedef -f UTF-8 -i ja_JP ja_JP.UTF-8

ENV LANG ja_JP.UTF_8
ENV LANGUAGE ja_JP:ja
ENV LC_ALL ja_JP.UTF-8
ENV TZ JST-9

RUN useradd -m ${User}
RUN apt-get install -y apt-utils git bash-completion curl 
RUN apt-get install -y nano openssl
RUN apt-get install -y wget zip
RUN apt-get install -y lsof sudo
RUN gpasswd -a ${User} sudo
RUN groupadd wheel
RUN gpasswd -a ${User} wheel
RUN gpasswd -a root wheel


USER root
RUN echo '%wheel    ALL=(ALL)   NOPASSWD:ALL' >> /etc/sudoers
RUN echo 'Defaults timestamp_timeout = 0' >> /etc/sudoers

#setup ubuntu
ENV DOCKER_CLIENT_VERSION=20.10.17
ENV DOCKER_API_VERSION=1.41
RUN curl -fsSL https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_CLIENT_VERSION}.tgz \
  | tar -xzC /usr/local/bin --strip=1 docker/docker


# If you do not need PASSWORD, please comment out below lines ---->
RUN echo -n 'export LINE=`sudo cat /etc/shadow | grep ' >> /home/${User}/.bashrc
RUN echo -n "${User}" >> /home/${User}/.bashrc
RUN echo '`' >> /home/${User}/.bashrc
RUN echo 'if [ ` echo \$LINE  | grep "!" ` ]; then' >> /home/${User}/.bashrc
RUN echo 'echo "register password..."' >>/home/${User}/.bashrc
RUN echo 'while :; do' >> /home/${User}/.bashrc
RUN echo "sudo passwd ${User}" >> /home/${User}/.bashrc
RUN echo 'if [ $? -eq 0 ];then' >> /home/${User}/.bashrc
RUN echo '  sudo sed -i -e "s/%wheel    ALL=(ALL)   NOPASSWD:ALL/#%wheel    ALL=(ALL)   NOPASSWD:ALL/" /etc/sudoers' >> /home/${User}/.bashrc
RUN echo '  break' >> /home/${User}/.bashrc
RUN echo 'echo "Retry... "' >> /home/${User}/.bashrc
RUN echo 'fi' >> /home/${User}/.bashrc
RUN echo 'done' >> /home/${User}/.bashrc
RUN echo 'fi' >> /home/${User}/.bashrc
# --------->   to this point

RUN echo -n 'export PATH=/home/' >> /home/${User}/.bashrc
RUN echo -n ${User} >> /home/${User}/.bashrc
RUN echo '/.local/bin:"$PATH"' >> /home/${User}/.bashrc

USER ${User}
WORKDIR /home/${User}
#setup aws cli
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN unzip awscliv2.zip
RUN sudo ./aws/install
RUN rm -R ./aws
RUN rm -R awscliv2.zip

#setup aws cli config
RUN mkdir /home/${User}/.aws
RUN echo '[admin]' >> /home/${User}/.aws/credentials
RUN echo -n 'aws_access_key_id=' >> /home/${User}/.aws/credentials
RUN echo  ${ACCESS_KEY} >> /home/${User}/.aws/credentials
RUN echo -n aws_secret_access_key= >> /home/${User}/.aws/credentials
RUN echo  ${SECRET_ACCESS_KEY} >> /home/${User}/.aws/credentials

RUN echo '[profile admin]' >> /home/${User}/.aws/config
RUN echo 'region=ap-northeast-1' >> /home/${User}/.aws/config
RUN echo 'output=json' >> /home/${User}/.aws/config

RUN echo  'export AWS_DEFAULT_PROFILE=admin' >> /home/${User}/.bashrc

RUN chmod 440 /home/${User}/.aws/config
RUN chmod 440 /home/${User}/.aws/credentials

#setup kubectl
RUN curl -o kubectl https://s3.us-west-2.amazonaws.com/amazon-eks/1.23.7/2022-06-29/bin/linux/amd64/kubectl
RUN curl -o kubectl.sha256 https://s3.us-west-2.amazonaws.com/amazon-eks/1.23.7/2022-06-29/bin/linux/amd64/kubectl.sha256
RUN openssl sha1 -sha256 kubectl
RUN chmod +x ./kubectl
RUN mkdir -p /home/${User}/bin && cp ./kubectl /home/${User}/bin/kubectl
RUN echo -n ' export PATH=$PATH:/home/' >> /home/${User}/.bashrc
RUN echo -n ${User} >> /home/${User}/.bashrc
RUN echo '/bin' >> /home/${User}/.bashrc
RUN export PATH=$PATH:$/home/${User}/bin
# RUN kubectl version --short --client
RUN rm kubectl kubectl.sha256
