#!/usr/bin/env Rscript

# Load required libraries
suppressPackageStartupMessages({
  library(optparse)
  library(ggplot2)
  library(dplyr)
  library(readr)
  library(stringr)
})

# Command-line options
option_list <- list(
  make_option(
    c("-b", "--bed"),
    type = "character",
    action = "store",
    help = "Comma-separated list of BED files with CNVs."
  ),
  make_option(
    c("-n", "--names"),
    type = "character",
    default = NULL,
    help = "Comma-separated sample names (in order of BED files)."
  ),
  make_option(
    c("-r", "--region"),
    type = "character",
    help = "Region to plot, e.g. chr1:1000000-2000000 or chr1"
  ),
  make_option(
    c("-o", "--output"),
    type = "character",
    default = "cnv_plot.png",
    help = "Output plot file (default: cnv_plot.png)"
  )
)

opt <- parse_args(OptionParser(option_list = option_list))

if (is.null(opt$bed) || is.null(opt$region)) {
  stop(
    "You must provide a comma-separated list of BED files and a region to plot. ",
    "Use -h for help."
  )
}

# Parse region
region_pattern <- "^([^:]+)(?::(\\d+)-(\\d+))?$"
region_match <- str_match(opt$region, region_pattern)
if (is.na(region_match[1, 1])) {
  stop("Region must be in format chr:start-end or chr")
}

chrom <- region_match[1, 2]
start <- ifelse(
  is.na(region_match[1, 3]),
  0,
  as.numeric(region_match[1, 3])
)
end <- ifelse(
  is.na(region_match[1, 4]),
  Inf,
  as.numeric(region_match[1, 4])
)

# Parse BED files (comma-separated)
bed_files <- strsplit(opt$bed, ",")[[1]]
bed_files <- trimws(bed_files)  # Remove any accidental spaces

# Parse sample names
if (!is.null(opt$names)) {
  sample_names <- strsplit(opt$names, ",")[[1]]
  sample_names <- trimws(sample_names)
  if (length(sample_names) != length(bed_files)) {
    stop("Number of sample names must match number of BED files.")
  }
} else {
  sample_names <- basename(bed_files)
}

# Read and combine BED files
all_cnv <- data.frame()
for (i in seq_along(bed_files)) {
  bed <- read_tsv(
    bed_files[i],
    col_names = FALSE,
    comment = "#",
    col_types = cols(.default = "c")
  )
  if (ncol(bed) < 4) {
    stop("BED file must have at least 4 columns: chrom, start, end, type")
  }
  bed <- bed %>%
    mutate(
      chrom = as.character(X1),
      start = as.numeric(X2),
      end = as.numeric(X3),
      type = as.character(X4),
      sample = sample_names[i]
    ) %>%
    select(sample, chrom, start, end, type)
  all_cnv <- bind_rows(all_cnv, bed)
}

# Filter for region
all_cnv <- all_cnv %>%
  filter(
    chrom == chrom,
    start < end,
    end >= start,
    start < end,
    start <= end,
    start < ifelse(is.infinite(end), Inf, end),
    end > start
  )
if (!is.infinite(start)) {
  all_cnv <- all_cnv %>% filter(end >= start)
}
if (!is.infinite(end)) {
  all_cnv <- all_cnv %>% filter(start <= end)
}

# Set y-axis order as a factor, preserving user input order
all_cnv$sample <- factor(all_cnv$sample, levels = sample_names)

# Calculate the center and width for each tile
all_cnv <- all_cnv %>%
  mutate(
    x = (start + end) / 2,
    width = end - start
  )

# Set up color values
fill_vals <- c(
  "del" = "red",
  "dup" = "blue",
  "DEL" = "red",
  "DUP" = "blue"
)

# Plot with geom_tile and discrete y-axis
p <- ggplot(
  all_cnv,
  aes(x = x, y = sample, width = width, fill = type)
) +
  geom_tile(
    aes(width = width, height = 0.8, color = type),
    alpha = 0.7
  ) +
  scale_fill_manual(values = fill_vals) +
  scale_color_manual(values = fill_vals) +
  scale_y_discrete(
    limits = sample_names,
    expand = expansion(add = 0.5)
  ) +
  scale_x_continuous(
    labels = scales::comma,
    expand = expansion(mult = 0.01)
  ) +
  labs(
    x = paste0(chrom, " position"),
    y = "Sample",
    title = paste0(
      "CNVs in ",
      chrom,
      ifelse(
        is.infinite(start),
        "",
        paste0(":", start, "-", end)
      )
    )
  ) +
  theme_bw() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    panel.grid.minor = element_blank()
  )

ggsave(
  opt$output,
  p,
  width = 10,
  height = 1 + length(sample_names) * 0.5
)

cat("Plot saved to", opt$output, "\n")