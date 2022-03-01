# Jetson docker sample
A sample docker file with base l4t and multimedia-api.
## Cross platform build/run
Install required tools:
```
sudo apt-get install qemu binfmt-support qemu-user-static
```
Execute registration scripts:
```
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes --credential yes
```
Build and run the container:
```
docker buildx build -t sample-docker .
docker run --rm -it sample-docker
```
