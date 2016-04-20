#!/bin/bash

TOOLS_BIN_BUILD=1
TOOLS_BUILD=2
TMPDIR_PATH=/tmp
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
