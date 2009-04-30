=begin rdoc
  Deploy a rails application using chef_deploy
  
  
=end
module PoolParty
  class Rails
    
    define_resource :rails_deploy_structure do
      default_options(
        :create => true,
        :to => "/var/www",
        :owner => "www-data"
      )
      
      def loaded(o={}, &block)
        
        has_directory ::File.dirname(to)
        has_directory "#{::File.dirname(to)}/#{name}"
        has_directory "#{::File.dirname(to)}/#{name}/shared", :owner => owner
        
        %w(config pids log).each do |dir|
          has_directory "#{::File.dirname(to)}/#{name}/shared/#{dir}"
        end
        
      end
    end
    
    plugin :rails_deploy do
      
      def loaded(o={}, &block)
        has_chef_deploy o, &block
        has_rails_deploy_structure o, &block
      end
      
    end
  end
end