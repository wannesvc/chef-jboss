module Jboss
  module Helper
    def stage_file(src: '', dst:'')
      case src
      when /^s3:\/\//
        log "Downloading #{::File.basename(src)} from s3"
        s3_file dst do
          remote_path src[5..-1].split('/')[1..-1].join('/')
          bucket ::File.dirname(src[5..-1])[/^.*?\//].chomp('/')
          owner 'jboss'
          group 'jboss'
        end
      when /^http[s]?:\/\//
        log "Downloading #{::File.basename(src)} from internet"
        remote_file dst do
          source src
          owner 'jboss'
          group 'jboss'
        end
      else
        log "Stage #{::File.basename(src)} locally"
        execute "Copy #{src} to /tmp" do
          command "cp -f #{src} #{dst}"
        end
      end
    end
    def delete_user(username, jboss_home) 
      ['domain', 'standalone'].each do |type|
        ::File.open("#{jboss_home}/#{type}/configuration/mgmt-users.properties", 'w') do |out_file|
          ::File.foreach("#{jboss_home}/#{type}/configuration/mgmt-users.properties", 'w') do |line|
            out_file.puts line unless line =~ /^username=/
          end
        end
      end
    end
    def add_user(username, password, type)
      execute "Adding #{type} #{username}" do
        command "#{jboss_home}/bin/add-user.sh --silent=true #{username} #{password} > /tmp/capture.log 2>&1"
        not_if { not ::File.open("#{jboss_home}/standalone/configuration/mgmt-users.properties").grep(/^#{username}=/).empty? }
        sensitive true
      end
    end
    def encrypt_password(username, realm, password)
      # password format to encrypt:
      # admin:ManagementRealm:testtest
      md5 = Digest::MD5.new
      md5.update("#{username}:#{realm}:#{password}")
      md5.hexdigest
    end
    def get_current_password(username, jboss_home)
      current = ::File.open("#{jboss_home}/standalone/configuration/mgmt-users.properties").grep(/^#{username}=/)
      if not current.empty?
        entry = current.first.split('=')
        entry[1].chomp("\n")
      else
        ''
      end
    end
  end
end
