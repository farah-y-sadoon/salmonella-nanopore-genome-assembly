'''
Visualizing variant calling results from Salmonella enterica Nanopore R10.4 reads against NCBI reference genome
'''

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
