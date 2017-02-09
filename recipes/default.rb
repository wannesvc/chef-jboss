#jboss_install node['jboss']['version']

node['jboss']['ear_files'].each do |ear|
  jboss_ear ear.split('/').last do
    source_path ear 
    deploy_path "#{node['jboss']['home']}/#{node['jboss']['installation_type']}/deployments"
  end
end
node['jboss']['users'].each do |user|
  jboss_user user[:username] do
    password user[:password]
  end
end
