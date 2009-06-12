module PoolParty
  class BashAliasResource
      
    plugin :bash_alias do
      dsl_methods :name, # the name of the cmd
                  :value # the value of the alias

      def loaded(opts={}, &block)        
        user opts[:user] || "root"
        has_line_in_file :file => "/root/.profile", :line => "alias #{name}='#{value}'"
      end
    end

  end
end
