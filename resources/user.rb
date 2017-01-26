# TODO: current value is encrypted, we need to encrypt the new value to compare them
# admin:ManagementRealm:testtest
require 'digest'

property :username, kind_of: String, name_property: true
property :password, kind_of: String

$jboss_path = "#{node['jboss']['home']}/#{node['jboss']['installation_type']}"

def delete_user(username) 
  ['domain', 'standalone'].each do |type|
    ::File.open("#{node['jboss']['home']}/#{type}/configuration/mgmt-users.properties", 'w') do |out_file|
      ::File.foreach("#{node['jboss']['home']}/#{type}/configuration/mgmt-users.properties", 'w') do |line|
        out_file.puts line unless line =~ /^username=/
      end
    end
  end
end
  
load_current_value do |desired|
  current = ::File.open("#{$jboss_path}/configuration/mgmt-users.properties").grep(/^#{username}=/)
  if not current.empty?
    entry = current.first.split('=')
    md5 = Digest::MD5.new
    md5.update("#{entry[0]}:ManagementRealm:#{desired.password}")
    enc_pass = md5.hexdigest
    username entry[0]
    if entry[1].chomp("\n") == enc_pass
      password desired.password
    else
      password '-'
    end
  else
    current_value_does_not_exist!
  end
end

action :add do
  converge_if_changed :password do
    delete_user(username)
    execute "Adding user #{username}" do
      command "#{node['jboss']['home']}/bin/add-user.sh --silent=true #{username} #{password} > /tmp/capture.log 2>&1"
      not_if { not ::File.open("#{$jboss_path}/configuration/mgmt-users.properties").grep(/^#{username}=/).empty? }
      #sensitive true
    end
  end
end

action :delete do
  puts "Deleting user #{username}"
  delete_user(username)
end
