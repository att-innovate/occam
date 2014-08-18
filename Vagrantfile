# -*- mode: ruby -*-
# vi: set ft=ruby :
Vagrant.configure("2") do |config|

  config.vm.boot_timeout = 3600
  config.vm.synced_folder ".", "/vagrant", disabled: true

  config.vm.define :ops1 do |t|
    # ops1 node
    t.vm.box = "doctorjnupe/precise64_dhcpclient_on_eth7"
    t.vm.hostname = "ops1.pao10.tfoundry.com"
    t.vm.synced_folder ".", "/occam", disabled: false
    t.vm.provider "virtualbox" do |prov|
      prov.gui = true
      prov.memory = 2048
      prov.cpus = 2
      prov.customize ["modifyvm", :id, "--natpf1", "delete", "ssh" ]
      # management network:
      prov.customize ["modifyvm", :id, "--nic1", "hostonly", "--hostonlyadapter1", "vboxnet0" ]
      # unused interfaces:
      prov.customize ["modifyvm", :id, "--nic2", "hostonly", "--hostonlyadapter2", "vboxnet0", "--cableconnected2", "off" ]
      prov.customize ["modifyvm", :id, "--nic3", "hostonly", "--hostonlyadapter3", "vboxnet0", "--cableconnected3", "off" ]
      prov.customize ["modifyvm", :id, "--nic4", "hostonly", "--hostonlyadapter4", "vboxnet0", "--cableconnected4", "off" ]
      prov.customize ["modifyvm", :id, "--nic5", "hostonly", "--hostonlyadapter5", "vboxnet0", "--cableconnected5", "off" ]
      # private network:
      prov.customize ["modifyvm", :id, "--nic6", "intnet", "--intnet6", "private" ]
      # unused interface:
      prov.customize ["modifyvm", :id, "--nic7", "intnet", "--intnet7", "private", "--cableconnected7", "off" ]
      # NAT interface required by Vagrant:
      prov.customize ["modifyvm", :id, "--nic8", "nat", "--natnet8", "10.99.2/24", "--natpf8", "ssh,tcp,127.0.0.1,2222,,22" ]
    end
    # set up eth0 interface with 192.168.3.10/24 address after first boot
    t.vm.provision "shell", inline: "echo -e '\nauto eth0\niface eth0 inet static\n  address 192.168.3.10\n  netmask 255.255.255.0\n  dns-nameservers 8.8.8.8\n' >> /etc/network/interfaces; ifup eth0"
  end

  config.vm.define :ctrl1 do |t|
    # controller node
    t.vm.box = "steigr/pxe"
    t.vm.provider "virtualbox" do |prov|
      prov.gui = true
      prov.memory = 2048
      prov.cpus = 2
      prov.customize ["modifyvm", :id, "--natpf1", "delete", "ssh" ]
      # management network:
      prov.customize ["modifyvm", :id, "--nic1", "hostonly", "--hostonlyadapter1", "vboxnet0", "--macaddress1", "b8ca3a5bc160" ]
      # public network:
      prov.customize ["modifyvm", :id, "--nic2", "hostonly", "--hostonlyadapter2", "vboxnet1", "--nicpromisc2", "allow-all" ]
      # unused interfaces:
      prov.customize ["modifyvm", :id, "--nic3", "hostonly", "--hostonlyadapter3", "vboxnet0", "--cableconnected3", "off" ]
      prov.customize ["modifyvm", :id, "--nic4", "hostonly", "--hostonlyadapter4", "vboxnet0", "--cableconnected4", "off" ]
      prov.customize ["modifyvm", :id, "--nic5", "hostonly", "--hostonlyadapter5", "vboxnet0", "--cableconnected5", "off" ]
      # private network:
      prov.customize ["modifyvm", :id, "--nic6", "intnet", "--intnet6", "private" ]
      # unused interface:
      prov.customize ["modifyvm", :id, "--nic7", "intnet", "--intnet7", "private", "--cableconnected7", "off" ]
      # NAT interface required by Vagrant:
      prov.customize ["modifyvm", :id, "--nic8", "nat", "--natnet8", "10.99.3/24", "--natpf8", "ssh,tcp,127.0.0.1,2223,,22" ]
      # attaching IPXE floppy image:
      prov.customize ["storageattach", :id, "--storagectl", "Floppy Controller", "--type", "fdd", "--device", "0", "--medium", "PATH_TO_VIRTUALDISKS_DIRECTORY/ctrl1_ipxe.dsk"]
      # attaching disks, because steigr/pxe box have no disks by default:
      prov.customize ["storageattach", :id, "--storagectl", "SATA Controller", "--port", "0", "--type", "hdd", "--medium", "PATH_TO_VIRTUALDISKS_DIRECTORY/ctrl1_disk1.vdi" ]
    end
  end
  
  config.vm.define :comp1 do |t|
    # compute node
    t.vm.box = "steigr/pxe"
    t.vm.provider "virtualbox" do |prov|
      prov.gui = true
      prov.memory = 2048
      prov.cpus = 2
      prov.customize ["modifyvm", :id, "--natpf1", "delete", "ssh" ]
      # management network:
      prov.customize ["modifyvm", :id, "--nic1", "hostonly", "--hostonlyadapter1", "vboxnet0", "--macaddress1", "b8ca3a5bbe54" ]
      # unused interfaces:
      prov.customize ["modifyvm", :id, "--nic2", "hostonly", "--hostonlyadapter2", "vboxnet0", "--cableconnected2", "off" ]
      prov.customize ["modifyvm", :id, "--nic3", "hostonly", "--hostonlyadapter3", "vboxnet0", "--cableconnected3", "off" ]
      prov.customize ["modifyvm", :id, "--nic4", "hostonly", "--hostonlyadapter4", "vboxnet0", "--cableconnected4", "off" ]
      prov.customize ["modifyvm", :id, "--nic5", "hostonly", "--hostonlyadapter5", "vboxnet0", "--cableconnected5", "off" ]
      # private network:
      prov.customize ["modifyvm", :id, "--nic6", "intnet", "--intnet6", "private" ]
      # unused interface:
      prov.customize ["modifyvm", :id, "--nic7", "intnet", "--intnet7", "private", "--cableconnected7", "off" ]
      # NAT interface required by Vagrant:
      prov.customize ["modifyvm", :id, "--nic8", "nat", "--natnet8", "10.99.4/24", "--natpf8", "ssh,tcp,127.0.0.1,2224,,22" ]
      # attaching IPXE floppy image:
      prov.customize ["storageattach", :id, "--storagectl", "Floppy Controller", "--type", "fdd", "--device", "0", "--medium", "PATH_TO_VIRTUALDISKS_DIRECTORY/comp1_ipxe.dsk"]
      # attaching disks, because steigr/pxe box have no disks by default: 
      prov.customize ["storageattach", :id, "--storagectl", "SATA Controller", "--port", "0", "--type", "hdd", "--medium", "PATH_TO_VIRTUALDISKS_DIRECTORY/comp1_disk1.vdi" ]
    end
  end

  config.vm.define :comp2 do |t|
    # compute node
    t.vm.box = "steigr/pxe"
    t.vm.provider "virtualbox" do |prov|
      prov.gui = true
      prov.memory = 2048
      prov.cpus = 2
      prov.customize ["modifyvm", :id, "--natpf1", "delete", "ssh" ]
      # management network:
      prov.customize ["modifyvm", :id, "--nic1", "hostonly", "--hostonlyadapter1", "vboxnet0", "--macaddress1", "b8ca3a5bbe74" ]
      # unused interfaces:
      prov.customize ["modifyvm", :id, "--nic2", "hostonly", "--hostonlyadapter2", "vboxnet0", "--cableconnected2", "off" ]
      prov.customize ["modifyvm", :id, "--nic3", "hostonly", "--hostonlyadapter3", "vboxnet0", "--cableconnected3", "off" ]
      prov.customize ["modifyvm", :id, "--nic4", "hostonly", "--hostonlyadapter4", "vboxnet0", "--cableconnected4", "off" ]
      prov.customize ["modifyvm", :id, "--nic5", "hostonly", "--hostonlyadapter5", "vboxnet0", "--cableconnected5", "off" ]
      # private network:
      prov.customize ["modifyvm", :id, "--nic6", "intnet", "--intnet6", "private" ]
      # unused interface:
      prov.customize ["modifyvm", :id, "--nic7", "intnet", "--intnet7", "private", "--cableconnected7", "off" ]
      # NAT interface required by Vagrant:
      prov.customize ["modifyvm", :id, "--nic8", "nat", "--natnet8", "10.99.5/24", "--natpf8", "ssh,tcp,127.0.0.1,2225,,22" ]
      # attaching IPXE floppy image:
      prov.customize ["storageattach", :id, "--storagectl", "Floppy Controller", "--type", "fdd", "--device", "0", "--medium", "PATH_TO_VIRTUALDISKS_DIRECTORY/comp2_ipxe.dsk"]
      # attaching disks, because steigr/pxe box have no disks by default:
      prov.customize ["storageattach", :id, "--storagectl", "SATA Controller", "--port", "0", "--type", "hdd", "--medium", "PATH_TO_VIRTUALDISKS_DIRECTORY/comp2_disk1.vdi" ]
    end
  end

  config.vm.define :comp3 do |t|
    # compute node
    t.vm.box = "steigr/pxe"
    t.vm.provider "virtualbox" do |prov|
      prov.gui = true
      prov.memory = 2048
      prov.cpus = 2
      prov.customize ["modifyvm", :id, "--natpf1", "delete", "ssh" ]
      # management network:
      prov.customize ["modifyvm", :id, "--nic1", "hostonly", "--hostonlyadapter1", "vboxnet0", "--macaddress1", "b8ca3a5bbe75" ]
      # unused interfaces:
      prov.customize ["modifyvm", :id, "--nic2", "hostonly", "--hostonlyadapter2", "vboxnet0", "--cableconnected2", "off" ]
      prov.customize ["modifyvm", :id, "--nic3", "hostonly", "--hostonlyadapter3", "vboxnet0", "--cableconnected3", "off" ]
      prov.customize ["modifyvm", :id, "--nic4", "hostonly", "--hostonlyadapter4", "vboxnet0", "--cableconnected4", "off" ]
      prov.customize ["modifyvm", :id, "--nic5", "hostonly", "--hostonlyadapter5", "vboxnet0", "--cableconnected5", "off" ]
      # private network:
      prov.customize ["modifyvm", :id, "--nic6", "intnet", "--intnet6", "private" ]
      # unused interface:
      prov.customize ["modifyvm", :id, "--nic7", "intnet", "--intnet7", "private", "--cableconnected7", "off" ]
      # NAT interface required by Vagrant:
      prov.customize ["modifyvm", :id, "--nic8", "nat", "--natnet8", "10.99.6/24", "--natpf8", "ssh,tcp,127.0.0.1,2226,,22" ]
      # attaching IPXE floppy image:
      prov.customize ["storageattach", :id, "--storagectl", "Floppy Controller", "--type", "fdd", "--device", "0", "--medium", "PATH_TO_VIRTUALDISKS_DIRECTORY/comp3_ipxe.dsk"]
      # attaching disks, because steigr/pxe box have no disks by default:
      prov.customize ["storageattach", :id, "--storagectl", "SATA Controller", "--port", "0", "--type", "hdd", "--medium", "PATH_TO_VIRTUALDISKS_DIRECTORY/comp3_disk1.vdi" ]
    end
  end

  config.vm.define :openam do |t|
    t.vm.box = "hashicorp/precise64"
    t.vm.hostname = "openam.tfoundry.com"
    t.vm.network :private_network, ip: "192.168.20.13"
  end

end
