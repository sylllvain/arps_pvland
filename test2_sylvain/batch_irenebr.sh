#!/bin/bash

#############################
# les directives cluster vont ici:
#MSUB -q rome         # Choosing nodes (see ccc_mpinfo and ccc_myproject)
#MSUB -A gen13425        # Project ID (see ccc_myproject)
#MSUB -Q normal          # Quality of service test/normal/long (see ccc_mqinfo)
#MSUB -r arps_br       # Request name
#MSUB -m scratch,work,store
#MSUB -@ sylvain.dupont@inrae.fr:begin,end
#MSUB -T 10800         # Time limit in seconds (default 7200)
#MSUB -n 128            # Number of tasks to use 
#MSUB -c 1               # Number of threads per task to use 
# -w # makes jobs with the same submission name (specified with -r) run in the order they were submitted
# fin des directives
#############################

# useful informations to print
echo "#############################"
echo "User:" $USER
echo "Date:" `date`
echo "Host:" `hostname`
echo "Directory:" `pwd`
echo "JOBID:" $BRIDGE_MSUB_JOBID 
echo "SUBMIT_DIR:" $BRIDGE_MSUB_PWD
#echo "SLURM_JOB_NODELIST:" $SLURM_JOB_NODELIST
echo "#############################"

#############################
#echo des commandes lancees
set -x

cd ${BRIDGE_MSUB_PWD}

module load mpi/openmpi/4.1.4.5
#cd ..
#./makearps clean
#./makearps -io nohdf arps_mpi
#cd ${BRIDGE_MSUB_PWD}

#cp arpsCHATShr.input $CCCSCRATCHDIR/simul_chats/hresol02/

#mkdir $CCCSCRATCHDIR/chats/bresol30cv24


#pour changer le repertoire de sortie de arps (parametre dirname) dans arps.input
# attention le nombre d'espace autour de dirname est important
#sed -i "s|^   dirname  =.*$|   dirname  = '/ccc/scratch/cont003/gen13425/dupontsy/SS/br_patch25_conv_test9_new',|g" arpsCHATSbr_patch_test.input
sed -i "s|^   dirname  =.*$|   dirname  = '/ccc/scratch/cont003/gen13425/dupontsy/SS/PV_test4_sfcphy5',|g" arps.input


#nettoyage et chargement des modules
#module purge
#attention pour jean-zay :module load intel-compilers/19.0.4 intel-mpi/2019.4


#execution du code
#ccc_mprun -n 576 -c 1 ../bin/arps_mpi_patch25_br <arpsCHATSbr_patch_test.input > arps_$BRIDGE_MSUB_JOBID.output
#ccc_mprun -n 576 -c 1 ../bin/arps_mpi_foret_br <arpsCHATSbr_foret.input > arps_$BRIDGE_MSUB_JOBID.output
ccc_mprun -n 128 -c 1 ../bin/arps_mpi <arps.input > arps_$BRIDGE_MSUB_JOBID.output
#ddt -n 576 ../bin/arps_mpi <arpsCHATSbr_patch_test.input > arps_$BRIDGE_MSUB_JOBID.output

#deplacement des fichiers log,sound,maxmin
#mv may20* /gpfsscratch/rech/jkw/commun/arps-musica/test_rtmrun/201211_Nrtm_100/
#mv arps_$SLURM_JOBID.output /gpfsscratch/rech/jkw/commun/arps-musica/test_maillage/test01/

# all done
echo "Job finished"
