FROM linuxserver/nzbget:latest
MAINTAINER death2all110

VOLUME /scripts

# Install Git
RUN apk add --no-cache git

# remove python2, install python3 and git, and install python libraries
RUN apk update && \
  apk upgrade && \
  apk del python2 && \
  apk add --no-cache \
    python3 \
    py3-setuptools

RUN apk add --no-cache \
  libffi-dev \
  gcc \
  musl-dev \
  openssl-dev \
  ffmpeg \
  automake \
  make \
  autoconf \
  g++ \
  libtool \
  intltool 

# install pip, venv, and set up a virtual self contained python environment
RUN python3 -m pip install --user --upgrade pip && \
  pip3 install requests \
    requests-oauthlib
	
# Install nzbToMedia
RUN apk add --no-cache git
RUN git clone https://github.com/clinton-hall/nzbToMedia.git /scripts/nzbToMedia

# Create App dir for building par2cmdline
RUN mkdir -p /app

# Make and Install par2cmdline
RUN git clone https://github.com/Parchive/par2cmdline.git && \
  cd par2cmdline && \
  ./automake.sh && \
  ./configure --disable-dependency-tracking && \
  make && \
  make check && \
  make install
  
# Add local par2 files
COPY  /app/par2cmdline/par2 /usr/local/bin

# Symlink Par2 to various par2 commands
RUN ln -sf /usr/local/bin/par2 /usr/local/bin/par2create && \
 ln -sf /usr/local/bin/par2 /usr/local/bin/par2verify && \
 ln -sf /usr/local/bin/par2 /usr/local/bin/par2repair

#Set script file permissions
RUN chmod 775 -R /scripts

#Set script directory setting in NZBGet
#RUN /app/nzbget -o ScriptDir=/app/scripts,/scripts/SMA-TV,/scripts/SMA-Movie,/scripts/nzbToMedia
ONBUILD RUN sed -i 's/^ScriptDir=.*/ScriptDir=\/app\/scripts;\/scripts\/SMA-TV/;\/scripts\/SMA-Movie/;\/scripts\/nzbToMedia/' /config/nzbget.conf

#Adding Custom files
ADD init/ /etc/my_init.d/
RUN chmod -v +x /etc/my_init.d/*.sh