#!/bin/bash
#
# Script Name: start.sh
# Author: John DeHart
# Date: 7/27/23
#
# Description: This bash script sets up and starts a Docker environment with 
#              The Littlest JupyterHub (tljh), with additional configurations for multiple
#              Python environments, and pre-installation of required packages and tools like Elyra.
#              It also updates the Sysmlv2 kernel model publishing location.
#
# Usage: 
# 1. Make the script executable: chmod +x tljh_docker_setup.sh
# 2. Run the script: ./tljh_docker_setup.sh
#
# Prerequisites: Docker and Docker Compose should be installed and running on the machine where the script is executed.
#
# Steps:
# 1. The script sets up a Docker network and a volume (if they don't exist).
# 2. It then removes the 'selab-tljh' image if it exists and starts up the Docker containers defined in docker-compose.yml.
# 3. TLJH is installed and configured with an admin user.
# 4. Base Conda environment is updated with packages defined in /tmp/updates/base_env.yaml inside the TLJH Docker container.
# 5. Additional Conda environments are created or updated based on yaml files in /tmp/envs inside the TLJH Docker container.
# 6. Elyra is installed using the requirements file /tmp/envs/elyra.txt.
# 7. The Sysmlv2 kernel model publishing location is updated.
#
# Output: 
# The script logs its output to a logfile that is created in the 'logs' directory in the same directory as the script. 
# The logfile is named 'logfile_<timestamp>.log'.
#
# Note: 
# This script assumes the presence of specific files and directories, and does not check if they exist. 
# Ensure all necessary files and directories are present before running the script.
#

set -e #
set -o pipefail

# Define a log file with a timestamp
NOW=$(date +"%Y%m%d_%H%M%S")
LOGFILE="$(dirname "$0")/logs/logfile_$NOW.log"

# Get the directory containing this script.
SCRIPT_DIR="$(dirname "$(readlink -f "$BASH_SOURCE")")"

# Define a function to check the status
check_status() {
    if [ $? -eq 0 ]; then
        echo "SUCCESS: $1" | tee -a $LOGFILE
    else
        echo "FAILED: $1" | tee -a $LOGFILE
        exit 1
    fi
}

# Start docker-compose
start_docker() {

    # Check if the Docker network exists and create it if it does not
    if [ -z "$(docker network ls | grep digital_env)" ]; then
    docker network create digital_env
    fi

    # Check if the Docker volume exists and create it if it does not
    if [ -z "$(docker volume ls | grep postgres_server_selab)" ]; then
    docker volume create postgres_server_selab
    fi

    # Check if the Docker volume exists and create it if it does not
    if [ -z "$(docker volume ls | grep user_data_selab)" ]; then
    docker volume create user_data_selab
    fi
    
    echo "Starting docker-compose..." | tee -a $LOGFILE
    # docker image rm -f selab
    docker compose -f docker-compose-selab.yml up -d --build
    check_status "docker-compose -f docker-compose-selab.yml start"
}

# Install tljh
# Note: the scratch directory must be removed before updating tljh
install_tljh() {
    AUTH_ADMIN=${AUTH_ADMIN:-"admin:admin"}
    echo "Create User: $AUTH_ADMIN" | tee -a $LOGFILE
    docker compose -f docker-compose-selab.yml exec tljh bash -c \
        "rm -rf /etc/skel/scratch/scratch && \
        curl -L https://tljh.jupyter.org/bootstrap.py \
        | sudo python3 - --show-progress-page --admin $AUTH_ADMIN --plugin git+https://github.com/kafonek/tljh-shared-directory \
        --user-requirements-txt-url https://raw.githubusercontent.com/enginetix2/SELab/refs/heads/main/envs/requirements.txt"
    check_status "Installed tljh"
}

# Update sysmlv2 kernel model publish location
update_sysmlv2_kernel() {
    echo "Updating the Sysmlv2 kernel model publishing location" | tee -a $LOGFILE
    docker compose -f docker-compose-selab.yml exec tljh bash -c "set -e; \
        sudo sed -i 's|\"ISYSML_API_BASE_PATH\": \"http://sysml2.intercax.com:9000\"|\"ISYSML_API_BASE_PATH\": \"http://sysmlapiserver:9000\"|g' /opt/tljh/user/envs/sysmlv2/share/jupyter/kernels/sysml/kernel.json"
    check_status "Sysmlv2 model publish location"
}

# Call the functions
start_docker
install_tljh
update_sysmlv2_kernel

# Done!!!
echo "Script completed successfully." | tee -a $LOGFILE