=begin rdoc
  Deploy a rails application using chef_deploy
  
  Usage:
    has_rails_deploy
      to => "/var/directory"
      name => "name of repos"
    
    Sets up the filesystem structure (similar to capistrano deploy) and uses ezra's
    chef-deploy to deploy the application
=end
module PoolParty
  class Rails
    
    plugin :rails_deploy do
      
      default_options(
        :dir => "/var/www",
        :owner => "www-data"
      )
      
      def loaded(o={}, &block)
        raise "You must include the directory to deploy the rails app" unless dir?
        raise "You must include the repo to deploy the rails app" unless repo?
        
        has_directory dir
        has_directory "#{dir}/#{name}"
        has_directory "#{dir}/#{name}/shared", :owner => owner
        
        %w(config pids log).each do |d|
          has_directory "#{dir}/#{name}/shared/#{d}", :owner => owner
        end
        
        has_file "#{dir}/#{name}/shared/config/database.yml" do
          content ::File.file?(database_yml) ? open(database_yml).read : database_yml
        end
        
        # Should these be here?
        has_chef_recipe "apache2"
        has_chef_recipe "apache2::mod_rails"
        
        dopts = options.choose {|k,v| [:repo, :user].include?(k)}
        has_chef_deploy dopts.merge(:name => "#{dir}/#{name}")
        
        if shared?
          shared.each do |sh|
            next unless sh.has_key?(:file)
            to = sh.has_key?(:to) ? sh[:to] : sh[:file]
            has_symlink "#{dir}/#{name}/current/#{to}", :to => "#{dir}/#{name}/shared/#{sh[:file]}"
          end
        end
        
      end
      
    end
  end
end