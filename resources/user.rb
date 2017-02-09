require 'digest'

property :username, kind_of: String, name_property: true
property :password, kind_of: String, required: true
property :type, kind_of: String, equal_to: [ 'admin', 'user'], default: 'admin'

action_class do
  include Jboss::Helper
end

include Jboss::Helper 

load_current_value do |desired|
  current_password = get_current_password(desired.username)
  unless current_password.empty?
    new_pass = encrypt_password(desired.username, 'ManagementRealm', desired.password)
    if current_password == new_pass
      username desired.username
      password desired.password
    else
      current_value_does_not_exist!
    end
  else
    current_value_does_not_exist!
  end
end

action :add do
  converge_if_changed :password do
    delete_user(username)
    add_user(username, password, type)
  end
end

action :delete do
  log "Deleting user #{username}"
  delete_user(username)
end
