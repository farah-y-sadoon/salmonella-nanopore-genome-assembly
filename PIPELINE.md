# Pipeline: *Salmonella enterica* Genome Assembly with Oxford Nanopore Long-Read Sequencing Data

## 0. List of Environments
### Conda Configuration
Before environment creation, the following channels were configured:
- **conda-forge**
- **bioconda**
- **defaults**

### Conda Environments
- **sra-tools** - SRA to FASTQ conversion
- **nanoplot** - Read quality visualization
- **seqkit** - Filtering and sequence statistics
- **flye** - De novo assembly construction
- **medaka** - Assembly polishing
- **quast** - Assembly quality assessment

### Apptainer Environments (HPC)
- **clair3_v1.0.10.sif** - Apptainer/Docker container used for high-performance variant calling

## 1. Data Aquisition
### Download Raw ONT Sequencing Reads
```bash
cd Desktop/m.binf/binf_6110/salmonella-nanopore-genome-assembly

mkdir data/

cd data/

wget https://sra-pub-run-odp.s3.amazonaws.com/sra/SRR32410565/SRR32410565

conda create -n sra-tools

conda activate sra-tools

conda install sra-tools

fasterq-dump SRR32410565 # convert sra to fastq using sra-tools - used fasterq incase there were reads longer than 65K, and seems to be latest update in the releases

```

### Download Reference Genome Assembly from NCBI
```bash
wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/006/945/GCF_000006945.2_ASM694v2/GCF_000006945.2_ASM694v2_genomic.fna.gz

gunzip GCF_000006945.2_ASM694v2_genomic.fna.gz
```

### Download Reference Genome Annotation from NCBI
```bash
wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/006/945/GCF_000006945.2_ASM694v2/GCF_000006945.2_ASM694v2_genomic.gff.gz

gunzip GCF_000006945.2_ASM694v2_genomic.gff.gz
```

## 2. Quality Assessment and Assembly
### Initial Read Quality Assessment with Nanoplot

```bash
conda create -n nanoplot

conda activate nanoplot 

conda install nanoplot

NanoPlot -t 7 --fastq data/SRR32410565.fastq -o nanoplot_qc/qc_raw_reads/
```

### Filter Reads for Length and Quality with SeqKit
```bash
conda create -n seqkit

conda activate seqkit

conda install seqkit

seqkit seq --min-len 1000 --min-qual 10 data/SRR32410565.fastq -o data/filtered_SRR32410565.fastq
```

### Post-Filtering Quality Assessment with Nanoplot
```bash
conda deactivate 

NanoPlot -t 7 --fastq data/filtered_SRR32410565.fastq -o nanoplot_qc/qc_filtered_reads/

conda activate seqkit

# Check stats to confirm coverage and that filtering was successful
seqkit stats data/filtered_SRR32410565.fastq
```

### Genome Assembly with Flye
```bash
mkdir -p assembly/flye_out

conda create -n flye

conda activate flye

conda install flye

flye --nano-hq data/filtered_SRR32410565.fastq --genome-size 5m --asm-coverage 157 --out-dir assembly/flye_out --threads 12
```

### Quality Assessment of the Assembled Draft Genome with QUAST
```bash
conda create -n quast python=3.9 -y

conda activate quast

pip install quast==5.2.0

conda install mummer

conda install minimap2

conda install matplotlib

quast.py assembly/flye_out/10-consensus/consensus.fasta -r data/GCF_000006945.2_ASM694v2_genomic.fna -o assembly/quast/qc_draft_assembly
```

### Polishing with Medaka 
```bash
conda create -n medaka

conda activate medaka

conda install -c nanoporetech medaka

# polish with raw reads
medaka_consensus -i data/SRR32410565.fastq -d assembly/flye_out/10-consensus/consensus.fasta -o assembly/medaka_out -t 12 -m r1041_e82_400bps_sup_v5.2.0 # could not use bacteria flag, used newest version of r1040 model available for medaka instead, consistent with the paper by Bogaerts et al.

```

### Quality Assessment of the Polished Genome with QUAST
```bash
conda deactivate 

quast.py assembly/medaka_out/consensus.fasta -r data/GCF_000006945.2_ASM694v2_genomic.fna -o assembly/quast/qc_polished_assembly # no drastic change here, most-likely because the basecalling was very accurate.
```

## 3. Alignment and Variant Calling 
### Alignment of Filtered Reads to Reference Genome with Minimap2
```bash
minimap2 -ax map-ont data/GCF_000006945.2_ASM694v2_genomic.fna data/filtered_SRR32410565.fastq > alignment/aligned_filtered_senter.sam
```

