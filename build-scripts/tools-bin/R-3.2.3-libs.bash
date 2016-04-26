#!/bin/bash

R_VER=3.2.3
  
#R libraries

cd ${TMPDIR_PATH}/
wget https://raw.githubusercontent.com/chipster/chipster-tools/master/modules/admin/R-3.2.3/install-libs.R
wget https://raw.githubusercontent.com/chipster/chipster-tools/master/modules/admin/R/smip.R
${TOOLS_BIN_PATH}/R-${R_VER}/bin/Rscript --vanilla install-libs.R
