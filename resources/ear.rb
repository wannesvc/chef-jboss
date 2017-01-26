#TODO: add undeployment at version change
#TODO: add generic file getter method for http/S3

property :ear_file, kind_of: String, name_property: true
property :source_path, kind_of: String, required: true

jboss_path = "#{node['jboss']['home']}/#{node['jboss']['installation_type']}"

def get_file(src: '', dst:'')
  case src[0..4]
  when 's3://'
  when 'http:'
    puts "Downloading #{::File.basename(src)} from internet"
    remote_file dst do
      source src
    end
  else
    puts 'Already a local file'
  end
end

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
  get_file(src: "#{source_path.chomp('/')}/#{ear_file}", dst: "/tmp/#{ear_file}")
  converge_if_changed :ear_file do
    puts "Deploying #{ear_file}"
    file "#{jboss_path}/deployments/#{ear_file}" do
      owner 'jboss'
      group 'jboss'
      mode '0600'
      content lazy { ::File.open("#{source_path.chomp('/')}/#{ear_file}").read }
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
end

action :undeploy do
  puts "Undeploying #{ear_file}"
  file ear_file do
    :delete
  end
  while Dir["#{jboss_path}/deployments/#{ear_file}.undeployed"].empty?
    puts 'Undeploying'
    sleep 5
  end
end
