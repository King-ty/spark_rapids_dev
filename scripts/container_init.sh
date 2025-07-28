#!/bin/bash
set -e

apt update
apt install -y --no-install-recommends gnupg
echo "deb http://developer.download.nvidia.com/devtools/repos/ubuntu$(source /etc/lsb-release; echo "$DISTRIB_RELEASE" | tr -d .)/$(dpkg --print-architecture) /" | tee /etc/apt/sources.list.d/nvidia-devtools.list
apt-key adv --fetch-keys http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub
apt update
apt install -y --no-install-recommends nsight-systems-cli vim curl ccache

CONTAINER_PROJECT_DIR="/root/spark_rapids_dev"
CONTAINER_SPARK_HOME="${CONTAINER_PROJECT_DIR}/source/spark-3.5.6-bin-hadoop3"
CONTAINER_PATH="\$SPARK_HOME/bin:\$SPARK_HOME/sbin:\$PATH"

echo "export SPARK_HOME=${CONTAINER_SPARK_HOME}" >> /root/.bashrc
echo "export PATH=${CONTAINER_PATH}" >> /root/.bashrc