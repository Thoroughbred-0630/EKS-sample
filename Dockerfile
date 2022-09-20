FROM httpd:latest

ARG USER

# RUN yum update -y \
#     && yum install \
#         systemd \
#         # service \
#         # tar \
#         # unzip \
#         sudo \
#         hostname \
#         -y

RUN apt-get update -y
# USER root
# RUN sed -i 's/^HOSTNAME=[a-zA-Z0-9\.\-]*$/HOSTNAME=${USER}/g' /etc/sysconfig/network
# RUN hostname ${USER}
# RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime
# RUN sed -i 's|^ZONE=[a-zA-Z0-9\.\"]*$|ZONE="Asia/Tokyo"|g' /etc/sysconfig/clock
# RUN echo "LANG=ja_JP.UTF-8" > /etc/sysconfig/i18n

# RUN yum install -y
# RUN yum install httpd -y
# RUN /etc/init.d/httpd status
# RUN /sbin/service httpd start
# RUN chkconfig httpd on
# EXPOSE 5353
COPY index.html /usr/local/apache2/htdoc/


