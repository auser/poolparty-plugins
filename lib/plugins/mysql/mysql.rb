=begin rdoc
== Overview
== Notes
== Usage
== Motivation
== References
=end
PoolParty::Resources::FileResource.searchable_paths << File.dirname(__FILE__)+'/templates/'

module PoolParty
  module Resources
    class Mysql < Resource
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
        has_file "/etc/mysql/conf.d/networked.cnf" do
          content "[mysqld]\nbind-address    = 0.0.0.0"
          notifies get_exec("restart-mysql"), :run
        end
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
        has_exec(:name => "Change the root mysql password", 
                 :command => "mysqladmin -uroot #{pw_string} password #{passwd}", 
                 :not_if => "mysqladmin -uroot -p#{passwd} status", 
                 :ignore_failure => true,
                 :subscribe => [:reload, get_package("mysql-server")])
      end

    end
  end
end
