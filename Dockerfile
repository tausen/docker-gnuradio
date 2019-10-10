FROM ubuntu:18.04

# Use sensible apt mirrors
ADD sources.list /etc/apt/sources.list

# Some PyBOMBS/gnuradio dependencies that aren't resolved automatically
RUN apt-get update && apt-get -y install sudo python3-pip
RUN apt-get update && apt-get -y install \
    gir1.2-gtk-3.0 \
    libgtk-3-0 \
    libpangocairo-1.0-0 \
    python-gi-cairo \
    python-gtk2 \
    python-mako \
    python-wxgtk3.0 \
    python-wxgtk3.0 \
    python3-gi-cairo \
    python3-mako \
    python3-yaml \
    python-yaml \
    python-six \
    python3-six \
    libcppunit-dev \
    python-cheetah \
    python-lxml \
    python3-lxml \
    python-numpy \
    python-qt4 \
    python-pyqt5 \
    python-setuptools \
    python3-setuptools

# Install tzdata - is a dependency that will fail to install later on
ADD tzdata.sh /tzdata.sh
RUN /tzdata.sh

# Install and prepare specific PyBOMBS version
RUN pip3 install PyBOMBS==2.3.3
RUN pybombs auto-config
RUN pybombs recipes add gr-recipes git+https://github.com/gnuradio/gr-recipes.git
RUN pybombs recipes add gr-etcetera git+https://github.com/gnuradio/gr-etcetera.git

# Install specific gnuradio version
RUN /bin/bash -c ' \
    pybombs prefix init /gnuradio'
RUN /bin/bash -c 'source /gnuradio/setup_env.sh && \
    pybombs config --package gnuradio gitrev 813412a1d0 && \
    pybombs install gnuradio'

# Install specific gr-iio version
RUN /bin/bash -c 'source /gnuradio/setup_env.sh && \
    pybombs fetch gr-iio && \
    cd /gnuradio/src/gr-iio && \
    git checkout 8d180d6c6 && \
    pybombs install gr-iio'

# TODO: rebase variable_dev_names to upgrade-3.8 branch - requires changes
# RUN cd /gnuradio/src/gr-iio && \
#     git remote add tausen https://github.com/tausen/gr-iio.git && \
#     git fetch tausen && \
#     git checkout 5883d004f8a6e376748b17cd5b0841d3eb7c7a17 && \
#     pybombs rebuild gr-iio

# Install some additional gnuradio components
# TODO: do not seem to be compatible with gnuradio 3.8
# RUN /bin/bash -c 'source /gnuradio/setup_env.sh && \
#     pybombs install gr-ccsds'
# RUN /bin/bash -c 'source /gnuradio/setup_env.sh && \
#     pybombs install gr-pyqt'
RUN /bin/bash -c 'source /gnuradio/setup_env.sh && \
    pybombs install inspectrum'

# Squelch gnuradio warning about missing xterm
RUN apt-get update && apt-get -y install \
    xterm

# Fix xterm_executable in gnuradio configuration
RUN sed -i 's/xterm_executable.*/xterm_executable = \/usr\/bin\/xterm/' /gnuradio/etc/gnuradio/conf.d/grc.conf

# Download UHD USRP images
RUN /gnuradio/lib/uhd/utils/uhd_images_downloader.py

# gr_filter_design dependencies
RUN apt-get update && apt-get -y install \
    python-scipy \
    python-qwt5-qt4

# Install some utils and editors for use with embedded Python blocks
RUN apt-get update && \
    apt-get -y install xdg-utils emacs gedit nano vim curl

# Make startup script with commands to call when starting bash
RUN touch /opt/bash-init-script.sh
RUN echo "# If you want to run any commands when starting a container put them in this file" >> /opt/bash-init-script.sh
RUN echo "source /gnuradio/setup_env.sh" >> /opt/bash-init-script.sh
RUN echo "export PYTHONPATH=$PYTHONPATH/gnuradio/lib/python3/dist-packages:/gnuradio/lib/python3.6/dist-packages:/gnuradio/lib/python2.7/dist-packages:" >> /opt/bash-init-script.sh
RUN chmod a+x /opt/bash-init-script.sh

# Make entry point that uses bash and calls the startup script
RUN touch /opt/docker-entry-script.sh
RUN echo "#!/bin/bash" >> /opt/docker-entry-script.sh
RUN echo "source /opt/bash-init-script.sh" >> /opt/docker-entry-script.sh
RUN echo "/bin/bash -c \"\$*\"" >> /opt/docker-entry-script.sh
RUN chmod a+x /opt/docker-entry-script.sh

ENV QT_X11_NO_MITSHM 1

# Add user
RUN adduser --disabled-password --gecos "" --uid 1000 developer
USER developer
ENV HOME /home/developer
WORKDIR /home/developer/work
ENTRYPOINT ["/opt/docker-entry-script.sh"]

# Set default editor to gedit, ensure gnuradio also uses it
RUN echo 'SELECTED_EDITOR=/usr/bin/gedit' > /home/developer/.selected_editor
RUN mkdir -p ~/.local/share/applications
RUN mkdir -p ~/.config
RUN xdg-mime default gedit.desktop text/x-python
