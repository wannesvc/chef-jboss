#resource_name :ear
property :ear_file, kind_of: String, name_property: true

jboss_path = "#{node['jboss']['home']}/#{node['jboss']['installation_type']}"

load_current_value do
  if ::File.exists?("#{jboss_path}/deployments/#{ear_file}")
    if ! Dir["#{jboss_path}/deployments/#{ear_file}.*"].empty?
      :ear_file ::File.basename("#{jboss_path}/deployments/#{ear_file}")
    else
      current_value_does_not_exist!
    end
  else
    current_value_does_not_exist!
  end
end

action :deploy do
  puts "Deploying #{::File.basename(ear_file)}"
  file ::File.basename("#{jboss_path}/#{ear_file}") do
    owner 'jboss'
    group 'jboss'
    mode '0600'
    content lazy { ::File.open(ear_file).read }
  end
  while Dir["#{jboss_path}/#{ear_file}.deployed"].empty?
    if not Dir["#{jboss_path}/#{ear_file}.*"].empty?
      status = Dir["#{jboss_path}/#{ear_file}.*"].first.split['.'].last
      puts status
      raise if status == 'failed'
    end
    sleep 5
  end
end

action :undeploy do
  puts "Undeploying #{::File.basename(ear_file)}"
  file ear_file do
    :delete
  end
  while Dir["#{jboss_path}/#{ear_file}.undeployed"].empty?
    puts 'Undeploying'
    sleep 5
  end
end
