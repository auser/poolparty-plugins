=begin rdoc

== Overview
Install Open Source tripwire

== Usage

    tripwire do
      root_dir "/usr/wpt" # CHANGE THIS to something obscure. The idea is you *dont* want tripwire to be in a standard location.
      mailto   "admin@emaildomain"
      smtp_settings "host", "username", "password"
    end

== BUGS

* It doesn't yet actually use the email settings in a cron job
* It wont re-write your policy when your template changes unless you manually rm #{root_dir}/etc/tw.pol - this is a todo

== NOTES

When you configure this will copy your password to /tmp/tripwire_password and
then rm it when done. This may cause problems when nodes provision each other.


== References
* http://linuxgazette.net/107/tag/4.html
* http://www.linuxhelp.net/guides/tripwire/
=end

PoolParty::Resources::FileResource.searchable_paths << File.dirname(__FILE__)+'/templates/'

module PoolParty
  module Resources
    class Tripwire < Resource
      dsl_methods :root_dir,
                  :mailto

      def after_loaded(o={}, &block)
        do_once do
          install_from_src
        end
      end

      def install_from_src
        base_requirements
        install_dependencies
        download
        password_file
        configure_and_build
        write_policy
        initialize_database
        cleanup_password_files
      end

      def smtp_settings host, username, password, port=25
        has_variable "tripwire_smtp_settings", true
        @smtp_settings ||= {:host => host, :username => username, :password => password, :port => port}
        %w{host username password port}.each do |setting|
          has_variable "tripwire_smtp_#{setting}", eval(setting)
        end
      end

      private
      def base_requirements
        has_directory src_dir
        has_directory "/tmp"
      end
      
      def install_dependencies
        has_package "expect"
      end

      def download
        has_exec "download_tripwire",
          :command => "wget http://softlayer.dl.sourceforge.net/sourceforge/tripwire/tripwire-2.4.1.2-src.tar.bz2 -O /usr/local/src/tripwire-2.4.1.2-src.tar.bz2",
          :not_if => "test -e /usr/local/src/tripwire-2.4.1.2-src.tar.bz2"
          
        has_exec "unpack_tripwire",
          :command => "cd /usr/local/src && tar -xvvf /usr/local/src/tripwire-2.4.1.2-src.tar.bz2",
          :not_if => "test -d #{tripwire_src}",
          :requires => get_exec("download_tripwire")
      end

      def configure_and_build
        raise "tripwire requires a root_dir to be specified. Try using the `root_dir` directive to specify an arbitrary directory to install tripwire in" unless root_dir
        has_directory root_dir
        has_exec "configure_tripwire",
          :command => "cd #{tripwire_src} && ./configure --prefix=#{root_dir}",
          :requires => get_exec("unpack_tripwire"),
          :not_if => "test -e #{tripwire_src}/Makefile"
          
        has_exec "make_tripwire",
          :command => "cd #{tripwire_src} && make",
          :requires => get_exec("configure_tripwire"),
          :not_if => "test -e #{tripwire_src}/bin/tripwire"
          
        has_file :name => "#{tripwire_src}/install/install.cfg", :mode => "0644", :template => "install.cfg.erb" do
          requires get_exec("make_tripwire")
        end
        has_file :name => "#{tripwire_src}/make-install-tripwire.tcl", :mode => "0755", :template => "make-install-tripwire.tcl.erb" do
          requires get_exec("make_tripwire")
        end



        # TODO ----------- this is a huge security hole b/c it leaves the
        # password all over the place. todo figure this one out
        has_exec "touch_password",
          :not_if => "test -e #{root_dir}/etc/tw.cfg",
          :command => "cd #{tripwire_src} && /usr/bin/expect make-install-tripwire.tcl #{site_password_unix_line} #{local_password_unix_line}",
          :requires => get_exec("make_tripwire")

        has_file :name => "#{root_dir}/etc/twcfg.txt", :mode => "0644", :template => "twcfg.txt.erb", :requires => get_exec("make_tripwire")
        has_file :name => "#{root_dir}/etc/twpol.txt", :mode => "0644", :template => "twpol.txt.erb", :requires => get_exec("make_tripwire")
      end

      def write_policy
        has_exec "cd #{root_dir} && echo #{site_password_unix_line} | ./sbin/twadmin --create-polfile #{root_dir}/etc/twpol.txt",
          :not_if => "test -e #{root_dir}/etc/tw.pol" # really this should be only if twpol.txt changed (todo)
      end

      def initialize_database
        has_exec "cd #{root_dir} && echo #{local_password_unix_line} | ./sbin/tripwire --init",
          :not_if => "test -e #{root_dir}/lib/tripwire/\`hostname\`.twd",
          :requires => get_exec("make_tripwire")
      end

      def src_dir
        "/usr/local/src"
      end

      def tripwire_src
        "/usr/local/src/tripwire-2.4.1.2-src"
      end

      def ideas
         # chkrootkit
         # wget ftp://ftp.pangeia.com.br/pub/seg/pac/chkrootkit.tar.gz 
         # tar -xzvf chkrootkit.tar.gz 
         # cd chkrootkit-version (whatever version is) 
         # ./chkrootkit 
      end

      # todo
      def site_password_unix_line
        '`cat /tmp/tripwire_password | head -n 1`'
      end

      # todo
      def local_password_unix_line
        '`cat /tmp/tripwire_password | tail -n 1`'
      end

      def check
        # #{root_dir}/sbin/tripwire --check > /tmp/report.txt
      end

      def password_file
        users_template = File.expand_path(File.dirname(clouds_dot_rb_file)/:templates/:tripwire/"tripwire_passwords")
        unless File.exists?(users_template)
          puts "***** WARNING #{users_template} does not exist. This is required to use the tripwire plugin. the format is the site password on the first line and local password in the second"
        end        
        has_file :name => "/tmp/tripwire_password", :mode => "0644", :template => users_template
      end

      def cleanup_password_files
        %w{
           /tmp/tripwire_password
           /var/poolparty/dr_configure/etc/poolparty/secure/templates/tripwire/tripwire_passwords
           /var/poolparty/dr_configure/chef/cookbooks/poolparty/templates/default/tmp/tripwire_password.erb
          }.each do |dirty|
          has_exec "rm -f #{dirty}", :only_if => "test -e #{dirty}"
        end
      end

    end
  end
end

