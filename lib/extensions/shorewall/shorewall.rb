=begin rdoc

== Overview
Install and configure Shorewall Firewall

== Usage

  shorewall do
    rule "Web/ACCEPT net $FW"
    rule "SSH/ACCEPT net $FW"
  end

** NOTE! You'd better enable SSH or you'll be locked out of your instance! **

By default this plugin installs the "one-interface" example with some tweaks.
If you wish to use your own shorewall configs simply create the directory
templates/etc/shorewall relative to your clouds.rb. Any files in that directory
will overide the plugin defaults and be compiled and placed into /etc/shorewall
on the remote machine. 

== References
=end


module PoolParty
  module Plugin
    class Shorewall < Plugin

      def before_load(o={}, &block)
        @rules = []
      end

      def loaded(o={}, &block)
        do_once do
          install
          configure
          start
        end
      end

      # def after_loaded(o={}, &block)
      # end

      def install
        has_package "shorewall-common" 
        has_package "shorewall-perl"
        has_directory "/var/lock/subsys"
      end

      def configure
        has_variable "shorewall_rules", :value => (@rules.join("\n") || "#")
        %w{interfaces policy rules zones shorewall.conf}.each do |cfg| # todo, load anything relative to the clouds.rb
          has_file :name => "/etc/shorewall/#{cfg}", :mode => "0644", :template => "etc/shorewall/#{cfg}.erb"
        end
      end

      def rule(rule)
        @rules << rule
      end

      def start
        # has_exec "/sbin/shorewall start"
        has_exec "/sbin/shorewall try /etc/shorewall"
      end

    end
  end
end

