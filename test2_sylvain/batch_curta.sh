#!/bin/bash

#############################
# les directives Slurm vont ici:

# Your job name (displayed by the queue)
#SBATCH -J ARPS

# walltime (hh:mm::ss)
#SBATCH -t 24:00:00

# Specify the number of nodes(nodes=) and the number of cores per nodes(tasks-pernode=) to be used
#SBATCH -N 1
#SBATCH --tasks-per-node=1
#SBATCH --constraint=compute

# change working directory
# SBATCH --chdir=.

# fin des directives PBS
#############################

# useful informations to print
echo "#############################" 
echo "User:" $USER
echo "Date:" `date`
echo "Host:" `hostname`
echo "Directory:" `pwd`
echo "SLURM_JOBID:" $SLURM_JOBID
echo "SLURM_SUBMIT_DIR:" $SLURM_SUBMIT_DIR
echo "SLURM_JOB_NODELIST:" $SLURM_JOB_NODELIST
echo "#############################" 

#############################

module purge
module load compiler/2023.0.0
module load mpi/2021.5.0
#module load mpi/openmpi


#execution du code
../bin/arps < arps.input > arps.output


echo "traitement et stat finis"

# all done
echo "Job finished"

