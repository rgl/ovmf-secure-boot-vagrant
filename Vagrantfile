Vagrant.configure('2') do |config|
  config.vm.box = 'ubuntu-20.04-uefi-amd64'

  config.vm.provider :libvirt do |lv, config|
    lv.memory = 4*1024
    lv.cpus = 4
    lv.cpu_mode = 'host-passthrough'
    lv.nested = true
    lv.keymap = 'pt'
    config.vm.synced_folder '.', '/vagrant', type: 'nfs'
  end

  config.vm.hostname = 'ovmf'
  config.vm.provision :shell, path: 'provision-base.sh'
  config.vm.provision :shell, path: 'provision-edk2.sh'
  config.vm.provision :shell, path: 'build-ovmf.sh', privileged: false
  config.vm.provision :shell, path: 'provision-go.sh'
  config.vm.provision :shell, path: 'provision-qmp-shell.sh', privileged: false
  config.vm.provision :shell, path: 'provision-go-uefi.sh', privileged: false
  config.vm.provision :shell, path: 'provision-sbctl.sh', privileged: false
  config.vm.provision :shell, path: 'provision-linux.sh', privileged: false
  config.vm.provision :shell, path: 'provision-u-root.sh', privileged: false
end
