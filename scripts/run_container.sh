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
CONTAINER_INIT_SCRIPT="${CONTAINER_PROJECT_DIR}/scripts/container_init.sh"

# Ensure project directory and subdirectories exist
mkdir -p "${PROJECT_DIR}/source"
mkdir -p "${PROJECT_DIR}/data"
mkdir -p "${PROJECT_DIR}/cache/m2_cache"
mkdir -p "${PROJECT_DIR}/cache/ccache"
mkdir -p "${PROJECT_DIR}/cache/conda_cache"
mkdir -p "${PROJECT_DIR}/cache/apt"

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

    # Start container in background mode
    docker run -d  \
        --name "${CONTAINER_NAME}" \
        --gpus all \
        --network host \
        --privileged \
        --shm-size=4g \
        -v "${PROJECT_DIR}:${CONTAINER_PROJECT_DIR}" \
        -v "${PROJECT_DIR}/cache/m2_cache:/root/.m2" \
        -v "${PROJECT_DIR}/cache/ccache:/root/.ccache" \
        -v "${PROJECT_DIR}/cache/conda_cache:/root/.conda/pkgs" \
        -v "${PROJECT_DIR}/cache/apt:/var/cache/apt" \
        -w "${CONTAINER_PROJECT_DIR}" \
        --entrypoint /bin/bash \
        "${IMAGE_NAME}" \
        -c "chmod +x ${CONTAINER_INIT_SCRIPT} && echo 'INIT_START' && ${CONTAINER_INIT_SCRIPT} && echo 'INIT_COMPLETE' && tail -f /dev/null"

    echo "Container started in background. Waiting for initialization..."
    
    # Display real-time logs and wait for initialization to complete
    echo "=== Container initialization logs ==="
    docker logs -f "${CONTAINER_NAME}" &
    LOGS_PID=$!
    
    # Wait for initialization completion flag
    while true; do
        if docker logs "${CONTAINER_NAME}" 2>/dev/null | grep -q "INIT_COMPLETE"; then
            echo ""
            echo "=== Initialization completed! ==="
            kill $LOGS_PID 2>/dev/null || true
            sleep 1
            break
        fi
        sleep 2
    done

    echo 'Container started successfully!'
fi
echo "Attaching to running container: ${CONTAINER_NAME}"
docker exec -it "${CONTAINER_NAME}" /bin/bash