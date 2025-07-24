#!/bin/bash
set -e

# Navigate to the source directory
cd source

# Download and extract Spark
wget https://dlcdn.apache.org/spark/spark-3.5.6/spark-3.5.6-bin-hadoop3.tgz
tar -zxvf spark-3.5.6-bin-hadoop3.tgz

# Download RAPIDS jar
wget https://repo1.maven.org/maven2/com/nvidia/rapids-4-spark_2.12/25.06.0/rapids-4-spark_2.12-25.06.0.jar


# 只在宿主机上生效，run container会自动设置容器的环境变量
# Set environment variables in .bashrc
echo "" >> ~/.bashrc
echo "# Spark and RAPIDS environment variables" >> ~/.bashrc
echo "export SPARK_HOME=~/spark_rapids_dev/source/spark-3.5.6-bin-hadoop3" >> ~/.bashrc
echo "export PATH=\$SPARK_HOME/bin:\$SPARK_HOME/sbin:\$PATH" >> ~/.bashrc

echo "-------------------------------------------------------------------"
echo "Setup complete. Please run the following command to apply changes:"
echo "source ~/.bashrc"
echo "-------------------------------------------------------------------" 