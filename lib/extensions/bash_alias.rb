module PoolParty
  module Plugin
    class BaseAlias < Plugin
      dsl_methods :name, # the name of the cmd
                  :value # the value of the alias

      def before_load(o={}, &block)
        user opts[:user] || "root"
        has_line_in_file :file => "/root/.profile", :line => "alias #{name}='#{value}'"
      end
    end
  end
end
