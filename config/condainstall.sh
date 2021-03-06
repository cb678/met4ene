#!/bin/tcsh
# Install Anaconda
wget "https://repo.anaconda.com/archive/Anaconda3-2019.07-Linux-x86_64.sh"
chmod +x Anaconda3-2019.07-Linux-x86_64.sh
./Anaconda3-2019.07-Linux-x86_64.sh
source ~/.bashrc 

# Initialize anaconda
conda init tcsh
source ~/.tcshrc 

# Create runwrf conda environment
conda create --name runwrf python=3.7

# Install necessary packages
pip install -U pytest
pip install PyYAML
pip install requests
pip install jupyter
conda install -c conda-forge xarray cartopy wrf-python pynio pseudonetcdf
pip install siphon
conda install -c conda-forge nco  # I did this for the magma2 environment only.
conda install -c conda-forge ncl
echo "Install pvlib-python by cloning the repository and running (pip install -e .) in the directory with setup.py"
echo "Install optwrf by cloning the met4ene repository and running (pip install -e .) in the met4ene/optwrf/ directory"