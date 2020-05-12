FROM ubuntu:18.04 AS base

MAINTAINER Brian Ball brian.ball@nrel.gov

#To run with .sh script:  ./rebuild_openstudio.sh 3.0.0 -rc2 6041b3435a
#or example command line:
#docker build . -t="docker-openstudio" --build-arg OPENSTUDIO_VERSION=3.0.0 --build-arg OPENSTUDIO_VERSION_EXT=-rc2 --build-arg OPENSTUDIO_SHA=6041b3435a

ARG OPENSTUDIO_VERSION=3.0.0
ARG OPENSTUDIO_VERSION_EXT
ARG OPENSTUDIO_SHA=2b3ac52851
ARG OS_BUNDLER_VERSION=2.1.0

ENV RUBY_VERSION=2.5.1
ENV BUNDLE_WITHOUT=native_ext

# Don't combine with above since ENV vars are not initialized until after the above call
ENV OPENSTUDIO_DOWNLOAD_FILENAME=OpenStudio-$OPENSTUDIO_VERSION$OPENSTUDIO_VERSION_EXT+$OPENSTUDIO_SHA-Linux.deb

# Install gdebi, then download and install OpenStudio, then clean up.
# gdebi handles the installation of OpenStudio's dependencies

# install locales and set to en_US.UTF-8. This is needed for running the CLI on some machines
# such as singularity.
RUN apt-get update && apt-get install -y \
        curl \
        vim \
        gdebi-core \
        ruby2.5 \
        libsqlite3-dev \
        ruby-dev \ 
        libffi-dev \ 
        build-essential \
        zlib1g-dev \
        vim \ 
        git \
	    locales \
        sudo

COPY OpenStudio-deb/$OPENSTUDIO_DOWNLOAD_FILENAME /usr/local/

RUN cd /usr/local/ \    
    && echo "Installing OpenStudio Package: ${OPENSTUDIO_DOWNLOAD_FILENAME}" \
    && gdebi -n $OPENSTUDIO_DOWNLOAD_FILENAME \
    && rm -f $OPENSTUDIO_DOWNLOAD_FILENAME \
    && rm -rf /var/lib/apt/lists/* \
    && locale-gen en_US en_US.UTF-8 \
    && dpkg-reconfigure locales


## Add RUBYLIB link for openstudio.rb
ENV RUBYLIB=/usr/local/openstudio-${OPENSTUDIO_VERSION}${OPENSTUDIO_VERSION_EXT}/Ruby
ENV ENERGYPLUS_EXE_PATH=/usr/local/openstudio-${OPENSTUDIO_VERSION}${OPENSTUDIO_VERSION_EXT}/EnergyPlus/energyplus

# The OpenStudio Gemfile contains a fixed bundler version, so you have to install and run specific to that version
RUN gem install bundler -v $OS_BUNDLER_VERSION && \
    mkdir /var/oscli && \
    cp /usr/local/openstudio-${OPENSTUDIO_VERSION}${OPENSTUDIO_VERSION_EXT}/Ruby/Gemfile /var/oscli/ && \
    cp /usr/local/openstudio-${OPENSTUDIO_VERSION}${OPENSTUDIO_VERSION_EXT}/Ruby/Gemfile.lock /var/oscli/ && \
    cp /usr/local/openstudio-${OPENSTUDIO_VERSION}${OPENSTUDIO_VERSION_EXT}/Ruby/openstudio-gems.gemspec /var/oscli/
WORKDIR /var/oscli
RUN bundle _${OS_BUNDLER_VERSION}_ install --path=gems --without=native_ext --jobs=4 --retry=3

# Configure the bootdir & confirm that openstudio is able to load the bundled gem set in /var/gemdata
VOLUME /var/simdata/openstudio
WORKDIR /var/simdata/openstudio
RUN openstudio --verbose --bundle /var/oscli/Gemfile --bundle_path /var/oscli/gems --bundle_without native_ext  openstudio_version

# May need this for syscalls that do not have ext in path
RUN ln -s /usr/local/openstudio-${OPENSTUDIO_VERSION}${OPENSTUDIO_VERSION_EXT} /usr/local/openstudio-${OPENSTUDIO_VERSION}

CMD [ "/bin/bash" ]
