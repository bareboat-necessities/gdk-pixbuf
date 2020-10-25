#!/usr/bin/env bash

#
# Build for Debian in a docker container
#

# bailout on errors and echo commands.
set -xe

DOCKER_SOCK="unix:///var/run/docker.sock"

echo "DOCKER_OPTS=\"-H tcp://127.0.0.1:2375 -H $DOCKER_SOCK -s devicemapper\"" | sudo tee /etc/default/docker > /dev/null
sudo service docker restart
sleep 5;

if [ "$EMU" = "on" ]; then
  if [ "$CONTAINER_DISTRO" = "raspbian" ]; then
      docker run --rm --privileged multiarch/qemu-user-static:register --reset
  else
      docker run --rm --privileged multiarch/qemu-user-static --reset --credential yes --persistent yes
  fi
fi

WORK_DIR=$(pwd):/ci-source

docker run --privileged -d -ti -e "container=docker"  -v $WORK_DIR:rw $DOCKER_IMAGE /bin/bash
DOCKER_CONTAINER_ID=$(docker ps --last 4 | grep $CONTAINER_DISTRO | awk '{print $1}')

docker exec -ti $DOCKER_CONTAINER_ID apt-get update
docker exec -ti $DOCKER_CONTAINER_ID apt-get -y install dpkg-dev debhelper devscripts equivs pkg-config apt-utils fakeroot
docker exec -ti $DOCKER_CONTAINER_ID apt-get -y install build-essential dh-exec meson cmake man-db \
    at-spi2-core                      \
    dh-sequence-gir                   \
    fonts-cantarell                   \
    gnome-pkg-tools                   \
    gobject-introspection             \
    libcolord-dev                     \
    libcups2-dev                      \
    libgdk-pixbuf2.0-dev              \
    libgirepository1.0-dev            \
    libjson-glib-dev                  \
    librest-dev                       \
    libxkbfile-dev                    \
    sassc                             \
    xvfb                              \
    gtk-doc-tools                     \
    libglib2.0-doc                    \
    libcairo2-doc                     \
    xsltproc                          \
    libglib2.0-doc                    \
    libatk-bridge2.0-dev              \
    libatk1.0-dev                     \
    libcairo2-dev                     \
    libegl1-mesa-dev                  \
    libepoxy-dev                      \
    libfontconfig1-dev                \
    libfribidi-dev                    \
    libharfbuzz-dev                   \
    libpango1.0-dev                   \
    libwayland-dev                    \
    libxcomposite-dev                 \
    libxcursor-dev                    \
    libxdamage-dev                    \
    libxext-dev                       \
    libxfixes-dev                     \
    libxi-dev                         \
    libxinerama-dev                   \
    libxkbcommon-dev                  \
    libxml2-utils                     \
    libxrandr-dev                     \
    wayland-protocols                 \
    libatk1.0-doc                     \
    libc6                             \
    libglib2.0-0                      \
    libjson-glib-1.0-0                \
    libxcomposite1                    \
    libpango1.0-doc

docker exec -ti $DOCKER_CONTAINER_ID apt-get -y upgrade
docker exec -ti $DOCKER_CONTAINER_ID ldconfig

docker exec -ti $DOCKER_CONTAINER_ID /bin/bash -xec \
    "update-alternatives --set fakeroot /usr/bin/fakeroot-tcp; cd ci-source; dpkg-buildpackage -b -uc -us -j4; " \
    "mkdir dist; mv ../*.deb dist; chmod -R a+rw dist"

find dist -name \*.deb

echo "Stopping"
docker ps -a
docker stop $DOCKER_CONTAINER_ID
docker rm -v $DOCKER_CONTAINER_ID
