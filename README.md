# doliolid-slim-simulations

Forward-time population genetic simulations modeling bloom founder dynamics in *Dolioletta gegenbauri*, using SLiM 5.

## Model features

- nonWF model with obligate alternation of sexual and asexual reproduction
- Haploid mitochondrial chromosome
- Mutation rate calibration to empirical nucleotide diversity
- Parameter sweeps across life cycle parameters
- Purifying selection with per-gene DFE based on empirical dN/dS
- Bloom founder sweeps from a pooled haplotype bank
- Summary statistics: pi, Tajima's D, Fu's Fs, haplotype uniqueness, minimum pairwise distance

## Repository structure

\`\`\`
doliolid-slim-simulations/
└── scripts/
    ├── slim/       # SLiM simulation scripts
    ├── bash/       # SLURM job submission wrappers
    └── R/          # Calibration checking, post-processing, visualization
\`\`\`

## Software

| Tool | Purpose |
|------|---------|
| SLiM 5.1 | Forward genetic simulations |
| R | Post-processing and visualization |
