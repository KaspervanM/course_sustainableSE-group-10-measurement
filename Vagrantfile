Vagrant.configure("2") do |config|

  config.vm.box = "ubuntu/jammy64"
  
  config.vm.provider "virtualbox" do |vb|
    vb.memory = 4096
    vb.cpus = 4
  end
  
  config.trigger.before :up do |trigger|
    trigger.warn = "removing standard dhcp host interface if existent"
    trigger.run = { inline: "bash -c 'if [ $( VBoxManage list dhcpservers | grep -c vboxnet0 ) != \"0\" ]; then VBoxManage dhcpserver remove --netname HostInterfaceNetworking-vboxnet0; fi'" }
  end

  config.vm.define "docker_vm" do |docker|
    docker.vm.hostname = "docker-vm"
    docker.vm.network "private_network", ip: "192.168.56.10"
  end

  config.vm.define "podman_vm" do |podman|
    podman.vm.hostname = "podman-vm"
    podman.vm.network "private_network", ip: "192.168.56.11"
  end

  config.vm.provision "ansible" do |ansible|
    ansible.compatibility_mode = "2.0"
    ansible.playbook = "ansible/main.yml"
    ansible.groups = {
    "docker_group"  => ["docker_vm"],
    "podman_group" => ["podman_vm"]
    }
  end
end
