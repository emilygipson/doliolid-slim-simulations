# doliolid-slim-simulations

Forward-time population genetic simulations modeling bloom founder dynamics in the doliolid tunicate Dolioletta gegenbauri, using SLiM 5.


- nonWF SLiM model with a four-stage life cycle (oozooid, nurse, phorozooid, gonozooid) implementing obligate alternation of sexual and asexual reproduction
- Haploid mitochondrial chromosome 
- Mutation rate calibration to empirical nucleotide diversity
- Parameter sweeps across life cycle parameters (K_NURSES, oozooid survival, nurse mortality)
- Purifying selection models with per-gene DFE based on empirical dN/dS ratios
- Pooled haplotype bank approach for efficient bloom founder sweeps across k values
- Summary statistics: pi, Tajima's D, Fu's Fs, haplotype uniqueness, minimum pairwise distance

## Repository structure
```
doliolid-slim-simulations/
├── scripts/
│   ├── slim/       # SLiM simulation scripts
│   ├── bash/       # SLURM job submission wrappers
│   └── R/          # Calibration checking, post-processing, visualization
└── figures/        # Output figures
```

## Software

| Tool | Purpose |
|------|---------|
| SLiM 5.1 | Forward genetic simulations |
| R | Post-processing, visualization, ABC (planned) |
| UGA Sapelo2 | HPC cluster (SLURM) |



## Contact

Emily Gipson — Emily.Gipson@uga.edu

