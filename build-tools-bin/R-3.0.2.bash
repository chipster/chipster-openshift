#!/bin/bash

#R 3.0.2
R_VER=3.0.2  
cd ${TMPDIR_PATH}/
wget -O - http://ftp.acc.umu.se/mirror/CRAN/src/base/R-3/R-${R_VER}.tar.gz | tar -xz
cd R-${R_VER}/
export MAKEFLAGS=-j
./configure --prefix=${TOOLS_BIN_SYMLINK}/R-${R_VER}
make
make install
echo 'MAKEFLAGS=-j' > ${TOOLS_BIN_SYMLINK}/R-${R_VER}/lib/R/etc/Makevars.site # (could also be $HOME/.R/Makevars)
## clean makeflags after R install
export MAKEFLAGS=
#
cd ../
rm -rf R-${R_VER}/
