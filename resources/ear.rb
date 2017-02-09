#TODO: add undeployment at version change ?

property :ear_file, kind_of: String, name_property: true
property :source_path, kind_of: String, required: true
property :deploy_path, kind_of: String, required: true

action_class do
  include Jboss::Helper
end

load_current_value do |desired|
  if ::File.exists?("#{desired.deploy_path}/#{desired.ear_file}") && ! Dir["#{desired.deploy_path}/#{desired.ear_file}.*"].empty?
    case Dir["#{desired.deploy_path}/#{desired.ear_file}.*"].first.split('.').last
    when 'deployed'
      ear_file desired.ear_file
    when 'failed'
      Chef::Log.warn "Previous deploy of #{desired.ear_file} failed, cleaning up" do
        %x(rm -rf #{desired.deploy_path}/#{desired.ear_file} #{desired.deploy_path}/#{desired.ear_file}.*)
      end
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
    log "Deploying #{ear_file}"
    stage_file(src: source_path, dst: "#{deploy_path}/#{ear_file}")
    ruby_block "Waiting for deployment of #{ear_file}" do
      block do
        count = 0
        while Dir["#{deploy_path}/#{ear_file}.deployed"].empty? && count < 10
          if not Dir["#{deploy_path}/#{ear_file}.*"].empty?
log '------------------'
log  Dir["#{deploy_path}/#{ear_file}.*"]
log '------------------'
            status = Dir["#{deploy_path}/#{ear_file}.*"].first.split['.'].last
            log status
            raise if status == 'failed'
          end
          sleep 5
          count += 1
          if count == 9
            log "Timeout waiting for deployment. Is Jboss running?" do
              level :warn
            end
          end
        end
      end
    end
  end
end

action :undeploy do
  log "Undeploying #{ear_file}"
  file ear_file do
    :delete
  end
  while Dir["#{deploy_path}/#{ear_file}.undeployed"].empty?
    log 'Undeploying'
    sleep 5
  end
end
