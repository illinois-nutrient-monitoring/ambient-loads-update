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
#SBATCH --time=02:00:00                 # Time limit hrs:min:sec
#SBATCH --output=logs/array_%A-%a.out        # Standard output and error log
#SBATCH --array=1-32                    # Array range, must match N_ARRAY
#SBATCH --job-name=ambient                # Job name
#SBATCH --ntasks=11                     # Number of tasks to run
#SBATCH --nodes=1-10
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
DB=$BASE_PATH/ambient_2023.sqlite

SITE_N=86                               # Number of sites
PARAM_N=13
N=$[$SITE_N * $PARAM_N]
N_ARRAY=13
PER_TASK=$[$N/$N_ARRAY + 1] #NOTE: PER_TASK should be PER_ARRAY

# Calculate the starting and ending values for this task based
# on the SLURM task and the number of runs per task.
START_NUM=$(( ($SLURM_ARRAY_TASK_ID - 1) * $PER_TASK + 1 ))
END_NUM=$(( $SLURM_ARRAY_TASK_ID * $PER_TASK ))

if [ $END_NUM -gt $N ]
then
    END_NUM=$N
fi

echo N $N
echo ARRAYS $N_ARRAY
echo ID $SLURM_ARRAY_TASK_ID
echo per task $PER_TASK
echo START $START_NUM
echo END $END_NUM

# load appropriate modules
module purge
module load gnu8/8.3.0
#module load R/3.6.3
module load R/4.2.0

# Print the task and run range
echo This is task $SLURM_ARRAY_TASK_ID, which will do runs $START_NUM to $END_NUM

# Run the loop of runs for this task.
for (( run=$START_NUM; run<=$END_NUM; run++ )); do
  echo This is SLURM task $SLURM_ARRAY_TASK_ID, run number $run
  srun -N1 -n1 Rscript $R_PATH/0_make_eLists.R $DB $SAVE_PATH $run &
done

wait

date
