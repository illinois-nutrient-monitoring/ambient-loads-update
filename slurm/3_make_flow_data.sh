#!/bin/sh

# This script combines array tasks with
# bash loops to process many short runs. Array jobs are convenient
# for running lots of tasks, but if each task is short, they
# quickly become inefficient, taking more time to schedule than
# they spend doing any work and bogging down the scheduler for
# all users.
# See: https://help.rc.ufl.edu/doc/SLURM_Job_Arrays

#SBATCH --account=cmwsc
#SBATCH -p normal 
#SBATCH --time=04:00:00                 # Time limit hrs:min:sec
#SBATCH --job-name=ambient                # Job name
#SBATCH --ntasks=1                     # Number of tasks to run
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1               # Number of cpus per processes
#SBATCH --mem-per-cpu=4gb               # Minimum memory required per cpu
#SBATCH --mail-type=ALL
#SBATCH --mail-user=thodson@usgs.gov

pwd; hostname; date

#Set the number of runs that each SLURM task should do
BASE_PATH=$HOME/projects/ambient-loads-update
#SAVE_PATH=$BASE_PATH/save
SAVE_PATH=/lustre/projects/water/cmwsc/thodson/ambient-loads-update/elists
R_PATH=$BASE_PATH/R
#DB=$BASE_PATH/ambient_2023.sqlite

# load appropriate modules
module purge
module load gnu8/8.3.0
module load R/4.2.0

srun -N1 -n1 Rscript $R_PATH/3_make_flow_data.R

date
