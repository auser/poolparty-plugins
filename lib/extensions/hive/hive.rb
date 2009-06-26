=begin rdoc
In
=end

module PoolParty
  module Plugin
    class Hive < Plugin
      def before_load(o={}, &block)
        do_once do
          # install_from_bin
          install_from_src
          set_environment_variables
          create_hdfs_directories
        end
      end

      def install_from_bin
        has_exec "wget #{hive_dist} -O /usr/local/src/hive-0.3.0-hadoop-0.19.0-dev.tar.gz",
          :not_if => "test -e /usr/local/src/hive-0.3.0-hadoop-0.19.0-dev.tar.gz"
        has_exec "cd /usr/local/src && tar -xvvf /usr/local/src/hive-0.3.0-hadoop-0.19.0-dev.tar.gz", 
          :not_if => "test -e #{hive_home}"
        has_exec "mv /usr/local/src/hive-0.3.0-hadoop-0.19.0-dev #{hive_home}", 
          :not_if => "test -e #{hive_home}"
      end

      # doesn't really work
      def install_from_src
        install_dependent_packages
        download_and_build_src
      end

      def install_dependent_packages
        has_package :name => "subversion"
        has_package :name => "ant"
      end

      def download_and_build_src
        has_exec "svn co #{hive_repo} #{src_dir} -r#{hive_revision}",
          :not_if => "test -e #{src_dir}/build.xml"
        has_exec "cd #{src_dir} && wget --no-check-certificate https://issues.apache.org/jira/secure/attachment/12409779/hive-487.3.patch",
          :not_if => "test -e #{src_dir}/hive-487.3.patch"
        has_exec "cd #{src_dir} && patch -p0 < hive-487.3.patch && mv hive-487.3.patch hive-487.3.patch.applied", 
          :not_if => "test -e #{src_dir}/hive-487.3.patch.applied"
        has_exec "cd #{src_dir} && ant -Dhadoop.version=\\\"#{hadoop_version}\\\" package",
          :not_if => "test -e #{hive_home}/README.txt"
        has_exec "mv #{src_dir}/build/dist #{hive_home}",
          :not_if => "test -e #{hive_home}"
      end

      # todo, pull from parent
      def set_environment_variables
        has_file :name => "/root/.hadoop-etc-env.sh", :content => <<-EOF
export HADOOP_HOME=#{hadoop_home}
export HADOOP=$HADOOP_HOME/bin/hadoop
export HIVE_HOME=#{hive_home}
export PATH=$HADOOP_HOME/bin:$HIVE_HOME/bin:$PATH
        EOF
        has_line_in_file :file => "/root/.profile", :line => "source /root/.hadoop-etc-env.sh"
      end

      def create_hdfs_directories
        has_exec "#{hadoop_home}/bin/hadoop fs -mkdir /tmp", 
          :not_if => "#{hadoop_home}/bin/hadoop fs -ls /tmp",
          :only_if => "test -e #{hadoop_data_dir}/dfs"

        has_exec "#{hadoop_home}/bin/hadoop fs -mkdir /user/hive/warehouse", 
          :not_if => "#{hadoop_home}/bin/hadoop fs -ls /user/hive/warehouse",
          :only_if => "test -e #{hadoop_data_dir}/dfs"

        has_exec "#{hadoop_home}/bin/hadoop fs -chmod g+w /tmp", 
          :not_if => "#{hadoop_home}/bin/hadoop fs -ls /tmp", # todo, check perms
          :only_if => "test -e #{hadoop_data_dir}/dfs"
 
        has_exec "#{hadoop_home}/bin/hadoop fs -chmod g+w /user/hive/warehouse", 
          :not_if => "#{hadoop_home}/bin/hadoop fs -ls /user/hive/warehouse",
          :only_if => "test -e #{hadoop_data_dir}/dfs"
      end

      private

      def hive_dist
        "http://www.apache.org/dist/hadoop/hive/hive-0.3.0/hive-0.3.0-hadoop-0.19.0-dev.tar.gz"
      end

      def src_dir
        "/usr/local/src/hive"
      end

      def hive_home
        "/usr/local/hive"
      end

      def hive_repo
        # "http://svn.apache.org/repos/asf/hadoop/hive/tags/release-0.3.0/"
        "http://svn.apache.org/repos/asf/hadoop/hive/trunk"
      end

      def hive_revision
        "781069"
      end

      ### TODO the values below should pull from parent e.g. the hadoop plugin
      def hadoop_home
        "/usr/local/hadoop"
      end

      def hadoop_data_dir
        "/mnt/hadoop-data"
      end

      def hadoop_version
        "0.20.0"
      end

    end
  end
end
 
