#!/bin/csh

#SBATCH -J ung_metg		# Job name
#SBATCH -o output.metgrid	# Name of stdout output file(%j expands to jobId)
#SBATCH -e errors.metgrid	# Name of stderr output file(%j expands to jobId)
#SBATCH --nodes=1		# Total number of nodes requested 
#SBATCH --ntasks=1		# Total number of tasks to be configured for. 
#SBATCH --tasks-per-node=1	# sets number of tasks to run on each node. 
#SBATCH --cpus-per-task=1	# sets number of cpus needed by each task (if task is "make -j3" number should be 3).
#SBATCH --get-user-env		# tells sbatch to retrieve the users login environment. 
#SBATCH -t 00:30:00		# Run time (hh:mm:ss) 
#SBATCH --mem=1000M		# memory required per node
#SBATCH --partition=default_cpu	# Which queue it should run on.

limit stacksize unlimited

### ---------------  run ungrib  -------------------------

./ungrib.exe

### ---------------  get rid of links to raw grib file----

rm -f GRIBFILE.*

### ---------------  run metgrid  ------------------------

./metgrid.exe

### ---------------  get rid of ungrib intermediate files-

rm -f FILE*
rm -f PFILE*

exit
