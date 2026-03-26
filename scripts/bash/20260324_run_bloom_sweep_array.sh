#!/bin/bash
#SBATCH --job-name=bloom_sweep
#SBATCH --partition=batch
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=64G
#SBATCH --time=48:00:00
#SBATCH --array=1-18
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=eeg37520@uga.edu
#SBATCH --output=/scratch/eeg37520/doliolid_slim/logs/20260324_bloom_sweep_%a.out
#SBATCH --error=/scratch/eeg37520/doliolid_slim/logs/20260324_bloom_sweep_%a.err

# =============================================================================
# PRODUCTION BLOOM FOUNDER SWEEP — 18 parameter combinations
# =============================================================================
# Reads CALIBRATED mu values from the sweep parameter file.
# DO NOT submit until calibration is complete and mu values are confirmed.
#
# Emily Gipson, UGA mfflab
# Created: 2026-03-24
# =============================================================================

cd /scratch/eeg37520/doliolid_slim

# Activate SLiM conda environment
source /apps/eb/Miniforge3/24.11.3-0/etc/profile.d/conda.sh
conda activate slim_env

# Parameter file: combo_id K_NURSES ooz_survival nurse_mortality CALIBRATED_mu
# This file must be populated with calibrated mu values before submission
PARAMFILE=/scratch/eeg37520/doliolid_slim/sweeps/20260324_sweep_params.txt

# Read this task's parameters
LINE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" $PARAMFILE)
COMBO_ID=$(echo $LINE | awk '{print $1}')
K_NURSES=$(echo $LINE | awk '{print $2}')
OOZ_SURV=$(echo $LINE | awk '{print $3}')
NURSE_MORT=$(echo $LINE | awk '{print $4}')
MU=$(echo $LINE | awk '{print $5}')

echo "=== Array task ${SLURM_ARRAY_TASK_ID}: combo ${COMBO_ID} ==="
echo "  K_NURSES=${K_NURSES} OOZ_SURV=${OOZ_SURV} NURSE_MORT=${NURSE_MORT} MU=${MU}"

OUTFILE="/scratch/eeg37520/doliolid_slim/sweeps/combo_${COMBO_ID}_sweep_results.tsv"
LOGFILE="/scratch/eeg37520/doliolid_slim/sweeps/combo_${COMBO_ID}_sweep_log.csv"

slim \
    -d K_NURSES=${K_NURSES} \
    -d MU=${MU} \
    -d OOZ_SURVIVAL=${OOZ_SURV} \
    -d NURSE_MORT=${NURSE_MORT} \
    -d COMBO_ID=${COMBO_ID} \
    -d N_REPS=500 \
    -d "OUTFILE='${OUTFILE}'" \
    -d "LOGFILE='${LOGFILE}'" \
    /scratch/eeg37520/doliolid_slim/20260324_bloom_sweep_universal.slim

echo "=== Combo ${COMBO_ID} sweep complete ==="
