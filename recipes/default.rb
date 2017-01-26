include_recipe 'java'

directory node['jboss']['home']

group 'jboss' do
  gid 110
end

user 'jboss' do
  comment 'JBoss service user'
  uid node['jboss']['uid']
  gid node['jboss']['gid']
  home node["jboss"]["home"]
  manage_home false
  shell '/sbin/nologin'
end

if node['jboss']['zip_installer'][0..3] == 'http'
  remote_file '/tmp/jboss-as.zip' do
    source node['jboss']['zip_installer']
  end
  node.default['jboss']['zip_installer'] = '/tmp/jboss-as.zip'
end

execute 'Unzipping JBoss standalone' do
  command "unzip #{node['jboss']['zip_installer']} -d #{node['jboss']['home']}"
  creates "#{node['jboss']['home']}/bin"
end

template '/etc/init.d/jboss-as' do
  source 'jboss-initd.erb'
  mode '0755'
end

file '/etc/jboss-as/jboss-as.conf' do
  content "
JBOSS_HOME=#{node['jboss']['home']}
JBOSS_USER=jboss
"
end

file "#{node['jboss']['home']}/bin/standalone.sh" do
  mode '0755'
end

["#{node['jboss']['home']}/standalone/data/content", 
"#{node['jboss']['home']}/standalone/tmp", 
"#{node['jboss']['home']}/standalone/log",
"#{node['jboss']['home']}/standalone/deployments",
"#{node['jboss']['home']}/standalone/configuration"].each do |dir|
  directory dir do
    recursive true
    owner 'jboss'
    group 'jboss'
  end
end

service 'jboss-as' do 
  action [:enable, :start]
  subscribes :restart, 'template[/etc/init.d/jboss-as]'
  subscribes :restart, 'file[/etc/jboss-as.conf]'
  subscribes :restart, "template[#{node['jboss']['home']}/standalone/configuration/eforms.xml]"
end

node['jboss']['ear_files'].each do |ear|
  jboss_ear ear
end
