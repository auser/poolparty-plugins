=begin rdoc

== Overview
Install and configure Shorewall Firewall

== Usage

  shorewall do
    rule "Web/ACCEPT net $FW"
    rule "SSH/ACCEPT net $FW"
    rule "ACCEPT net:10.0.0.0/8 $FW"    # allow local EC2 traffic OR
    rule "ACCEPT net:192.168.0.0/8 $FW" # allow local class C traffic
  end

** NOTE! You need to enable SSH or you'll be locked out of your instance! **

By default this plugin installs the "one-interface" example with some tweaks.
If you wish to use your own shorewall configs simply create the directory
templates/etc/shorewall relative to your clouds.rb. Any files in that directory
will overide the plugin defaults and be compiled and placed into /etc/shorewall
on the remote machine. 

To view the created iptables run: `iptables -L`

== Motivation
You may ask, "Why do we need a firewall when EC2 already provides one?" The answer is 

* You may be deploying to a cloud provider other than EC2 (VMware, Eucalyptus,
  Slicehost, homegrown cloud etc.) and they may not have a firewall enabled
* You may be part of a large organization all sharing one EC2 account. In this
  case anyone with access to the account could accidentally open ports in the
  security group.
* You may need to log various packets for corporate compliance

== References
* http://www.shorewall.net/standalone.htm
=end

PoolParty::Resources::FileResource.searchable_paths << File.dirname(__FILE__)+'/templates/'

module PoolParty
  module Resources
    class Shorewall < Resource

      def before_load(o={}, &block)
        @rules = []
      end

      def after_loaded(o={}, &block)
        do_once do
          install
          configure
        end
      end

      def install
        has_package "shorewall-common" 
        has_package "shorewall-perl"
        has_directory "/var/lock/subsys"
      end

      def configure
        has_exec :name => "reload_shorewall_config", :command => "/sbin/shorewall try /etc/shorewall", :action => :nothing
        has_variable "shorewall_rules", (@rules.join("\n") || "#")
        %w{interfaces policy rules zones shorewall.conf}.each do |cfg| # todo, load anything relative to the clouds.rb
          has_file "/etc/shorewall/#{cfg}" do
            mode "0644"
            template "etc/shorewall/#{cfg}.erb"
            notifies get_exec("reload_shorewall_config"), :run
            requires get_exec("reload_shorewall_config")
          end
        end
        has_exec :name => "load_shorewall_first_time", :command => "echo Loading shorewall..." do
          not_if "iptables -L | grep Shorewall"
          notifies get_exec("reload_shorewall_config"), :run
          requires get_exec("reload_shorewall_config")
        end
      end

      def rule(rule)
        @rules << rule
      end

    end
  end
end
