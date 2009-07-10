=begin rdoc

== Overview
Install Open Source tripwire

== Usage

  tripwire

== References
* http://linuxgazette.net/107/tag/4.html
=end


module PoolParty
  module Plugin
    class Tripwire < Plugin
      dsl_methods :root_dir,
                  :mailto

      # def before_load(o={}, &block)
      def loaded(o={}, &block)
        do_once do
          install_from_src
        end
      end

      def install_from_src
        download
        configure_and_build
      end

      def smtp_settings host, username, password, port=25
        @smtp_settings ||= {:host => host, :username => username, :password => password, :port => port}
        %w{host username password port}.each do |setting|
          has_variable "tripwire_smtp_#{setting}", :value => eval(setting)
        end
      end

      private
      def download
        has_exec "wget http://softlayer.dl.sourceforge.net/sourceforge/tripwire/tripwire-2.4.1.2-src.tar.bz2 -O /usr/local/src/tripwire-2.4.1.2-src.tar.bz2",
          :not_if => "test -e /usr/local/src/tripwire-2.4.1.2-src.tar.bz2"
        has_exec "cd /usr/local/src && tar -xvvf /usr/local/src/tripwire-2.4.1.2-src.tar.bz2",
          :not_if => "test -d #{tripwire_src}"
      end

      def configure_and_build
        raise "tripwire requires a root_dir to be specified. Try using the `root_dir` directive to specify an arbitrary directory to install tripwire in" unless root_dir
        has_directory root_dir
        has_exec "cd #{tripwire_src} && ./configure --prefix=#{root_dir}",
          :not_if => "test -e #{tripwire_src}/Makefile"
        has_exec "cd #{tripwire_src} && make",
          :not_if => "test -e #{tripwire_src}/bin/tripwire"
      end

      def src_dir
        "/usr/local/src"
      end

      def tripwire_src
        "/usr/local/src/tripwire-2.4.1.2-src"
      end


    end
  end
end

