# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.define :ops1 do |t|
    config.vm.hostname = "ops1.zone1.example.com"
    t.vm.synced_folder ".", "/vagrant"
    t.vm.box = "jkyle/centos-7.0-x86_64"

    t.vm.provider "virtualbox" do |v|
      v.gui = true
      v.memory = 2048
      v.cpus = 2
    end

    t.vm.provider "vmware_fusion" do |v|
      v.gui = true
      v.memory = 2048
      v.cpus = 2
      v.vmx["ethernet1.connectiontype"] = "custom"
      v.vmx["ethernet1.present"] = "TRUE"
      v.vmx["ethernet1.virtualdev"] = "e1000"
      v.vmx["ethernet1.vnet"] = "vmnet2"
    end

    config.vm.provision :ansible do |ansible|
      ansible.playbook = "ansible/vagrant.yml"
      ansible.sudo = true
    end
  end

  config.vm.define :ctrl1 do |t|
    config.vm.hostname = "ctrl1.zone1.example.com"
    config.vm.boot_timeout = 900
    t.vm.synced_folder ".", "/vagrant"
    t.vm.box = "jkyle/blank-amd64"

    t.vm.provider "vmware_fusion" do |v|
      v.gui = true
      v.memory = 2048
      v.cpus = 2

      v.vmx["bios.bootOrder"] = "ethernet1"
      v.vmx["ethernet1.address"] = "00:50:56:26:29:68"
      v.vmx["ethernet1.addressType"] = "static"
      v.vmx["ethernet1.connectionType"] = "custom"
      v.vmx["ethernet1.pciSlotNumber"] = "34"
      v.vmx["ethernet1.present"] = "TRUE"
      v.vmx["ethernet1.virtualDev"] = "e1000"
      v.vmx["ethernet1.vnet"] = "vmnet2"
    end
  end
end
