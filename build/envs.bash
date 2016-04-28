#!/bin/bash

CHIPSTER_CLONE_BUILDS=/mnt/artefacts/chipster-clone
CHIPSTER_BUILDS=/mnt/artefacts/chipster
CHIPSTER_WEB_SERVER_BUILDS=/mnt/artefacts/chipster-web-server
CHIPSTER_WEB_BUILDS=/mnt/artefacts/chipster-web
CHIPSTER_TOOLS_BUILDS=/mnt/artefacts/chipster-tools

TMPDIR_PATH=/tmp

TOOLS_BIN_BUILD=2
TOOLS_BIN_PATH=/mnt/artefacts/chipster-tools-bin/$TOOLS_BIN_BUILD
mkdir -p $TOOLS_BIN_PATH

# Rscript path must not change after it's compiled https://bugs.r-project.org/bugzilla/show_bug.cgi?id=14493
mkdir -p /opt/chipster/comp
TOOLS_BIN_SYMLINK=/opt/chipster/comp/tools-bin
ln -s $TOOLS_BIN_PATH $TOOLS_BIN_SYMLINK

NIC_MIRROR=bio.nic.funet.fi

function wget_retry {
  wget "$@"
}

function get_next_build {
  expr $(readlink latest | cut -d "_" -f 1 ) + 1 
}

function create_links {
  BUILD=$1
  BRANCH=$2
  rm -f latest
  ln -s $BUILD latest
  rm -f latest_$BRANCH
  ln -s $BUILD latest_$BRANCH
}

set -ex
