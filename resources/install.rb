property :version, kind_of: String, name_property: true
property :install_source, kind_of: String, default: nil
property :install_destination, kind_of: String, default: '/opt'
property :install_type, kind_of: String, default: 'standalone'
property :service_user_name, kind_of: String, default: 'jboss'
property :service_user_uid, kind_of: Integer, default: 110
property :service_user_gid, kind_of: Integer, default: 110
property :service_template, kind_of: String, default: 'jboss-initd.erb'
property :service_configuration, kind_of: Hash, default: {}
property :configuration_template, kind_of: String, default: nil

action_class do
  include Jboss::Helper

  def lookup_download(version)
    {'jboss-as-7.1.1.Final' => 'http://download.jboss.org/jbossas/7.1/jboss-as-7.1.1.Final/jboss-as-7.1.1.Final.zip'
    }[version]
  end
end

action :install do
  include_recipe 'java'
  package 'unzip'

  group 'jboss' do
    gid 110
  end

  user service_user_name do
    comment 'JBoss service user'
    uid service_user_uid
    gid service_user_gid
    home home
    manage_home false
    shell '/sbin/nologin'
  end

  install_source ||= lookup_download(version) 
  archive = ::File.basename(install_source)
  home = "#{install_destination.chomp('/')}/#{archive.chomp('.zip')}"
  config_entries = {
    JBOSS_HOME: home,
    JBOSS_USER: service_user_name
  }
  unless configuration_template.nil?
    config_entries[:JBOSS_CONFIG] = configuration_template.chomp('erb')
    template "#{home}/#{install_type}/configuration/#{configuration_template.chomp('erb')}" do
      source configuration_template 
      owner service_user_name
      group service_user_name
      notifies :restart, 'Service[jboss-as]'
    end 
  end

  directory install_destination

  stage_file(src: install_source, dst: "/tmp/#{archive}")
   
  execute "Unzipping JBoss #{install_type}" do
    command "unzip /tmp/#{archive} -d #{::File.dirname(home)}"
    creates "#{home}/bin"
  end

  template '/etc/init.d/jboss-as' do
    source service_template
    mode '0755'
  end

  directory "/etc/jboss-as"

  file "/etc/jboss-as/jboss-as.conf" do
    content config_entries.map{|k,v| "#{k}=#{v}"}.join("\n")
  end

  file "#{home}/bin/standalone.sh" do
    mode '0755'
  end

  ["#{home}/standalone/data/content", 
  "#{home}/standalone/tmp", 
  "#{home}/standalone/log",
  "#{home}/standalone/deployments",
  "#{home}/standalone/configuration"].each do |dir|
    directory dir do
      recursive true
      owner service_user_name
      group service_user_name
    end
  end

  service 'jboss-as' do 
    action [:enable, :start]
    subscribes :restart, 'template[/etc/init.d/jboss-as]', :delayed
    subscribes :restart, 'file[/etc/jboss-as.conf]', :delayed
  end
end
