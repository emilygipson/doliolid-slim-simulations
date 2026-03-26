#!/bin/bash
#SBATCH --job-name=slim_calibrate
#SBATCH --partition=batch
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=16G
#SBATCH --time=24:00:00
#SBATCH --array=1-18
#SBATCH --output=/scratch/eeg37520/doliolid_slim/logs/20260324_calibration_%a.out
#SBATCH --error=/scratch/eeg37520/doliolid_slim/logs/20260324_calibration_%a.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=eeg37520@uga.edu

# =============================================================================
# MU CALIBRATION ARRAY JOB — 18 parameter combinations
# Each array task reads one line from the parameter file and runs
# the universal calibration SLiM script with those parameters.
# =============================================================================

cd /scratch/eeg37520/doliolid_slim

# Activate SLiM conda environment
source /apps/eb/Miniforge3/24.11.3-0/etc/profile.d/conda.sh
conda activate slim_env

# Create log directories if they don't exist
mkdir -p /scratch/eeg37520/doliolid_slim/logs
mkdir -p /scratch/eeg37520/doliolid_slim/calibration_logs

# Read parameters for this array task
PARAMFILE=/scratch/eeg37520/doliolid_slim/20260324_calibration_params.txt
LINE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" $PARAMFILE)

COMBO_ID=$(echo $LINE | awk '{print $1}')
K_NURSES=$(echo $LINE | awk '{print $2}')
MU=$(echo $LINE | awk '{print $3}')
OOZ_SURV=$(echo $LINE | awk '{print $4}')
NURSE_MORT=$(echo $LINE | awk '{print $5}')

echo "========================================"
echo "  Calibration: Combo ${COMBO_ID}"
echo "  K_NURSES=${K_NURSES}"
echo "  MU=${MU}"
echo "  OOZ_SURVIVAL=${OOZ_SURV}"
echo "  NURSE_MORTALITY=${NURSE_MORT}"
echo "  Array task: ${SLURM_ARRAY_TASK_ID}"
echo "  Job ID: ${SLURM_JOB_ID}"
echo "  Start: $(date)"
echo "========================================"

slim \
    -d K_NURSES=${K_NURSES} \
    -d MU=${MU} \
    -d OOZ_SURVIVAL=${OOZ_SURV} \
    -d NURSE_MORTALITY=${NURSE_MORT} \
    -d COMBO_ID=${COMBO_ID} \
    -d "LOGDIR='/scratch/eeg37520/doliolid_slim/calibration_logs'" \
    -d END_TICK=30000 \
    /scratch/eeg37520/doliolid_slim/20260324_mu_calibration_universal.slim

echo "========================================"
echo "  Finished: $(date)"
echo "========================================"
