To run test, make sure you have run a system with energibridge installed.

Either use VMs and have Vagrant, Ansible and Virtualbox installed, or do the tests baremetal and have Docker and Podman installed.

For Docker, it is assumed to be installed rootlessly and with the Docker daemon.

For linux, there is a `setup.sh` script that sets up your shell to use energibridge. It has a trap that undoes this upon exit of the shell.

To run the test, execute: `test.sh`.

To run the baremetal networking test, make sure you have go and jq installed. Then, from the root folder:
- Run `src/network_baremetal/setup.sh`. This script should not be measured with `./energibridge`.
- In another shell, run `src/network_baremetal/test.sh`. This script can be measured with `./energibridge`.

What this does, is it starts parallel simulated 'browsing' sessions. These are essentially a list of get requests to the two servers.
There are three and these can be configured in `src/network_baremetal/traffic/session-config.json`. The sessions are assigned using round-robin.