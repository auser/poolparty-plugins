=begin rdoc
  Installs edge dynomite from the git repository
  
  Usage:
    enable :dynomite
=end
module PoolParty
  module Plugin
    class Dynomite < Plugin
      
      def enable
        has_exec "install dynomite" do
          command "git clone git://github.com/cliffmoon/dynomite.git && cd dynomite && git submodule init && git submodule update && rake"
          not_if "which tcrtest"
        end
      end
      
    end
  end
end