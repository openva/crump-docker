FROM ubuntu:15.10

# Install dependencies
RUN echo "deb http://archive.ubuntu.com/ubuntu/ vivid universe" | tee -a "/etc/apt/sources.list"
RUN apt-get update && apt-get install -y \
	python \
	wget \
	zip \
	python-pip \
	git \
&& rm -rf /var/lib/apt/lists/*

# Download Crump
RUN git clone https://github.com/openva/crump.git ~/crump/

# Copy over our update script
COPY run.sh /root/run.sh
#RUN /root/run.sh

### MOVE all_records.sqlite.zip OUT OF DOCKER
### docker cp <containerId>:/file/path/within/container /host/path/target

### MOVE LOG FILES OUT OF DOCKER AND APPEND TO LOCAL LOGS
### docker cp <containerId>:/file/path/within/container /host/path/target
