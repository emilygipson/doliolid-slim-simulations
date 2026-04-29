#!/bin/bash
#SBATCH --job-name=pursel_cal
#SBATCH --partition=batch
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=32G
#SBATCH --time=24:00:00
#SBATCH --array=1-11
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=eeg37520@uga.edu
#SBATCH --output=/scratch/eeg37520/doliolid_slim/logs/20260324_pursel_cal_%a.out
#SBATCH --error=/scratch/eeg37520/doliolid_slim/logs/20260324_pursel_cal_%a.err

# PURIFYING SELECTION CALIBRATION — 11 DFE parameter combinations
# All at combo 4 life cycle: K=5000, OOZ_SURVIVAL=0.50, NURSE_MORT=0.05
#
# Emily Gipson, UGA mfflab

cd /scratch/eeg37520/doliolid_slim

source /apps/eb/Miniforge3/24.11.3-0/etc/profile.d/conda.sh
conda activate slim_env

PARAMFILE=/scratch/eeg37520/doliolid_slim/pursel_calibration/20260324_pursel_calibration_params.txt

LINE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" $PARAMFILE)
PURSEL_ID=$(echo $LINE | awk '{print $1}')
DFE_TYPE=$(echo $LINE | awk '{print $2}')
SEL_COEFF=$(echo $LINE | awk '{print $3}')
GAMMA_SHAPE=$(echo $LINE | awk '{print $4}')
MU=$(echo $LINE | awk '{print $5}')

echo "=== Array task ${SLURM_ARRAY_TASK_ID}: pursel ${PURSEL_ID} ==="
echo "  DFE_TYPE=${DFE_TYPE} SEL_COEFF=${SEL_COEFF} GAMMA_SHAPE=${GAMMA_SHAPE} MU=${MU}"

LOGFILE="/scratch/eeg37520/doliolid_slim/pursel_calibration/pursel_${PURSEL_ID}_calibration_log.csv"

# Build the SLiM command
SLIM_CMD="slim -d PURSEL_ID=${PURSEL_ID} -d \"DFE_TYPE='${DFE_TYPE}'\" -d SEL_COEFF=${SEL_COEFF} -d MU=${MU} -d \"LOGFILE='${LOGFILE}'\""

# Add GAMMA_SHAPE only for gamma DFE
if [ "$DFE_TYPE" = "gamma" ]; then
    SLIM_CMD="${SLIM_CMD} -d GAMMA_SHAPE=${GAMMA_SHAPE}"
fi

SLIM_CMD="${SLIM_CMD} /scratch/eeg37520/doliolid_slim/20260324_pursel_calibration.slim"

echo "Running: ${SLIM_CMD}"
eval ${SLIM_CMD}

echo "=== Pursel ${PURSEL_ID} calibration complete ==="
