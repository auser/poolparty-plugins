=begin rdoc

== Convenience Helpers

Adds a few handy packages and aliases for developing poolparty instances.

== Usage

    has_convenience_helpers

== Examples

    $ inspect-poolparty-recipes # => will vim the poolparty chef recipe file
    $ cd-cookbooks              # => cd into the poolparty cookbooks directory
    $ tree                      # => show the directory structure as a nice tree
    /var/poolparty/dr_configure/chef/cookbooks/poolparty# tree
    .
    |-- attributes
    |   `-- poolparty.rb
    |-- recipes
    |   `-- default.rb
    `-- templates
        `-- default
            |-- etc
            |   |-- jvm.erb
            |   `-- motd.erb
            |-- home
            |   `-- hadoop
            |       `-- ssh
            |           `-- hadoop_id_rsa.erb
            `-- usr
                `-- local
                    `-- hadoop
                        `-- conf
                            |-- hadoop-env.sh.erb
                            `-- hadoop-site.xml.erb

=end

module PoolParty
  module Plugin
    class ConvenienceHelpers < Plugin
      def before_load(o={}, &block)
        add_packages
        add_aliases
        add_binaries
        add_profile_updates
      end

      def add_packages
        has_package "curl"
        has_package "tree"
        has_package "screen"

        case cloud.os
        when "centos"
          has_package "ruby-irb"
        else
          has_package "irb"
          has_package "vim-nox"
        end
      end

      def add_aliases
        has_bash_alias :name => "inspect-poolparty-recipes", :value => "vi /var/poolparty/dr_configure/chef/cookbooks/poolparty/recipes/default.rb"
        has_bash_alias :name => "cd-cookbooks", :value => "pushd /var/poolparty/dr_configure/chef/cookbooks/poolparty"

        %w{instance-id local-hostname local-ipv4 public-hostname public-ipv4 security-groups}.each do |metaalias|
          has_bash_alias :name => metaalias, :value => "curl http://169.254.169.254/latest/meta-data/#{metaalias}"
        end
      end

      def add_binaries
        has_exec "wget http://gist.github.com/raw/131294/0622454b2cc2f787c04d20ab3d47e888e31edcd4/gistfile1 -O /usr/bin/xtail && chmod +x /usr/bin/xtail", 
          :not_if => "test -e /usr/bin/xtail"
        has_exec "curl http://timkay.com/aws/aws -o /usr/bin/aws", :not_if => "test -e /usr/bin/aws"
      end

      def add_profile_updates
        has_exec %Q{echo \\"export PS1='\\\\u@\\\\h \\\\A \\\\w (#{cloud_name}) $ '\\" >> /root/.profile}, :not_if => "grep PS1 /root/.profile | grep #{cloud_name}"
        # bind '"\e[A":history-search-backward'
        # bind '"\e[B":history-search-forward'
      end

    end
  end
end


