=begin rdoc
== Development Gem

Deploy a and install a gem developed locally. This is useful when you are
developing an internal or forked gem and you want to deploy it to your cloud


== Usage

  has_development_gem_package('jetty-rack', 
                              :from => "~/path/to/my/site", 
                              :git_pull_first => true)  # git pull from before sending to server

=end

module PoolParty
  module Resources
    class DevelopmentGem < Resource
 
      dsl_methods :name,            # Name of the gem
                  :from,            # The *local* path to the src of the gem being deployed
                  :conflicts,       # an array of strings specifying gems this conflicts with
                  :jruby,           # use jruby?
                  :bin,             # the binary cmd used to manage gems
                  :install_cmd,     # the full cmd used to install the gems
                  :build_gem_task,  # the task used to _build_ the gem
                  :to               # where to put the gem to build it

      default_options(
        :build_gem_task => "gem",
        :conflicts      => []
      )

      def loaded(opts={}, &block)        
        bin            opts[:bin] ? opts[:bin] : opts[:jruby] ? "jruby -S gem" : "gem"
        install_cmd    opts[:install_cmd] || "#{bin} install pkg/*.gem --no-rdoc --no-ri"
        to             opts[:to] ? opts[:to] : "/usr/local/src/#{name}"

        has_deploy_directory(name + '-src', dsl_options)
        [name, conflicts].flatten.compact.each {|c| remove_existing_gem(c)} # remove any gems that might conflict
        add_gem_building
        add_gem_installation
      end

      def remove_existing_gem(existing_name)
        has_exec("rm-existing-gem-#{existing_name}",
            :command => "#{bin} uninstall #{existing_name} --all",
            :only_if => "#{bin} list --local #{existing_name} | grep ^#{existing_name}[[:space:]]")
      end

      def add_gem_building
        has_exec("build-development-gem-#{name}",
          :command => "cd #{gem_root} && rake #{build_gem_task}")
      end

      def add_gem_installation
        has_exec("install-development-gem-#{name}",
          :requires => get_exec("build-development-gem-#{name}"),
          :command => "cd #{gem_root} && #{install_cmd}")
      end

      def gem_root
        to
      end

    end

  end
end
