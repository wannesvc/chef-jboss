#TODO: add undeployment at version change ?
#TODO: add generic file getter method for http/S3

property :ear_file, kind_of: String, name_property: true
property :source_path, kind_of: String, required: true

$jboss_path = "#{node['jboss']['home']}/#{node['jboss']['installation_type']}"

action_class do
  def deploy_file(src: '', dst:'')
    case src[0..3]
    when 's3:/'
    when 'http'
      puts "Downloading #{::File.basename(src)} from internet"
      remote_file dst do
        source src
        action :create_if_missing
      end
    else
      execute "Copy #{src} to /tmp" do
        command "cp -f #{src} #{dst}"
      end
    end
    file dst do
      owner 'jboss'
      group 'jboss'
    end
  end
end

load_current_value do |desired|
  if ::File.exists?("#{$jboss_path}/deployments/#{desired.ear_file}")
    case Dir["#{$jboss_path}/deployments/#{desired.ear_file}.*"].first.split('.').last
    when 'deployed'
      ear_file desired.ear_file
    when 'failed'
      current_value_does_not_exist!
    when 'isDeploying'
      ear_file desired.ear_file
    end
  else
    current_value_does_not_exist!
  end
end

action :deploy do
  converge_if_changed :ear_file do
    puts "Deploying #{ear_file}"
    deploy_file(src: "#{source_path.chomp('/')}/#{ear_file}", dst: "#{$jboss_path}/deployments/#{ear_file}")
    while Dir["#{$jboss_path}/#{ear_file}.deployed"].empty?
      if not Dir["#{$jboss_path}/#{ear_file}.*"].empty?
        status = Dir["#{$jboss_path}/#{ear_file}.*"].first.split['.'].last
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
  while Dir["#{$jboss_path}/deployments/#{ear_file}.undeployed"].empty?
    puts 'Undeploying'
    sleep 5
  end
end
