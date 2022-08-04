#!/bin/sh

# This script combines array tasks with
# bash loops to process many short runs. Array jobs are convenient
# for running lots of tasks, but if each task is short, they
# quickly become inefficient, taking more time to schedule than
# they spend doing any work and bogging down the scheduler for
# all users.
# See: https://help.rc.ufl.edu/doc/SLURM_Job_Arrays

#SBATCH --job-name=nrec                 # Job name
#SBATCH --account=cmwsc
#SBATCH -p normal
#SBATCH --time=04:00:00                 # Time limit hrs:min:sec
#SBATCH --output=logs/data_release_%A.out    # Standard output and error log
#SBATCH --ntasks=1                      # Number of tasks to run
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1               # Number of cpus per processes
#SBATCH --mem-per-cpu=4gb               # Minimum memory required per cpu
#SBATCH --mail-type=ALL
#SBATCH --mail-user=thodson@usgs.gov

#module load legacy
#module load python/pPython3

# conda create --name nrec
# python3 -m venv /home/${USER}/environments/nrec
source /home/${USER}/environments/nrec/bin/activate

srun --mpi=pmi2 python3 ../python/2_make_data_release.py
