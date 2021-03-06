=begin rdoc

== Overview

  Install denyhosts sshd sentry. 

  denyhosts takes hosts that have various levels of failed logins and blocks them for a specified period of time.

  Create the file templates/denyhosts.conf.erb relative to your clouds.rb to configure.

== Notes

  The denyhosts.conf that is installed with this plugin is more lenient than
  the default denyhosts config. Because most machines installing this are in
  the cloud there is probably no way to access them if you accidentally get
  blocked from the machine. 

  In this case we are favoring protecting false-positives rather than tighter security.

== Usage

  denyhosts

== Motivation
== References
=end

PoolParty::Resources::FileResource.searchable_paths << File.dirname(__FILE__)+'/templates/'

module PoolParty
  module Resources
    class Denyhosts < Resource

      def loaded(o={}, &block)
        do_once do
          install
          configure
        end
      end

      def install
        # when installing denyhosts we first want to archive our auth.log
        # because various processes may have tried to login from our address
        # for whatever reason.
        has_exec({:name => "archive_auth_log", :command => "mv /var/log/auth.log /var/log/auth.log.orig"},
                 :not_if => "test -e /etc/init.d/denyhosts") # if denyhosts isnt already installed
        has_package "denyhosts"
        has_exec({:name => "make-denyhosts-init.d-script-executable", :command => "chmod +x /etc/init.d/denyhosts"}) # sometimes we may want to shut this off, e.g. when creating an image
        has_service "denyhosts", :enabled => true, :running => true, :supports => [:restart]
        has_exec({:name => "restart-denyhosts", :command => "/etc/init.d/denyhosts restart", :action => :nothing})
      end

      def configure
        has_file "/etc/denyhosts.conf" do
          mode "0644"
          template "denyhosts.conf.erb"
          notifies get_exec("restart-denyhosts"), :run
        end
      end

    end
  end
end

