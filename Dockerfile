# syntax=docker/dockerfile:1.4

FROM ubuntu:20.04 as compile_stage

ARG DEBIAN_FRONTEND=noninteractive
ARG WORKDIR="/htd"

RUN --mount=type=cache,id=apt-cache,target=/var/cache/apt \
    apt-get update && apt-get -y upgrade && apt-get install -y \
    apt-utils \
    unzip \
    tar \
    curl \
    xz-utils \
    build-essential \
    wget \
    git \
    python3-pip \
    ocl-icd-libopencl1 \
    opencl-headers \
    clinfo

RUN mkdir -p /etc/OpenCL/vendors && \
    echo "libnvidia-opencl.so.1" > /etc/OpenCL/vendors/nvidia.icd
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility

WORKDIR "${WORKDIR}"
RUN wget https://boostorg.jfrog.io/artifactory/main/release/1.77.0/source/boost_1_77_0.tar.bz2
RUN tar --bzip2 -xf boost_1_77_0.tar.bz2

WORKDIR "${WORKDIR}/boost_1_77_0"
RUN mkdir ${WORKDIR}/boost_1_77_0/build 
RUN cd tools/build && ./bootstrap.sh && ./b2 install --prefix=${WORKDIR}/boost_1_77_0/build
RUN ${WORKDIR}/boost_1_77_0/build/bin/b2 --build-dir=${WORKDIR}/boost_1_77_0/build toolset=gcc stage

# Download Vina-GPU and modify OPENCL version from 3.0 to 1.2 but it must be set according to the host opencl version (use `clinfo` to check this)
# RUN git clone https://github.com/quantori/Vina-GPU.git && sed -i 's/OPENCL_VERSION=-DOPENCL_3_0/OPENCL_VERSION=-DOPENCL_1_2/g' Vina-GPU/Makefile

RUN ln -s /usr/lib/x86_64-linux-gnu/libOpenCL.so.1 /usr/lib/libOpenCL.so
COPY . ${WORKDIR}/vina
WORKDIR "${WORKDIR}/vina"

# -I/usr/lib/x86_64-linux-gnu/include \

ENV LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${WORKDIR}/boost_1_77_0/stage/lib"

RUN gcc -o Vina-GPU \
        -I${WORKDIR}/boost_1_77_0 -I./lib -I./OpenCL/inc \
        ./main/main.cpp \
        -O3 ./lib/*.cpp ./OpenCL/src/wrapcl.cpp ${WORKDIR}/boost_1_77_0/libs/thread/src/pthread/thread.cpp ${WORKDIR}/boost_1_77_0/libs/thread/src/pthread/once.cpp \
        -lboost_program_options -lboost_system -lboost_filesystem -lOpenCL -lstdc++ -lm -lpthread \
        -L${WORKDIR}/boost_1_77_0/stage/lib -L/usr/lib/x86_64-linux-gnu \
        -DOPENCL_1_2 -DBUILD_KERNEL_FROM_SOURCE -DNVIDIA_PLATFORM


# test run of Vina-GPU
# RUN cd Vina-GPU && ./Vina-GPU --config ./input_file_example/2bm2_config.txt

# Install some requirements
# RUN pip install --upgrade pip
# RUN pip install pandas scipy

# # Download and Install ADFRsuite
# RUN wget https://ccsb.scripps.edu/adfr/download/1038/ -O ADFRsuite_x86_64Linux_1.0.tar.gz && \
#     tar xvzf ADFRsuite_x86_64Linux_1.0.tar.gz && \
#     cd ADFRsuite_x86_64Linux_1.0 && \
#     -y Y | ./install.sh -d /htd/ADFRsuite-1.0
    
# RUN export PATH=/htd/ADFRsuite-1.0/bin:$PATH

# # Install Open Babel. Download source code from `Sourceforge.net`
# RUN mkdir openbabel && \
#     cd openbabel && \
#     wget http://sourceforge.net/projects/openbabel/files/openbabel/2.4.0/openbabel-openbabel-2-4-0.tar.gz/download -O openbabel-openbabel-2-4-0.tar.gz && \
#     tar zxf openbabel-openbabel-2-4-0.tar.gz && \
#     mkdir build && \
#     cd build && \
#     cmake ../openbabel-openbabel-2-4-0 && \
#     make && \
#     make install

# # Install Meeko
# RUN git clone https://github.com/forlilab/Meeko && \
#     cd Meeko && \
#     pip install .
