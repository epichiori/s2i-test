# test
FROM centos:7

ENV SUMMARY="Base image which allows using of source-to-image."	\
    DESCRIPTION="The s2i-core image provides any images layered on top of it \
with all the tools needed to use source-to-image functionality while keeping \
the image size as small as possible."

LABEL summary="$SUMMARY" \
      description="$DESCRIPTION" \
      io.k8s.description="Platform for test s2i" \
      io.k8s.display-name="builder 0.0.1" \
      io.openshift.expose-services="8080:http" \
      io.openshift.tags="builder,1.0.1,etc." \
      io.openshift.s2i.scripts-url="image:///usr/libexec/s2i" \
      io.s2i.scripts-url=image:///usr/libexec/s2i \
      com.redhat.component="s2i-core-container" \
      name="centos/s2i-core-centos7" \
      version="1" \
      release="1" \
# TODO: Put the maintainer name in the image metadata
# LABEL maintainer="Your Name <your@email.com>"
      maintainer="E. Pichori"

# Path to be used in other layers to place s2i scripts into
ENV STI_SCRIPTS_PATH=/usr/libexec/s2i \
    APP_ROOT=/opt/app-root

# When bash is started non-interactively, to run a shell script, for example it
# looks for this variable and source the content of this file. This will enable
# the SCL for all scripts without need to do 'scl enable'.
ENV BASH_ENV=${APP_ROOT}/etc/scl_enable \
    ENV=${APP_ROOT}/etc/scl_enable \
    PROMPT_COMMAND=". ${APP_ROOT}/etc/scl_enable" \
    # The $HOME is not set by default, but some applications needs this variable
    HOME=/opt/app-root/src \
    PATH=/opt/app-root/src/bin:/opt/app-root/bin:$PATH \
    # TODO: Rename the builder environment variable to inform users about application you provide them
    BUILDER_VERSION=1.0

# TODO: Set labels used in OpenShift to describe the builder image
LABEL io.k8s.description="Platform for test s2i" \
      io.k8s.display-name="builder 0.0.1" \
      io.openshift.expose-services="8080:http" \
      io.openshift.tags="builder,1.0.1,etc." \
      io.openshift.s2i.scripts-url="image:///usr/libexec/s2i" 

# TODO: Install required packages here:
# RUN yum install -y ... && yum clean all -y
# This is the list of basic dependencies that all language container image can
# consume.
# Also setup the 'openshift' user that is used for the build execution and for the
# application runtime execution.
RUN rpmkeys --import file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7 && \
    INSTALL_PKGS="bsdtar \
    findutils \
    gettext \
    groff \
    scl-utils \
    tar \
    unzip \
    yum-utils \
    rubygems" && \
    mkdir -p ${HOME}/.pki/nssdb && \
    chown -R 1001:0 ${HOME}/.pki && \
    yum install -y --setopt=tsflags=nodocs $INSTALL_PKGS && \
    yum clean all -y && \
    rpm -V $INSTALL_PKGS

RUN gem install asdf

WORKDIR ${HOME}

# TODO: Install required packages here:
# RUN yum install -y ... && yum clean all -y
RUN yum install -y rubygems && yum clean all -y
RUN gem install asdf

# TODO (optional): Copy the builder files into /opt/app-root
# COPY ./<builder_folder>/ /opt/app-root/

# TODO: Copy the S2I scripts to /usr/libexec/s2i, since openshift/base-centos7 image
# sets io.openshift.s2i.scripts-url label that way, or update that label
COPY .s2i/bin/ /usr/libexec/s2i

# Copy extra files to the image.
COPY files/ /

##### START WFP starndardized configuration #####
# RUN chgrp -R 0 /etc /var/run /var/log /usr/local && chmod -R g=u /etc /var/run /var/log /usr/local

#WORKDIR /home/serviceuser

# Reset permissions of modified directories and add default user
RUN rpm-file-permissions && \
    useradd -u 1001 -r -g 0 -d ${HOME} -s /sbin/nologin -c "Default Application User" serviceuser && \
    chown -R 1001:0 ${APP_ROOT}

##### END  WFP starndardized configuration  #####

# This allows OpenShift Container Platform to validate the authority the image is attempting to run with and prevent running images that are trying to run as root, because running containers as a privileged user exposes potential security holes. If the image does not specify a USER, it inherits the USER from the parent image.
USER 1001

# TODO: Set the default port for applications built using this image
EXPOSE 8080
# Generic ports to bind the services started by dockercmd.sh ( httpd, nginx, Tomcat, ... )
# Actually the microservice pattern requires 1 port per container !
# EXPOSE 8000 8001 8002 8003 8004 9000 9001 9002 9003 9004

# https://docs.openshift.org/latest/creating_images/guidelines.html#openshift-specific-guidelines
#ENTRYPOINT [ "uid_entrypoint.sh" ]

# TODO: Set the default CMD for the image
CMD ["/usr/libexec/s2i/usage"]
