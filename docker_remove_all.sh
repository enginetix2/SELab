#!/bin/bash

# Define the Docker network and volumes
NETWORK_NAME="digital_env"
VOLUME_POSTGRES="postgres_server_selab"
VOLUME_USER_DATA="user_data_selab"
COMPOSE_FILE="docker-compose-selab.yml"

# Function to delete the Docker network
delete_network() {
    if [ ! -z "$(docker network ls | grep $NETWORK_NAME)" ]; then
        echo "Deleting Docker network: $NETWORK_NAME"
        docker network rm $NETWORK_NAME
    else
        echo "Docker network $NETWORK_NAME does not exist."
    fi
}

# Function to delete Docker volumes
delete_volumes() {
    for volume in $VOLUME_POSTGRES $VOLUME_USER_DATA; do
        if [ ! -z "$(docker volume ls | grep $volume)" ]; then
            echo "Deleting Docker volume: $volume"
            docker volume rm $volume
        else
            echo "Docker volume $volume does not exist."
        fi
    done
}

# Function to stop and remove containers from the compose file
delete_containers() {
    echo "Stopping and removing containers defined in $COMPOSE_FILE"
    docker compose -f $COMPOSE_FILE down --volumes --remove-orphans
}

# Call the functions
delete_containers
delete_volumes
delete_network

echo "Cleanup completed."