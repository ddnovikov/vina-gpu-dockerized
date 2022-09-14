# vina-gpu-dockerized 

A fork of heterogeneous OpenCL implementation of AutoDock Vina with a Dockerfile and scripts that allow to run the code with little to no setups.
 
- Tested on Ubuntu 20.04 on GCP with Nvidia T4 GPU.
- Works only with OpenCL 1.2.
- For instructions on usage please visit the original repository: [Vina-GPU](https://github.com/DeltaGroupNJUPT/Vina-GPU).

# How to build and run

1. Use a machine with NVIDIA GPU card plugged in. 
2. Run `./setup_gpu.sh` - this script installs docker, nvidia drivers and OpenCL on the host machine. When done, reboot to make sure all changes are applied. After reboot, check that `nvidia-smi` and `clinfo` work and show the info on your GPU device. If something goes wrong here - I'd recommend either using a fresh machine in cloud or make sure you uninstall everything that is being installed in the script. Huge layers of installed packages with various hacks and configurations frequently lead to weird bugs in device and environment management.
3. To build Vina-GPU binary only, do `DOCKER_BUILDKIT=1 docker build --target vina-gpu -t vina .`. To build Vina-GPU library with a few convenience libraries -- do `DOCKER_BUILDKIT=1 docker build --target vina-gpu-quantori -t vina .`. Note: this is a very simple one-off container which is not intended to be used with complex toolsets. For this purpose, a more sophisticated image with user management should be created.
4. To run `docker run --gpus 1 --rm -it vina bash`. 
5. You can check the correctness of the build by running this test example `./Vina-GPU --config ./input_file_example/2bm2_config.txt`.
