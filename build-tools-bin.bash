#!/bin/bash

bash utils/create-artefacts-volume.bash

bash utils/run-job.bash build-tools-bin/chipster-tools.bash base envs.bash

bash utils/create-image.bash build-tools-bin/R tools-bin-r

# lib build is broken
#bash utils/run-job.bash build-tools-bin/R-3.0.2.bash tools-bin-r envs.bash
#bash utils/run-job.bash build-tools-bin/R-3.0.2-libs.bash tools-bin-r envs.bash

bash utils/run-job.bash build-tools-bin/R-3.2.3.bash tools-bin-r envs.bash
bash utils/run-job.bash build-tools-bin/R-3.2.3-libs.bash tools-bin-r envs.bash

bash utils/create-image.bash build-tools-bin/samtools tools-bin-samtools

bash utils/run-job.bash build-tools-bin/SAM_tools1.bash tools-bin-samtools envs.bash
bash utils/run-job.bash build-tools-bin/BEDTools.bash tools-bin-samtools envs.bash

bash utils/run-job.bash build-tools-bin/SAM_tools.bash base envs.bash

bash utils/create-image.bash build-tools-bin/vcftools tools-bin-vcftools

bash utils/run-job.bash build-tools-bin/vcftools.bash base envs.bash
