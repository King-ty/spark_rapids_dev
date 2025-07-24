# Milestone 2: Dockerfile for Spark RAPIDS Development

# Base Image: Use a specific, versioned NVIDIA CUDA development image.
# Ubuntu 22.04 is a modern LTS, and CUDA 12.1.1 is a stable choice for recent RAPIDS versions.
FROM nvidia/cuda:12.8.0-devel-ubuntu22.04

# Set non-interactive mode for package installers
ENV DEBIAN_FRONTEND=noninteractive

# Install essential system dependencies and build tools
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    wget \
    unzip \
    software-properties-common \
    vim \
    curl \
    maven \
    # Clean up apt cache to keep image size down
    && rm -rf /var/lib/apt/lists/*

# Install Java (OpenJDK 11) and Maven for Spark/RAPIDS plugin builds
RUN apt-get update && apt-get install -y openjdk-11-jdk maven && rm -rf /var/lib/apt/lists/*
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64

# Install Miniconda for Python environment management
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh && \
    bash /tmp/miniconda.sh -b -p /opt/conda && \
    rm /tmp/miniconda.sh && \
    /opt/conda/bin/conda clean -tip

# Add conda to the PATH for all users
ENV PATH /opt/conda/bin:$PATH

# Install PySpark
RUN pip install pyspark==3.5.6

# All following commands will run as root.
# The user will be root by default.
WORKDIR /workspace

# Set up conda for the root user
RUN conda init bash

# Set a default command to keep the container running if needed,
# but it will usually be overridden by `docker run -it ... /bin/bash`
CMD ["/bin/bash"]