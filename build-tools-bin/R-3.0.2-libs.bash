#!/bin/bash

R_VER=3.0.2
  
#R libraries
${TOOLS_BIN_SYMLINK}/R-${R_VER}/bin/Rscript --vanilla ${TOOLS_PATH}/chipster-tools/modules/admin/R/install-libs.R
