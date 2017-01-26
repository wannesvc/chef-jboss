resource_name :ear
property :file, kind_of: String, name_property: true

#load_current_value do
#  if ::File.exists?("#{node['jboss']['home']}/#{node['jboss']['installation_type']}/deployments/#{file}")
#    if ! Dir["#{node['jboss']['home']}/#{node['jboss']['installation_type']}/deployments/#{file}.*"].empty?
#      Dir["#{node['jboss']['home']}/#{node['jboss']['installation_type']}/deployments/#{file}.*"].first.split('.').last
#    else
#      return 'not_deployed'
#    end
#  else
#    return 'not_deployed'
#  end
#end

action :deploy do
  puts "Deploying #{::File.basename(file)}"
  file ::File.basename("#{node['jboss']['home']}/#{node['jboss']['installation_type']}/#{file}") do
    owner 'jboss'
    group 'jboss'
    mode '0600'
    content lazy { ::File.open(file).read }
  end
  while Dir["#{node['jboss']['home']}/#{node['jboss']['installation_type']}/#{file}.deployed"].empty?
    status = Dir["#{node['jboss']['home']}/#{node['jboss']['installation_type']}/#{file}.*"].first.split['.'].last
    puts status
    raise if status == 'failed'
    sleep 5
  end
end

action :undeploy do
  puts "Undeploying #{::File.basename(file)}"
  file file do
    :delete
  end
  while Dir["#{node['jboss']['home']}/#{node['jboss']['installation_type']}/#{file}.undeployed"].empty?
    puts 'Undeploying'
    sleep 5
  end
end
