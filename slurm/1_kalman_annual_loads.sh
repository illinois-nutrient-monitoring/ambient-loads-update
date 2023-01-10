#!/bin/sh

# This script calculates trends, gfn trends, and loads

# This script combines array tasks with
# bash loops to process many short runs. Array jobs are convenient
# for running lots of tasks, but if each task is short, they
# quickly become inefficient, taking more time to schedule than
# they spend doing any work and bogging down the scheduler for
# all users.
# See: https://help.rc.ufl.edu/doc/SLURM_Job_Arrays

#SBATCH --account=cmwsc
#SBATCH --partition=long
#SBATCH --time=30:00:00                 # Time limit hrs:min:sec
#SBATCH --output=logs/array_%A-%a.out        # Standard output and error log
#SBATCH --array=1-1118                    # Array range, must match N_ARRAY
#SBATCH --job-name=ambient                # Job name
#SBATCH --ntasks=1                     # Number of tasks to run
#SBATCH --nodes=1    
#SBATCH --cpus-per-task=1               # Number of cpus per processes
#SBATCH --mem-per-cpu=6gb               # Minimum memory required per cpu
#SBATCH --mail-type=ALL
#SBATCH --mail-user=thodson@usgs.gov

pwd; hostname; date

#Set the number of runs that each SLURM task should do
BASE_PATH=$HOME/projects/ambient-loads-update
#SAVE_PATH=$BASE_PATH/save
R_PATH=$BASE_PATH/R
DB=$BASE_PATH/ambient_2023.sqlite
PROJECT_PATH=/lustre/projects/water/cmwsc/thodson/ambient-loads-update

SITE_N=86                               # Number of sites
PARAM_N=14
N=$[$SITE_N * $PARAM_N] # should equal number of arrays
SEED=0 # starting bootstrap
#200? in each run, so increment SEED by 200 to add more 
#SEED=400 # starting bootstrap

# load appropriate modules
module purge
module load gnu8/8.3.0
#module load R/3.6.3
module load R/4.2.0

# Print the task and run range
#echo This is task $SLURM_ARRAY_TASK_ID

run=$SLURM_ARRAY_TASK_ID
srun -N1 -n1 Rscript $R_PATH/1_kalman_annual_loads.R $DB $PROJECT_PATH $run $SEED

date
