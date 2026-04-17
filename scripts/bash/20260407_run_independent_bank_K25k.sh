#!/bin/bash
#SBATCH --job-name=indbank_K25k
#SBATCH --partition=batch
#SBATCH --array=1-150
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --time=96:00:00
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=eeg37520@uga.edu
#SBATCH --output=/scratch/eeg37520/doliolid_slim/logs/indbank_K25k_%A_%a.out
#SBATCH --error=/scratch/eeg37520/doliolid_slim/logs/indbank_K25k_%A_%a.err

# Independent-runs haplotype bank construction at K_NURSES=25000.
# Each array task is one fully independent SLiM run that samples one
# nurse haplotype at the end and writes it to its own per-task file.
# The full bank is built by concatenating all per-task files after
# the array completes.
#
# Combo 5 parameters (K=25k center of life-cycle grid):
#   K_NURSES     = 25000
#   MU           = 2.4e-7   (calibrated)
#   OOZ_SURVIVAL = 0.50
#   NURSE_MORT   = 0.05
#   BURNIN       = 160000   (1.25x the longest K=25k calibration final tick)

source /apps/eb/Miniforge3/24.11.3-0/etc/profile.d/conda.sh
conda activate slim_env

WORKDIR=/scratch/eeg37520/doliolid_slim
SCRIPT=$WORKDIR/20260407_independent_bank_K25k.slim
OUTDIR=$WORKDIR/independent_bank_K25k_combo5

mkdir -p $OUTDIR
mkdir -p $WORKDIR/logs

cd $WORKDIR

slim \
  -d "TASK_ID=${SLURM_ARRAY_TASK_ID}" \
  -d "OUT_DIR='${OUTDIR}'" \
  -d "K_NURSES=25000" \
  -d "MU=2.4e-7" \
  -d "BURNIN=160000" \
  -d "OOZ_SURVIVAL=0.50" \
  -d "NURSE_MORT=0.05" \
  $SCRIPT
