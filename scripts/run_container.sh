#!/bin/bash
set -e

IMAGE_TAG="1.0.0"
IMAGE_NAME="spark-rapids-dev:${IMAGE_TAG}"
CONTAINER_NAME_PREFIX="spark_rapids_dev_"
if [ -z "$1" ]; then
    CONTAINER_NAME="${CONTAINER_NAME_PREFIX}$(whoami)"
else
    CONTAINER_NAME="${CONTAINER_NAME_PREFIX}$1"
fi
# Define the project directory on the host. This will be mounted to the same path inside the container.
PROJECT_DIR=$(realpath ~/spark_rapids_dev)
CONTAINER_PROJECT_DIR="/root/spark_rapids_dev"
CONTAINER_SPARK_HOME="${CONTAINER_PROJECT_DIR}/source/spark-3.5.6-bin-hadoop3"
CONTAINER_PATH="\$SPARK_HOME/bin:\$SPARK_HOME/sbin:\$PATH"

# Ensure project directory and subdirectories exist
mkdir -p "${PROJECT_DIR}/source"
mkdir -p "${PROJECT_DIR}/data"
mkdir -p "${PROJECT_DIR}/cache/m2_cache"
mkdir -p "${PROJECT_DIR}/cache/ccache"
mkdir -p "${PROJECT_DIR}/cache/conda_cache"

echo "CONTAINER_NAME: ${CONTAINER_NAME}"

# Check if a container with the same name is already running
if docker inspect "${CONTAINER_NAME}" >/dev/null 2>&1; then
    STATUS=$(docker inspect -f '{{.State.Status}}' "${CONTAINER_NAME}")
    if [ "$STATUS" = "exited" ]; then
        echo "Container ${CONTAINER_NAME} exists but has exited"
        echo "Restarting container..."
        docker start "${CONTAINER_NAME}"
    elif [ "$STATUS" = "running" ]; then
        echo "Container ${CONTAINER_NAME} exists and is running"
    else
        echo "Container ${CONTAINER_NAME} exists with status: $STATUS"
        echo "You may want to remove it and start a new one."
        echo "To remove the container, run: docker rm -f ${CONTAINER_NAME}"
        exit 1
    fi
else
    echo "Container ${CONTAINER_NAME} does not exist"
    if [ -z "$(docker images -q "${IMAGE_NAME}")" ]; then
        echo "Docker image ${IMAGE_NAME} does not exist."
        echo "You can build it using the following script:"
        echo "~/spark_rapids_dev/scripts/build_image.sh"

        exit 1
    else
        echo "Using existing Docker image: ${IMAGE_NAME}"
    fi

    echo "Starting new container: ${CONTAINER_NAME}"

    docker run -itd  \
        --name "${CONTAINER_NAME}" \
        --gpus all \
        --network host \
        --shm-size=4g \
        -v "${PROJECT_DIR}:${CONTAINER_PROJECT_DIR}" \
        -v "${PROJECT_DIR}/cache/m2_cache:/root/.m2" \
        -v "${PROJECT_DIR}/cache/ccache:/root/.ccache" \
        -v "${PROJECT_DIR}/cache/conda_cache:/root/.conda/pkgs" \
        -w "${CONTAINER_PROJECT_DIR}" \
        "${IMAGE_NAME}" \
        /bin/bash -c "echo 'export SPARK_HOME=${CONTAINER_SPARK_HOME}' >> /root/.bashrc && echo 'export PATH=${CONTAINER_PATH}' >> /root/.bashrc && exec /usr/bin/tail -f /dev/null"

    echo 'Container started successfully!'
fi

echo "Attaching to running container: ${CONTAINER_NAME}"
docker exec -it "${CONTAINER_NAME}" /bin/bash