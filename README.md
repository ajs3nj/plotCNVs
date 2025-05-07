# plotCNVs

A command-line tool for visualizing Copy Number Variations (CNVs) from BED files using R and ggplot2.

## Description

This script creates a visualization of CNVs across multiple samples, displaying them as colored tiles on a genomic coordinate system. It's particularly useful for comparing CNV patterns across different samples in a specific genomic region.

## Requirements

The script requires the following R packages:
- optparse
- ggplot2
- dplyr
- readr
- stringr

You can install these packages in R using:
```R
install.packages(c("optparse", "ggplot2", "dplyr", "readr", "stringr"))
```

## Usage

```bash
Rscript plotCNVs.R -b <bed_files> -r <region> [-n <sample_names>] [-o <output_file>]
```

### Arguments

- `-b, --bed`: Comma-separated list of BED files containing CNV data
- `-r, --region`: Region to plot (format: `chr:start-end` or just `chr`)
- `-n, --names`: (Optional) Comma-separated sample names in the same order as BED files
- `-o, --output`: (Optional) Output plot file name (default: cnv_plot.png)

### BED File Format

The input BED files should have at least 4 columns:
1. Chromosome
2. Start position
3. End position
4. CNV type (del/DEL for deletions, dup/DUP for duplications)

## Examples

1. Plot CNVs from two samples in a specific region:
```bash
Rscript plotCNVs.R -b sample1.bed,sample2.bed -r chr1:1000000-2000000
```

2. Plot CNVs with custom sample names:
```bash
Rscript plotCNVs.R -b sample1.bed,sample2.bed -r chr1:1000000-2000000 -n "Control,Tumor"
```

3. Plot CNVs for an entire chromosome:
```bash
Rscript plotCNVs.R -b sample1.bed,sample2.bed -r chr1
```

4. Specify custom output file:
```bash
Rscript plotCNVs.R -b sample1.bed,sample2.bed -r chr1:1000000-2000000 -o my_cnvs.png
```

## Output

The script generates a PNG plot where:
- Each row represents a sample
- The x-axis shows genomic coordinates
- CNVs are displayed as colored tiles:
  - Red: Deletions (del/DEL)
  - Blue: Duplications (dup/DUP)

## Notes

- The plot height automatically adjusts based on the number of samples
- The default plot width is 10 inches
- Sample names default to the BED file names if not specified 
