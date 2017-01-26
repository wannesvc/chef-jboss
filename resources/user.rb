#resource_name :user
property :username, kind_of: String, name_property: true
property :password, kind_of: String

jboss_path = "#{node['jboss']['home']}/#{node['jboss']['installation_type']}"

load_current_value do
  current = ::File.open("#{jboss_path}/configuration/mgmt-users.properties").grep(/^#{username}=/)
  if not current.empty?
    entry = current.first.split('=')
    username entry[0]
    password entry[1].chomp('\n')
  else
    current_value_does_not_exist!
  end
end

action :add do
  execute "Adding user #{username}" do
    command "#{node['jboss']['home']}/bin/add-user.sh #{username} #{password}"
    not_if { not ::File.open("#{jboss_path}/configuration/mgmt-users.properties").grep(/^#{username}=/).empty? }
  end
end

action :delete do
  puts "Deleting user #{username}"
  ::File.open("#{jboss_path}/configuration/mgmt-users.properties", 'w') do |out_file|
    ::File.foreach("#{jboss_path}/configuration/mgmt-users.properties", 'w') do |line|
      out_file.puts line unless line =~ /^username=/
    end
  end
end
