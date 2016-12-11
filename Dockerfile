FROM ubuntu:latest

MAINTAINER Youcef Rahal

RUN apt-get update --fix-missing

# Install firefox (for jupyter)
RUN apt-get install -y firefox

# Install x11vnc and dependencies and set a simple password
RUN apt-get install -y x11vnc xvfb && \
    mkdir ~/.vnc && \
    x11vnc -storepasswd 1234 ~/.vnc/passwd

# Install icewm (window manager)
RUN apt-get install -y icewm
# Auto start icewm in the ~/.bashrc (if it's not running)
RUN bash -c 'echo "if ! pidof -x \"icewm\" > /dev/null; then nohup icewm &>> /var/log/icewm.log & fi" >> /root/.bashrc'

# Install extras to be able read media files
RUN apt-get install -y software-properties-common
RUN add-apt-repository multiverse
RUN apt-get update
RUN apt-get install -y gstreamer1.0-libav

# Install git because it's lightweight and it's useful to have it in the container
RUN apt-get install -y git

# Fetch and install Anaconda3 and dependencies
RUN apt-get install -y wget bzip2 && \
    wget https://repo.continuum.io/archive/Anaconda3-4.2.0-Linux-x86_64.sh -O ~/anaconda.sh && \
    /bin/bash ~/anaconda.sh -b -p /opt/anaconda3 && \
    rm ~/anaconda.sh
# Add Anaconda3 to the PATH
ENV PATH /opt/anaconda3/bin:$PATH

# Update pip
RUN pip install --upgrade pip

# Install opencv and moviepy (pillow is already installed)
RUN conda install -y -c https://conda.anaconda.org/menpo opencv3 && \
    pip install moviepy

# Install TensorFlow
RUN conda install -y -c conda-forge tensorflow
RUN conda install -y scikit-learn

# Install Keras
RUN pip install keras
# Set Keras to use Tensorflow
RUN mkdir ~/.keras && echo "{ \"image_dim_ordering\": \"tf\", \"epsilon\": 1e-07, \"backend\": \"tensorflow\", \"floatx\": \"float32\" }" >  ~/.keras/keras.json

# Run these import once so they don't happen every time the container is run
# Matplotlib needs to build the font cache
RUN python -c 'import matplotlib.pyplot as plt'
# Moviepy needs to download ffmpeg
RUN python -c 'from moviepy.editor import VideoFileClip'

# Install flask-socketio
RUN conda install -y -c conda-forge flask-socketio

# Install eventlet
RUN conda install -y -c conda-forge eventlet

# Set the working directory
WORKDIR /src

# The port where x11vnc will be running
EXPOSE 5900

# Run x11vnc on start
CMD x11vnc -create -forever -usepw
