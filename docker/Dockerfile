FROM ubuntu:20.04

# Install dependencies
RUN apt update -y
#RUN apt install -y  build-essential g++ git inetutils-tools nano jq
RUN DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt install -y autoconf automake build-essential ccache cmake cpufrequtils doxygen ethtool g++ git inetutils-tools libboost-all-dev libncurses5 libncurses5-dev libusb-1.0-0 libusb-1.0-0-dev libusb-dev python3-dev python3-mako python3-numpy python3-requests python3-scipy python3-setuptools python3-ruamel.yaml nano jq

# Compile and install USRP drivers
RUN git clone https://github.com/j0lama/uhd.git
WORKDIR uhd/
RUN git checkout UHD-4.3
WORKDIR host/
RUN mkdir build/
WORKDIR build/
RUN cmake ../
RUN make -j$(nproc)
RUN make install
RUN ldconfig

# Install UHD drivers
#RUN DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt install -y libuhd-dev uhd-host
#RUN ldconfig

# Download USRP images
RUN uhd_images_downloader
ENV UHD_IMAGES_DIR="/usr/local/share/uhd/images"

# Copy tools
WORKDIR examples/
RUN mkdir logs/
COPY tools/ .

# Compile consumer
RUN gcc consumer.c -o consumer