To run test, make sure you have run a system with energibridge installed.

Either use VMs and have Vagrant, Ansible and Virtualbox installed, or do the tests baremetal and have Docker and Podman installed.

For Docker, it is assumed to be installed rootlessly and with the Docker daemon.

For linux, there is a `setup.sh` script that sets up your shell to use energibridge. It has a trap that undoes this upon exit of the shell.

To run the test, execute: `test.sh`.
