#!/usr/bin/env bash

EXT=$1
REPO=$2
DISTRO=$3

for pkg_file in dist/*.$EXT; do
  cloudsmith push deb $REPO/$DISTRO $pkg_file
  RESULT=$?
  if [[ $pkg_file == "*all.deb" && $RESULT -ne 0 ]] ; then
     echo " skipping already deployed $pkg_file"
  fi
done