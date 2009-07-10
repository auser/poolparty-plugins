=begin rdoc

== Overview
Install and configure Shorewall Firewall

== Usage

  shorewall do

  end

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

      def loaded(o={}, &block)
        do_once do
          install
        end
      end

      def install
        has_package "shorewall-common" 
        has_package "shorewall-perl"
      end

    end
  end
end

