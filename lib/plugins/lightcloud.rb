=begin rdoc
  Installs tokyo tyrant, tokyo cabinet and lightcloud. 
  
  It creates a basic config.py file that should probably be updated and made "smarter"
  
  Usage:
    enable :lightcloud
=end
module PoolParty
  module Resources
    class LightCloud < Resource
      
      def loaded o={}, &block
        enable
        install_gem if o.has_key?(:install_gem)
      end
      def enable
        enable :tokyo_tyrant
        
        install_lightcloud
        start_lightcloud
      end
      
      def install_lightcloud
        has_exec "svn co http://opensource.plurk.com/svn/opensource/lightcloud_manager ~/lightcloud_manager && cd ~/lightcloud_manager"

        has_file "~/lightcloud_manager/config.py" do
          render :erb
          content <<-EOC
DATA_DIR = '~/lightcloud_manager/data'
TOKYO_SERVER_PARMS = '#bnum=1000000#fpow=13#opts=ld'

USE_MASTER = True

<% %x[/usr/bin/server-list-active internal_ip].split("\t").each_with_index do |ip, index| %>
NODES = {
    #Lookup nodes
    'lookup1_<%= index -%>': { 'id': <%= index %>, 'host': '127.0.0.1:41201', 'master': '127.0.0.1:51201' },

    #Storage nodes
    'storage1_<%= index -%>': { 'id': <%= index + 1 %>, 'host': '127.0.0.1:41201', 'master': '127.0.0.1:51201' },
<% end %>
}          
          EOC
end
      end
      
      def start_lightcloud
        has_exec "python -m manager all start"
      end
      
      def install_gem
        has_gem_package "mitchellh-lightcloud"
      end
      
    end
  end
end