### Converting to BAM Format, Sorting, and Indexing with Samtools
```bash
# Convert alignment to BAM
samtools view --bam alignment/aligned_filtered_senter.sam --output alignment/aligned_filtered_senter.bam

# Sort alignment
samtools sort alignment/aligned_filtered_senter.bam -o alignment/sorted_aligned_senter.bam

# Index alignment
samtools index alignment/sorted_aligned_senter.bam

# Index reference genome
samtools faidx data/GCF_000006945.2_ASM694v2_genomic.fna

# Investigate coverage depth for plasmid vs chromosome
samtools coverage -a alignment/sorted_aligned_senter.bam

```

### Variant Calling with Clair3 (Apptainer on HPC)
To ensure reproducibility and adequeate computational resources, Variant calling was performed on the Fir cluster (Digital Research Alliance of Canada) using the Clair3 pipeline within an Apptainer container.

#### Environment Setup
```bash
cd /project/def-cottenie/fsadoon/salmonella_project/

mkdir -p software

cd software

apptainer pull docker://hkubal/clair3:v1.0.10
```
#### Transfer Data to HPC
```bash
# Mac terminal

# Sync reference genome .fna and index
rsync -avP /Users/farahsadoon/Desktop/m.binf/binf_6110/salmonella-nanopore-genome-assembly/data/GCF_000006945.2_ASM694v2_genomic.fna* fsadoon@fir.alliancecan.ca:/project/def-cottenie/fsadoon/salmonella_project/data/

# Sync sorted alignment .bam and index
rsync -avP /Users/farahsadoon/Desktop/m.binf/binf_6110/salmonella-nanopore-genome-assembly/alignment/sorted_aligned_senter.bam* fsadoon@fir.alliancecan.ca:/project/def-cottenie/fsadoon/salmonella_project/alignment/

```
#### Download Clair3 Model
```bash
mkdir -p /project/def-cottenie/fsadoon/salmonella_project/models

cd /project/def-cottenie/fsadoon/salmonella_project/models

wget https://cdn.oxfordnanoportal.com/software/analysis/models/clair3/r1041_e82_400bps_sup_v500.tar.gz

tar -zxvf r1041_e82_400bps_sup_v500.tar.gz
```

#### Clair3 SLURM Job Submission
A bash script `submit_clair3.sh` was created to execute the variant caller. 

```bash
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
```
## 4. Visualizing Assembly and Variants
### Comparing Polished Assembly to Reference with MUMmer 
```bash
conda create -n mummer

conda activate mummer

conda install mummer

# Create delta file to describe structural differences between assembly and reference 
nucmer -prefix=senter_asm_vs_ref data/GCF_000006945.2_ASM694v2_genomic.fna assembly/medaka_out/consensus.fasta

# Visualize structural differences with a dot plot
mummerplot --filter --fat --prefix=senter_asm_vs_ref senter_asm_vs_ref.delta #--filter to show only the best hit to any particular spot on either sequence (one-to-one mapping of references and query subsequences)

```
#### Investigating Read Coverage at Junctions

### Comparing SNP, Insertion, Deletion Proportions between Chromosome and Plasmid
```bash
# Create a file without the VCF headers, only keep the calls that passed quality check and output chromosome, position, ID, reference sequence, alternative sequence to a text file
grep -v "^#" merge_output.vcf | awk '$7 == "PASS" {print $1, $2, $4, $5}' > pass_variants.txt
```

```r
# Prepare libraries
library(tidyverse)

# Load data 
df_variants <- read_table("pass_variants.txt", col_names = FALSE) %>% 
  rename(chromosome = X1, 
         position = X2, 
         ref = X3, 
         alt = X4)

# Determine variant type based on string length and distinguish plasmid from chromosome
df_variants <- df_variants %>% 
  mutate(type = case_when(
    nchar(ref) == nchar(alt) ~ "SNP", 
    nchar(ref) > nchar(alt) ~ "Deletion",
    nchar(ref) < nchar(alt) ~ "Insertion"
  )) %>% 
    mutate(contig_label = if_else(chromosome == "NC_003277.2", "Plasmid", "Chromosome"))

# Calculate proportions
type_counts <- df_variants %>% 
  count(type, contig_label) %>% 
  rename(variant_type = type, 
         count = n)

# Visualize Variant-Type Proportions with a Bar Chart
ggplot(type_counts, aes(x = contig_label, y = count, fill = variant_type)) +
  geom_bar(stat = "identity", position = position_dodge(preserve = "single")) +
  geom_text(aes(label = count), 
            position = position_dodge(width = 0.9), 
            vjust = -0.5) + 
  labs(title = "Comparative Analysis of Chromosomal and Plasmid Variants",
       subtitle = "Categorization of SNPs, insertions, and deletions in Salmonlla enterica following ONT R10.4 sequencing and Clair3 variant calling",
       x = NULL,
       y = "Total Count",
       fill = "Variant Type") +
  scale_fill_brewer(palette = "Dark2") + 
  theme_minimal()
```
