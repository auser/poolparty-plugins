=begin rdoc
== Overview
== Notes
== Usage
== References
=end

module PoolParty
  module Plugin
    class Database < Plugin

    def loaded(o={}, &block)
      # do_once do
      #   create_database(name) if name
      # end
    end

    def create_database(name)
      self.name name
      has_exec(:name => "create-#{name}-database", :command => "/usr/bin/mysqladmin #{permissions_string} create #{name}") do
        # not_if "/usr/bin/mysqlshow #{permissions_string} #{name} | grep -q #{name}"
        not_if "/usr/bin/mysqlshow #{permissions_string} | grep -q #{name}"
      end
    end

    # ideally you could just pass in the cloud, but thats so tricky
    # ugly, but fine for now
    def grant_permissions_on_cloud_with_keypair_for_user(keypair, user, password)
      instances = cloud.remote_base.describe_instances.select_with_hash(:key_name => keypair) 
      hostnames = instances.collect{|i| i.private_dns_name}
      hostnames.each do |host|
        grant_permissions_on_host_for_user(host, user, password)
      end
    end

    def grant_permissions_on_host_for_user(host, user, password)
      has_exec(:name => "create-#{name}-user-#{user}-#{host}", :command => %Q{/usr/bin/mysql #{permissions_string} -e 'grant all privileges on #{name}.* to \\"#{user}\\"@\\"#{host}\\" identified by \\"#{password}\\"'}) do
        not_if %Q{mysql #{permissions_string} -e 'use mysql;select User,Host from user where User=\\"#{user}\\" AND Host=\\"#{host}\\"';}
      end
    end

    def permissions_string
      if parent && parent.root_password_string
        "-uroot -p#{parent.root_password_string}"
      else
        ""
      end
    end

    end
  end
end

