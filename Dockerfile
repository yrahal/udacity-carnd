FROM yrahal/dev-machine:latest

MAINTAINER Youcef Rahal

USER root

RUN apt-get update --fix-missing

# Install extras to be able read media files
RUN apt-get install -y software-properties-common
RUN add-apt-repository multiverse
#RUN apt-get update # TODO uncomment when VS Code fixes it.
RUN apt-get install -y gstreamer1.0-libav

# Fetch and install Anaconda3 and dependencies
RUN wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/anaconda.sh && \
    /bin/bash ~/anaconda.sh -b -p /opt/anaconda3 && \
    rm ~/anaconda.sh

# Add Anaconda3 to the PATH
ENV PATH /opt/anaconda3/bin:$PATH

# Update pip
RUN pip install --upgrade pip

RUN conda create -y -n cpu

RUN /bin/bash -c "source activate cpu && \
    conda install -y sympy scikit-learn scikit-image pillow flask-socketio plotly nb_conda pyqtgraph seaborn pandas h5py && \
    conda install -y -c menpo opencv3 && \
    conda install -y -c conda-forge eventlet ffmpeg && \
    pip install moviepy peakutils jupyterthemes && \
    pip install socketIO-client transforms3d PyQt5 && \
    conda clean -y -a && \
    source deactivate cpu"

# TODO conda is not properly cloning as it should here (files are copied instead of linked...)
RUN conda create -y -n gpu --clone cpu

RUN conda install -y -n cpu tensorflow && \
    conda clean -y -a

RUN conda install -y -n gpu tensorflow-gpu && \
    conda clean -y -a

# Install uWebSockets-0.13.0 and dependencies
RUN apt-get install -y libuv1-dev libssl-dev
RUN wget https://github.com/uWebSockets/uWebSockets/archive/v0.13.0.tar.gz -O uws.tar.gz && \
    tar xvfz uws.tar.gz && \
    cd uWebSockets-0.13.0 && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make && \
    make install && \
    cd ../../ && \
    rm -r uWebSockets-0.13.0 && \
    rm uws.tar.gz && \
    ln -s /usr/lib64/libuWS.so /usr/lib/libuWS.so

# Install cppad and ipopt and dependencies
RUN apt-get install -y cppad gfortran
RUN wget https://www.coin-or.org/download/source/Ipopt/Ipopt-3.12.7.tgz && \
    tar xvfz Ipopt-3.12.7.tgz && \
    rm Ipopt-3.12.7.tgz && \
    cd Ipopt-3.12.7 && \
    
    # BLAS
    cd ThirdParty/Blas && \
    ./get.Blas && \
    mkdir -p build && cd build && \
    ../configure --prefix=/usr/local --disable-shared --with-pic && \
    make install && \

    # Lapack
    cd ../../../ThirdParty/Lapack && \
    ./get.Lapack && \
    mkdir -p build && cd build && \
    ../configure --prefix=/usr/local --disable-shared --with-pic --with-blas="/usr/local/lib/libcoinblas.a -lgfortran" && \
    make install && \

    # ASL
    cd ../../../ThirdParty/ASL && \
    ./get.ASL && \

    # MUMPS
    cd ../../ThirdParty/Mumps && \
    ./get.Mumps && \

    # build everything
    cd ../../ && \
    ./configure --prefix=/usr/local coin_skip_warn_cxxflags=yes --with-blas="/usr/local/lib/libcoinblas.a -lgfortran" --with-lapack=/usr/local/lib/libcoinlapack.a && \
    make && \
    make test && \
    make -j1 install && \

    cd .. && \
    rm -r Ipopt-3.12.7

# Clean
RUN apt-get clean && \
    apt-get autoremove && \
    rm -r /var/lib/apt/lists/*

# Create a command to run Jupyter notebooks
RUN echo "jupyter notebook --no-browser --ip='*'" > /bin/run_jupyter.sh && chmod a+x /bin/run_jupyter.sh

# Create a command to set the jupyter theme
RUN echo "jt -T -cellw 1400 -t chesterish -fs 8 -nfs 6 -tfs 6" > /bin/jupyter_theme.sh && chmod a+x /bin/jupyter_theme.sh

# Rename orion user/group to kitt
RUN usermod -l kitt -m -d /home/kitt orion
RUN groupmod -n kitt orion

# The next commands will be run as the new user
USER kitt

# Set Keras to use Tensorflow
RUN mkdir ~/.keras && echo "{ \"image_dim_ordering\": \"tf\", \"epsilon\": 1e-07, \"backend\": \"tensorflow\", \"floatx\": \"float32\" }" >  ~/.keras/keras.json

# Set the cpu env as default
RUN echo "source activate cpu" >> ~/.bashrc

# Run these import once so they don't happen every time the container is run
# Matplotlib needs to build the font cache
RUN /bin/bash -c "source activate cpu && python -c 'import matplotlib.pyplot as plt'"
# Download ffmpeg
#RUN /bin/bash -c "source activate cpu && (echo 'import imageio'; echo 'imageio.plugins.ffmpeg.download()') | python"
#RUN (echo "import imageio"; echo "imageio.plugins.ffmpeg.download()") | python

# The port where jupyter will be running and the port the simulator will be listening on
EXPOSE 8888
EXPOSE 4567
