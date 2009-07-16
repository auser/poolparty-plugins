=begin rdoc
== Overview
== Notes
== Usage
== Motivation
== References
=end

module PoolParty
  module Plugin
    class Mysql < Plugin
      dsl_methods :root_password_string,
                  :existing_root_password

      def loaded(o={}, &block)
        do_once do
        end
      end

      def master
        has_exec(:name => "restart-mysql", :command => "/etc/init.d/mysql restart", :action => :nothing)
        has_exec(:name => "reload-mysql", :command => "/etc/init.d/mysql reload", :action => :nothing)
        has_package(:name => "mysql-server")
        has_service(:name => "mysql", :requires => get_package("mysql-server"))
        has_file(:name => "/etc/mysql/conf.d/networked.cnf", :content => "[mysqld]\nbind-address    = 0.0.0.0", :calls => get_exec("restart-mysql"))
      end

      def slave
        # todo
      end

      def client
        has_package(:name => "mysql-client")
      end

      def root_password(passwd="root_password")
        root_password_string passwd
        pw_string = existing_root_password ? "-p#{existing_root_password}" : ""
        has_exec(:name => "Change the root password", 
                 :command => "mysqladmin -uroot #{pw_string} password #{passwd}", 
                 :not_if => "mysqladmin -uroot -p#{passwd} status", 
                 :subscribe => [:reload, get_package("mysql-server")])
      end

    end
  end
end
