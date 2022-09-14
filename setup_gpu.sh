#!/bin/sh

sudo apt -y update
sudo apt -y install apt-transport-https ca-certificates curl gnupg-agent software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt -y update
sudo apt -y install docker-ce docker-ce-cli containerd.io 
sudo apt -y install nvidia-driver-450-server nvidia-cuda-toolkit nvidia-container-toolkit ocl-icd-libopencl1 clinfo
sudo reboot
