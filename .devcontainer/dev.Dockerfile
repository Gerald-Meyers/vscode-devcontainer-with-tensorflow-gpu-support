# This base image is chosen because it has all of the basic requirements preinstalled, 
# such as python, CUDA, CUDnn and should be GPU enabled by default.
# Several tensorflow/tensorflow images are broken by default and either require significant rework to become functional, 
# or are incompatible with Windows.

# It is also possible to specify a variant using build arguments passed from devcontainer.json.
# ARG VARIANT=2.16.1-gpu
# FROM tensorflow/tensorflow:${VARIANT}

# Specify the TensorFlow image variant to use. This is a known good image that works well.
FROM tensorflow/tensorflow:2.16.1-gpu

# Update environment variable
ENV LD_LIBRARY_PATH="/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64:${LD_LIBRARY_PATH}"

COPY \
    .devcontainer/apt-packages.txt \
    /tmp/apt-packages.txt


# Longer lines are split to improve readability. Large installation groups are handled in a single RUN command to improve caching.
RUN \
    --mount=type=cache,target=/var/cache/apt \
    # Now, run the update and install packages.
    apt-get update && apt-get install -y --no-install-recommends \
        $(grep -vE '^\s*#|^\s*$' /tmp/apt-packages.txt | xargs) \
    && \
    apt-get clean \
    && \
    rm -rf /var/lib/apt/lists/* /tmp/apt-packages.txt

# Copy the requirements file and install Python dependencies
COPY \
    .devcontainer/python_requirements.txt \
    /tmp/requirements.txt

# Install Python dependencies
RUN \
    # Upgrade pip and setuptools
    python3 -m pip install --upgrade pip setuptools \
    && \
    # Install Python packages from requirements file
    python3 -m pip install -v \
        --no-cache-dir -r /tmp/requirements.txt \
    && \
    # Remove the requirements file after installation
    rm /tmp/requirements.txt

# Install gcloud CLI (example for Debian/Ubuntu). This is only necessary if you want to use Google Cloud services.
# RUN apt-get update && apt-get install -y apt-transport-https ca-certificates gnupg curl sudo \
#     && echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
#     && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - \
#     && apt-get update && apt-get install -y google-cloud-cli \
#     && apt-get clean && rm -rf /var/lib/apt/lists/*

# Create a non-root user and switch to it. Only needed if you want to avoid running as root inside the container.
# RUN \
#     useradd -m -s /bin/bash -u 1000 user \
#     && \
#     echo "user ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Switch to the new user.
# USER user

# Change the working directory to /home/user.
# WORKDIR /home/user

# Define the entry point for the container. This is used for additional initialization customization.
# VSCode overrides ENTRYPOINT by default to keep the container running. Instead, you use lifecycle scripts like postCreateCommand.
# This is kept for posterity.
# ENTRYPOINT ["/path/to/your/script.sh"]

# Filter out informational log messages from TensorFlow
# ENV TF_CPP_MIN_LOG_LEVEL=0
ENV TF_CPP_MIN_LOG_LEVEL=1

HEALTHCHECK --interval=5s --timeout=5s \
    --start-period=5s --retries=3 \
    CMD [ "curl", "-f", "http://localhost:8080/health" ]

LABEL maintainer="Gerald Meyers"
LABEL description="A tensorflow docker container that can be used for machine learning tasks."
LABEL version="0.1.0"