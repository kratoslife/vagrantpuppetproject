Vagrant.configure(2) do |config|
    config.vm.network "private_network", ip: "192.168.33.10"
  config.vm.box = "ubuntu/trusty64"

  config.vm.provision :shell do |shell|
    shell.inline = "mkdir -p /etc/puppet/modules;
                    puppet module install puppetlabs-stdlib;
                    puppet module install ripienaar-concat;
                    puppet module install puppetlabs-apt;
                    puppet module install puppetlabs/postgresql;
                    puppet module install puppetlabs/vcsrepo;
                    puppet module install puppetlabs-git;
                    puppet module install arioch-redis;
                    puppet module install ajcrowe-supervisord;
                    puppet module install jfryman-nginx"
  end

  config.vm.provision "puppet" do |puppet|
        puppet.options = ["--templatedir","/vagrant/templates"]
  end

end