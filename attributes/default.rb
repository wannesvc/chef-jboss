default['jboss']['version'] = 'jboss-as-7.1.1.Final'
default['jboss']['home'] = "/opt/#{node['jboss']['version']}"
default['jboss']['installation_type'] = 'standalone'
default['jboss']['uid'] = 110
default['jboss']['gid'] = 110
default['jboss']['ear_files'] = []
default['jboss']['users'] = [
  { username: 'admin', password: 'testtest'}
]
default['jboss']['conf'] = {
  JBOSS_HOME: node['jboss']['home'],
  JBOSS_USER: 'jboss'
}

### configure the java cookbook to use oracle java 8
default['java']['jdk_version'] = '8'
default['java']['oracle']['accept_oracle_download_terms'] = true
default['java']['install_flavor'] = 'oracle'
