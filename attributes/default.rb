default['jboss']['zip_installer'] = 'http://download.jboss.org/jbossas/7.1/jboss-as-7.1.1.Final/jboss-as-7.1.1.Final.zip'
default['jboss']['home'] = "/opt/#{::File.basename(node['jboss']['zip_installer']).chomp('.zip')}"
default['jboss']['installation_type'] = 'standalone'
default['jboss']['uid'] = 110
default['jboss']['gid'] = 110
default['jboss']['ear_files'] = []

### configure the java cookbook to use oracle java 8
default['java']['jdk_version'] = '8'
default['java']['oracle']['accept_oracle_download_terms'] = true
default['java']['install_flavor'] = 'oracle'
