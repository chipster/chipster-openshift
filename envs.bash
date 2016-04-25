#!/bin/bash

CHIPSTER_CLONE_BUILD=1
CHIPSTER_BUILD=1
CHIPSTER_WEB_SERVER_BUILD=1
CHIPSTER_WEB_BUILD=2
TOOLS_BIN_BUILD=2
TOOLS_BUILD=7
TMPDIR_PATH=/tmp
CHIPSTER_CLONE_PATH=/mnt/artefacts/chipster-clone/$CHIPSTER_CLONE_BUILD
CHIPSTER_PATH=/mnt/artefacts/chipster/$CHIPSTER_BUILD
CHIPSTER_WEB_SERVER_PATH=/mnt/artefacts/chipster-web-server/$CHIPSTER_WEB_SERVER_BUILD
CHIPSTER_WEB_PATH=/mnt/artefacts/chipster-web/$CHIPSTER_WEB_BUILD
TOOLS_BIN_PATH=/mnt/artefacts/chipster-tools-bin/$TOOLS_BIN_BUILD
TOOLS_PATH=/mnt/artefacts/chipster-tools/$TOOLS_BUILD

mkdir -p $TOOLS_BIN_PATH

# Rscript path must not change after it's compiled https://bugs.r-project.org/bugzilla/show_bug.cgi?id=14493
mkdir -p /opt/chipster/comp
TOOLS_BIN_SYMLINK=/opt/chipster/comp/tools-bin
ln -s $TOOLS_BIN_PATH $TOOLS_BIN_SYMLINK

NIC_MIRROR=bio.nic.funet.fi

function wget_retry {
	wget "$@"
}

set -ex
