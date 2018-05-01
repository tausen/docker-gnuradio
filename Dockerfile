FROM ubuntu:16.04

RUN apt-get update && apt-get -y install \
     python-pip \
     python-apt

RUN pip install PyBOMBS

RUN pybombs auto-config

RUN pybombs recipes add-defaults
RUN pybombs prefix init /gnuradio -a gnuradio -R gnuradio-default
RUN /bin/bash -c 'source /gnuradio/setup_env.sh && pybombs install gr-iio'

# Make startup script with commands to call when starting bash
RUN touch /opt/bash-init-script.sh
RUN echo "# If you want to run any commands when starting a container put them in this file" >> /opt/bash-init-script.sh
RUN echo "source /gnuradio/setup_env.sh" >> /opt/bash-init-script.sh
RUN chmod a+x /opt/bash-init-script.sh

# Make entry point that uses bash and calls the startup script
RUN touch /opt/docker-entry-script.sh
RUN echo "#!/bin/bash" >> /opt/docker-entry-script.sh
RUN echo "source /opt/bash-init-script.sh" >> /opt/docker-entry-script.sh
RUN echo "/bin/bash -c \"\$*\"" >> /opt/docker-entry-script.sh
RUN chmod a+x /opt/docker-entry-script.sh

RUN cd /gnuradio/src/gr-iio && \
    git remote add tausen https://github.com/tausen/gr-iio.git && \
    git fetch tausen && \
    git checkout variable_dev_names_v0.3 && \
    pybombs rebuild gr-iio

RUN adduser --disabled-password --gecos "" --uid 1000 developer
USER developer
ENV HOME /home/developer
WORKDIR /home/developer/work
ENTRYPOINT ["/opt/docker-entry-script.sh"]

