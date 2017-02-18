FROM yrahal/dev-machine:latest

MAINTAINER Youcef Rahal

USER root

# Install extras to be able read media files
RUN apt-get install -y software-properties-common
RUN add-apt-repository multiverse
RUN apt-get update
RUN apt-get install -y gstreamer1.0-libav

# Clean
RUN apt-get clean

# Fetch and install Anaconda3 and dependencies
RUN wget https://repo.continuum.io/archive/Anaconda3-4.2.0-Linux-x86_64.sh -O ~/anaconda.sh && \
    /bin/bash ~/anaconda.sh -b -p /opt/anaconda3 && \
    rm ~/anaconda.sh
# Add Anaconda3 to the PATH
ENV PATH /opt/anaconda3/bin:$PATH

# Update pip
RUN pip install --upgrade pip

# Install opencv and moviepy (pillow is already installed)
# Install TensorFlow
# Install Keras
# Install flask-socketio
# Install eventlet
# Install peakutils (useful for P4)
# Install jupyter-themes
RUN conda install -y scikit-learn && \
    conda install -y -c https://conda.anaconda.org/menpo opencv3 && \
    conda install -y -c conda-forge tensorflow flask-socketio eventlet && \
    pip install moviepy peakutils jupyterthemes keras

# Create a command to run Jupyter notebooks
RUN echo "jupyter notebook --no-browser --ip='*'" > /bin/run_jupyter.sh && chmod a+x /bin/run_jupyter.sh

# Create a command to set the jupyter theme
RUN echo "jt -T -cellw 1400 -t chesterish -fs 8 -nfs 6 -tfs 6" > /bin/jupyter_theme.sh && chmod a+x /bin/jupyter_theme.sh

# Rename orion to kitt
RUN usermod -l kitt -m -d /home/kitt orion

# The next commands will be run as the new user
USER kitt

# Add Anaconda3 to the PATH
ENV PATH /opt/anaconda3/bin:$PATH

# Set Keras to use Tensorflow
RUN mkdir ~/.keras && echo "{ \"image_dim_ordering\": \"tf\", \"epsilon\": 1e-07, \"backend\": \"tensorflow\", \"floatx\": \"float32\" }" >  ~/.keras/keras.json

# Run these import once so they don't happen every time the container is run
# Matplotlib needs to build the font cache
RUN python -c 'import matplotlib.pyplot as plt'
# Download ffmpeg
RUN (echo "import imageio"; echo "imageio.plugins.ffmpeg.download()") | python

# The port where jupyter will be running
EXPOSE 8888
