#!/bin/bash
#
# Script Name: start_simple_elyra.sh
# Author: John DeHart
# Date: 7/27/23
#
# Description: Sets up and starts a Docker environment with TLJH and installs additional kernels.
#
# Usage: 
# 1. Make the script executable: chmod +x start_simple_elyra.sh
# 2. Run the script: ./start_simple_elyra.sh
#
# Prerequisites: Docker and Docker Compose should be installed and running on the machine where the script is executed.
#
# Output: 
# The script logs its output to a logfile that is created in the 'logs' directory in the same directory as the script. 
# The logfile is named 'logfile_<timestamp>.log'.
#

set -e
set -o pipefail

# Define a log file with a timestamp
NOW=$(date +"%Y%m%d_%H%M%S")
LOGFILE="$(dirname "$0")/logs/logfile_$NOW.log"

# Function to check the status of the last command
check_status() {
    if [ $? -eq 0 ]; then
        echo "SUCCESS: $1" | tee -a $LOGFILE
    else
        echo "FAILED: $1" | tee -a $LOGFILE
        exit 1
    fi
}

# Start Docker Compose
start_docker() {
    echo "Starting Docker Compose..." | tee -a $LOGFILE

    # Ensure Docker network exists
    if [ -z "$(docker network ls | grep digital_env)" ]; then
        docker network create digital_env
    fi

    # Ensure Docker volumes exist
    for volume in postgres_server_selab user_data_selab; do
        if [ -z "$(docker volume ls | grep $volume)" ]; then
            docker volume create $volume
        fi
    done

    # Start Docker Compose
    docker compose -f docker-compose-selab.yml up -d --build
    check_status "Docker Compose started"

    # Wait for the container to initialize
    echo "Waiting for the container to initialize..." | tee -a $LOGFILE
    sleep 10
}

# Install TLJH
install_tljh() {
    AUTH_ADMIN=${AUTH_ADMIN:-"admin:admin"}
    echo "Installing TLJH with admin user: $AUTH_ADMIN" | tee -a $LOGFILE
    docker compose -f docker-compose-selab.yml exec tljh bash -c \
        "rm -rf /etc/skel/scratch/scratch && \
        curl -L https://tljh.jupyter.org/bootstrap.py | sudo python3 - \
        --show-progress-page --admin $AUTH_ADMIN \
        --plugin git+https://github.com/kafonek/tljh-shared-directory \
        --user-requirements-txt-url https://raw.githubusercontent.com/enginetix2/SELab/refs/heads/main/envs/requirements_elyra.txt"
    check_status "TLJH installation"
}

# Install Elyra
install_elyra() {
    echo "Installing Elyra..." | tee -a $LOGFILE
    docker compose -f docker-compose-selab.yml exec tljh bash -c "set -e; \
        sudo -E /opt/tljh/user/bin/python3 -m pip install --upgrade elyra --pre"
    check_status "Elyra installation"
}

# Install SysMLv2 Kernel
install_sysmlv2_kernel() {
    echo "Installing SysMLv2 kernel..." | tee -a $LOGFILE
    docker compose -f docker-compose-selab.yml exec tljh bash -c "set -e; \
        sudo -E /opt/tljh/user/bin/mamba install -y conda-forge::jupyter-sysml-kernel"
    check_status "SysMLv2 kernel installation"
}

# Update SysMLv2 Kernel Configuration
update_sysmlv2_kernel() {
    echo "Updating SysMLv2 kernel configuration..." | tee -a $LOGFILE
    docker compose -f docker-compose-selab.yml exec tljh bash -c "set -e; \
        sudo sed -i 's|\"ISYSML_API_BASE_PATH\": \"http://sysml2.intercax.com:9000\"|\"ISYSML_API_BASE_PATH\": \"http://sysmlapiserver:9000\"|g' \
        /opt/tljh/user/share/jupyter/kernels/sysml/kernel.json"
    check_status "SysMLv2 kernel configuration updated"
}

# Install R Kernel
install_r_kernel() {
    echo "Installing R kernel..." | tee -a $LOGFILE
    docker compose -f docker-compose-selab.yml exec tljh bash -c "set -e; \
        sudo apt-get update && sudo apt-get install -y r-base && \
        sudo -E /opt/tljh/user/bin/mamba install -y -c conda-forge r-irkernel"
    check_status "R kernel installation"
}

# Install Bash Kernel
install_bash_kernel() {
    echo "Installing Bash kernel..." | tee -a $LOGFILE
    docker compose -f docker-compose-selab.yml exec tljh bash -c "set -e; \
        sudo -E /opt/tljh/user/bin/python -m bash_kernel.install"
    check_status "Bash kernel installation"
}

# Install Scilab Kernel
install_scilab_kernel() {
    echo "Installing Scilab kernel..." | tee -a $LOGFILE
    docker compose -f docker-compose-selab.yml exec tljh bash -c "set -e; \
        # Update and install required dependencies
        sudo apt-get update && sudo apt-get install -y xvfb x11vnc fluxbox net-tools \
        git-core git procps nano build-essential gfortran \
        libncursesw5-dev libssl-dev libsqlite3-dev tk-dev libgdbm-dev libc6-dev \
        libbz2-dev libffi-dev python3-pip unzip lsb-release software-properties-common \
        curl wget rsync mesa-utils && \
        \
        # Add Mesa drivers for better Scilab compatibility
        sudo add-apt-repository ppa:kisak/kisak-mesa -y && \
        sudo apt-get update && sudo apt-get upgrade -y && \
        \
        # Install Scilab
        cd /tmp && \
        wget https://www.scilab.org/download/6.0.2/scilab-6.0.2.bin.linux-x86_64.tar.gz && \
        tar xf scilab-6.0.2.bin.linux-x86_64.tar.gz && \
        echo 'SCILAB_EXECUTABLE=/tmp/scilab-6.0.2/bin/scilab-adv-cli' | sudo tee -a /etc/environment && \
        export SCILAB_EXECUTABLE=/tmp/scilab-6.0.2/bin/scilab-adv-cli && \
        \
        # Install Scilab kernel
        sudo -E /opt/tljh/user/bin/python3 -m pip install --upgrade pip && \
        sudo -E /opt/tljh/user/bin/python3 -m pip install scilab-kernel && \
        \
        # Install Coselica toolbox
        /tmp/scilab-6.0.2/bin/scilab-cli -e 'atomsRepositoryAdd([\"http://atoms.scilab.org/6.0\"]); exit;' -nb && \
        /tmp/scilab-6.0.2/bin/scilab-cli -e 'atomsInstall(\"coselica\"); exit;' -nb && \
        \
        # Clean up temporary files
        rm -rf /tmp/scilab-6.0.2.bin.linux-x86_64.tar.gz"
    check_status "Scilab kernel installation"
}

# Main Execution
start_docker
install_tljh
install_elyra
install_sysmlv2_kernel
update_sysmlv2_kernel
install_r_kernel
install_bash_kernel
install_scilab_kernel

echo "Script completed successfully." | tee -a $LOGFILE