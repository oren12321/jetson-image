# Jetson image tools
Tools for Nvidia Jetson image that include: image creation, kernel customization, target flashing/cloning.
This tools are using docker and based on Nvidia developer resources and on [vuquangtrong/jetson-custom-image](https://github.com/vuquangtrong/jetson-custom-image).
## Usage
Set the required parameters in `env.list`.
Build and run the docker as follows:
```
docker build -t jetson-tools .
docker run --rm --privileged --env-file env.list --volume <host_dir>:/workdir jetson-tools <required_tool> <args>
```
To view available tools, run the docker without specifying a tool.
Recommended: use main tool `create_custom_base_image_tarball.sh`.

## Comments
The packed .tbz2 file of the tegra OS should be extracted using `tar -xpf <.tbz2 file>` in order to meintain filesystem permissions.

