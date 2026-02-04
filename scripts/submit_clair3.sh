#!/bin/bash
#SBATCH --account=def-cottenie
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=01:00:00
#SBATCH --job-name=Clair3_Salmonella
#SBATCH --output=%j.log

# 1. Load the Apptainer module
module load apptainer/1.4.5

# 2. Set Paths
BASE_DIR="/project/def-cottenie/fsadoon/salmonella_project"
INPUT_BAM="${BASE_DIR}/alignment/sorted_aligned_senter.bam"
REF_FASTA="${BASE_DIR}/data/GCF_000006945.2_ASM694v2_genomic.fna"
MODEL_DIR="${BASE_DIR}/models/r1041_e82_400bps_sup_v500"
OUTPUT_DIR="${BASE_DIR}/clair3_results"
CONTAINER="${BASE_DIR}/software/clair3_v1.0.10.sif"

mkdir -p ${OUTPUT_DIR}

# 3. Run Clair3 via Apptainer
apptainer exec -B /project:/project ${CONTAINER} \
  /bin/bash -c "export CONDA_PREFIX=/opt/conda/envs/clair3 && /opt/bin/run_clair3.sh \
  --bam_fn=${INPUT_BAM} \
  --ref_fn=${REF_FASTA} \
  --threads=8 \
  --platform='ont' \
  --model_path=${MODEL_DIR} \
  --output=${OUTPUT_DIR} \
  --include_all_ctgs \
  --haploid_precise \
  --no_phasing_for_fa"
