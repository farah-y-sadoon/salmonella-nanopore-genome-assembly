# Pipeline: *Salmonella enterica* Genome Assembly with Oxford Nanopore Long-Read Sequencing Data

## 1. Data Aquisition
### Download Raw ONT Sequencing Reads
```bash
wget https://sra-pub-run-odp.s3.amazonaws.com/sra/SRR32410565/SRR32410565

fasterq-dump SRR32410565 # convert sra to fastq using sra-tools - used fasterq incase there were reads longer than 65K, and seems to be latest update in the releases

ls 

head SRR32410565.fastq
```

### Download Reference Genome Assembly from NCBI
```bash
wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/006/945/GCF_000006945.2_ASM694v2/GCF_000006945.2_ASM694v2_genomic.fna.gz

gunzip GCF_000006945.2_ASM694v2_genomic.fna.gz
```

## 2. Quality Assessment and Assembly
### Initial Read Quality Assessment with Nanoplot

```bash
NanoPlot -t 7 --fastq data/SRR32410565.fastq -o nanoplot/qc_raw_reads/
```

### Filter Reads for Length and Quality with SeqKit
```bash
seqkit seq --min-len 1000 --min-qual 10 data/SRR32410565.fastq -o data/filtered_SRR32410565.fastq
```

### Post-Filtering Quality Assessment with Nanoplot
```bash
NanoPlot -t 7 --fastq data/filtered_SRR32410565.fastq -o nanoplot/qc_filtered_reads/

# Check stats to confirm coverage and that filtering was successful
seqkit stats data/filtered_SRR32410565.fastq
```

### Genome Assembly with Flye
```bash
mkdir assembly/

mkdir flye_out/

flye --nano-hq data/filtered_SRR32410565.fastq --genome-size 5m --asm-coverage 157 --out-dir assembly/flye_out --threads 12
```

## 3. Quality Assessment and Polishing 
### Quality Assessment of the Assembled Genome with QUAST
```bash
python tools/quast/quast.py assembly/flye_out/10-consensus/consensus.fasta -r data/GCF_000006945.2_ASM694v2_genomic.fna -o assembly/quast/qc_initial_assembly
```

### Polishing with Medaka 
```bash
medaka_consensus -i data/SRR32410565.fastq -d assembly/flye_out/10-consensus/consensus.fasta -o assembly/medaka_out -t 12 -m r1041_e82_400bps_sup_v5.2.0 # could not use bacteria flag, used newest version of r1040 model available for medaka instead, consistent with the paper by Bogaerts et al.
```

### Quality Assessment of the Polished Genome with QUAST
```bash
python tools/quast/quast.py assembly/medaka_out/consensus.fasta -r data/GCF_000006945.2_ASM694v2_genomic.fna -o assembly/quast/qc_polished_assembly # no drastic change here, most-likely because the basecalling was very accurate. there are changes reported so polishing was effective, QUAST just doesn't explain / highlight the biological importance.
```
