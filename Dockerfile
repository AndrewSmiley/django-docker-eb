FROM ubuntu
MAINTAINER Andrew Smiley
# Update packages
RUN apt-get update -y

# Install Python Setuptools and some other fancy tools for working we this container if we choose to attach to it
RUN apt-get install -y tar git curl nano wget dialog net-tools build-essential
RUN apt-get install -y python python-dev python-distribute python-pip supervisor

# copy the contents of this directory over to the container at location /src
ADD . /src


# Add and install Python modules
#we shouldn't have to do this twice but that's how the folks over at amazon suggested.
# we'd probably be fine with just ADD . /src
ADD requirements.txt /src/requirements.txt
RUN cd /src && pip install -r /src/requirements.txt

###############################################################################################################################################################
# This is the important part. The port we are exposing needs to match the port we are binding GUNICORN too. See the supervisord.conf file for the proper conf #
###############################################################################################################################################################
EXPOSE  8002
#set the working directorly
WORKDIR /src

#basically this is the command to execute when we run the contaner. This is the default for sudo docker run for this image
CMD supervisord -c /src/supervisord.conf

