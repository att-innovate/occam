# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.define :centos7 do |t|
    config.vm.hostname = "ops1.zone1.example.com"
    t.vm.synced_folder ".", "/vagrant"
    t.vm.box = "jkyle/centos7"
    t.vm.network "private_network", ip: "192.168.100.10"

    t.vm.provider "virtualbox" do |v|
      v.vm.gui = true
    end

    t.vm.provider "vmware_fusion" do |v|
      v.vm.gui = true
      v.vmx["memsize"] = "4096"
      v.vmx["numvcpus"] = "4"
    end

    config.vm.provision :ansible do |ansible|
      ansible.playbook = "playbook.yml"
      ansible.sudo = true
    end
  end
end
