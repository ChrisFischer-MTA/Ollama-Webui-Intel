# ChrisFischer-MTA
# Date: July 28, 2025
# Ollama Webui Docker Container
FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=america/los_angeles

SHELL ["/bin/bash", "-c"]

RUN apt-get update && apt-get install -y

RUN apt-get update && \
    apt install --no-install-recommends -q -y \
    software-properties-common \
    gpg-agent \
    wget \
    curl 
# Add or remove above line to invalidate the build cache

RUN wget -O- https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB \
| gpg --dearmor | tee /usr/share/keyrings/oneapi-archive-keyring.gpg > /dev/null

RUN echo "deb [signed-by=/usr/share/keyrings/oneapi-archive-keyring.gpg] https://apt.repos.intel.com/oneapi all main" | tee /etc/apt/sources.list.d/oneAPI.list

RUN add-apt-repository ppa:deadsnakes/ppa


# Base packages
RUN apt update && \
    apt install --no-install-recommends -q -y \
    software-properties-common \
    ca-certificates \
    wget \
    curl \
    ocl-icd-libopencl1 \
    intel-oneapi-base-toolkit \
    python3.11 \
    python3.11-venv

# How to update:
# Go to https://github.com/oneapi-src/level-zero/releases/ and get the current release
# Then go to https://github.com/intel/compute-runtime/releases/ and copy/paste the rest
# Intel GPU compute user-space drivers
RUN mkdir -p /tmp/gpu && \
 cd /tmp/gpu && \
 wget https://github.com/oneapi-src/level-zero/releases/download/v1.22.4/level-zero_1.22.4+u24.04_amd64.deb && \
# wget https://github.com/oneapi-src/level-zero/releases/download/v1.21.9/level-zero_1.21.9+u24.04_amd64.deb && \
 wget https://github.com/intel/intel-graphics-compiler/releases/download/v2.14.1/intel-igc-core-2_2.14.1+19448_amd64.deb && \
 wget https://github.com/intel/intel-graphics-compiler/releases/download/v2.14.1/intel-igc-opencl-2_2.14.1+19448_amd64.deb && \
 wget https://github.com/intel/compute-runtime/releases/download/25.27.34303.5/intel-ocloc-dbgsym_25.27.34303.5-0_amd64.ddeb && \
 wget https://github.com/intel/compute-runtime/releases/download/25.27.34303.5/intel-ocloc_25.27.34303.5-0_amd64.deb && \
 wget https://github.com/intel/compute-runtime/releases/download/25.27.34303.5/intel-opencl-icd-dbgsym_25.27.34303.5-0_amd64.ddeb && \
 wget https://github.com/intel/compute-runtime/releases/download/25.27.34303.5/intel-opencl-icd_25.27.34303.5-0_amd64.deb && \
 wget https://github.com/intel/compute-runtime/releases/download/25.27.34303.5/libigdgmm12_22.7.2_amd64.deb && \
 wget https://github.com/intel/compute-runtime/releases/download/25.27.34303.5/libze-intel-gpu1-dbgsym_25.27.34303.5-0_amd64.ddeb && \
 wget https://github.com/intel/compute-runtime/releases/download/25.27.34303.5/libze-intel-gpu1_25.27.34303.5-0_amd64.deb && \
 dpkg -i *.deb && \
 rm *.deb

# wget https://github.com/intel/intel-graphics-compiler/releases/download/v2.8.3/intel-igc-core-2_2.8.3+18762_amd64.deb && \
# wget https://github.com/intel/intel-graphics-compiler/releases/download/v2.8.3/intel-igc-opencl-2_2.8.3+18762_amd64.deb && \
# wget https://github.com/intel/compute-runtime/releases/download/25.09.32961.7/intel-level-zero-gpu_1.6.32961.7_amd64.deb && \
# wget https://github.com/intel/compute-runtime/releases/download/25.09.32961.7/intel-opencl-icd_25.09.32961.7_amd64.deb && \
# wget https://github.com/intel/compute-runtime/releases/download/25.09.32961.7/libigdgmm12_22.6.0_amd64.deb && \


RUN mkdir /opt/ollama

RUN cd /opt/ollama &&  python3.11 -m venv llm_env && source /opt/ollama/llm_env/bin/activate && pip install --pre --upgrade ipex-llm[cpp]

RUN apt update && \
    apt install --no-install-recommends -q -y intel-oneapi-runtime-libs


RUN mkdir /opt/ollama/llama-cpp && cd /opt/ollama/llama-cpp && ls -lah /opt/ollama/

RUN source /opt/ollama/llm_env/bin/activate && init-ollama

RUN echo "#!/bin/bash" >> /opt/ollama/start.sh
RUN echo "cd /opt/ollama" >> /opt/ollama/start.sh
RUN echo "source /opt/ollama/llm_env/bin/activate" >> /opt/ollama/start.sh
RUN echo "init-ollama"  >> /opt/ollama/start.sh
RUN echo "source /opt/intel/oneapi/setvars.sh" >> /opt/ollama/start.sh
RUN echo "/opt/ollama/ollama serve" >> /opt/ollama/start.sh
RUN chmod +x /opt/ollama/start.sh


# Install Ollama Portable Zip
#ARG IPEXLLM_RELEASE_REPO=ipex-llm/ipex-llm
#ARG IPEXLLM_RELEASE_VERSON=v2.2.0
#ARG IPEXLLM_PORTABLE_ZIP_FILENAME=ollama-ipex-llm-2.2.0-ubuntu.tgz
#RUN cd / && \
#  wget https://github.com/${IPEXLLM_RELEASE_REPO}/releases/download/${IPEXLLM_RELEASE_VERSON}/${IPEXLLM_PORTABLE_ZIP_FILENAME} && \
#  tar xvf ${IPEXLLM_PORTABLE_ZIP_FILENAME} --strip-components=1 -C / && \
#  rm ${IPEXLLM_PORTABLE_ZIP_FILENAME}

ENV OLLAMA_HOST=0.0.0.0:11434
ENV OLLAMA_NUM_GPU=999
ENV no_proxy=localhost,127.0.0.1
ENV ZES_ENABLE_SYSMAN=1
ENV SYCL_CACHE_PERSISTENT=1
#ENV OLLAMA_CONTEXT_LENGTH=16384

ENTRYPOINT ["/opt/ollama/start.sh"]
