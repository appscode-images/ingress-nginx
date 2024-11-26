FROM {ARG_FROM}

ARG TARGETARCH

USER root

# change primary user of www-data to root
# so controller can write to any folder below
RUN sed -i 's/www-data:x:101:[[:digit:]]*:/www-data:x:101:0:/' /etc/passwd

# Fix permission during the build to avoid issues at runtime
# https://docs.openshift.com/container-platform/4.17/openshift_images/create-images.html#use-uid_create-images
RUN bash -xeu -c ' \
  writeDirs=( \
    /dbg \
    /nginx-ingress-controller \
    /wait-shutdown \
    /etc/nginx \
    /etc/ingress-controller \
    /var/log \
    /var/log/nginx \
    /tmp/nginx \
  ); \
  for dir in "${writeDirs[@]}"; do \
    chgrp -R 0 ${dir}; \
    chmod -R g=u ${dir}; \
  done'

USER www-data
