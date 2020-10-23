FROM nvidia/cuda:11.1-cudnn8-devel-ubuntu18.04

LABEL maintainers="Alex Basok <alessaniel@gmail.com>"

ENV OPENCV_VERSION="4.4.0"

RUN apt clean && \
    apt update && \
    apt install --no-install-recommends -y \
        build-essential \
        cmake \
        git \
        wget \
        unzip \
        yasm \
        pkg-config \
        libswscale-dev \
        libtbb2 \
        libtbb-dev \
        libjpeg-dev \
        libpng-dev \
        libtiff-dev \
        libavformat-dev \
        libpq-dev \
        python3-pip \
        python3 \
        python3-dev \
        gdal-bin \
        libgdal-dev \
        python-gdal \
        python3-gdal \
        libsm6 \
        libxext6 \
        libxrender-dev \
        && apt autoremove -y \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install --no-cache-dir virtualenv && \
 virtualenv --python=/usr/bin/python3 /venv && \
  /venv/bin/pip install --upgrade pip && \
  /venv/bin/pip install numpy

RUN mkdir /tmp/opencv && \
    cd /tmp/opencv && \
    wget https://github.com/opencv/opencv/archive/${OPENCV_VERSION}.zip && \
    unzip ${OPENCV_VERSION}.zip && rm ${OPENCV_VERSION}.zip && \
    mv opencv-${OPENCV_VERSION} OpenCV && \
    cd OpenCV && \
    wget https://github.com/opencv/opencv_contrib/archive/${OPENCV_VERSION}.zip && \
    unzip ${OPENCV_VERSION}.zip && \
    mkdir build && \
    cd build && \
    cmake \
      -D WITH_TBB=ON \
      -D CMAKE_BUILD_TYPE=RELEASE \
      -D BUILD_EXAMPLES=OFF \
      -D WITH_FFMPEG=ON \
      -D WITH_V4L=ON \
      -D WITH_OPENGL=ON \
      -D WITH_CUDA=ON \
      -D WITH_CUDNN=ON \
      -D ENABLE_FAST_MATH=1 \
	  -D CUDA_FAST_MATH=1 \
      -D WITH_CUBLAS=ON \
      -D WITH_CUFFT=ON \
      -D WITH_EIGEN=ON \
      -D EIGEN_INCLUDE_vPATH=/usr/include/eigen3 \
      -D OPENCV_EXTRA_MODULES_PATH=../opencv_contrib-${OPENCV_VERSION}/modules/ \
      -D OPENCV_ENABLE_NONFREE=ON \
      -D CMAKE_INSTALL_PREFIX=$(/venv/bin/python3 -c "import sys; print(sys.prefix)") \
      -D PYTHON_EXECUTABLE=$(which python3) \
      -D PYTHON_INCLUDE_DIR=$(/venv/bin/python3 -c "from distutils.sysconfig import get_python_inc; print(get_python_inc())") \
      -D PYTHON_PACKAGES_PATH=$(/venv/bin/python3 -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())") \
      .. && \
    make all -j$(nproc) && \
    make install && \
    ldconfig && \
    echo "/usr/local/lib" > /etc/ld.so.conf.d/opencv.conf && \
    cd && rm -rf /tmp/opencv