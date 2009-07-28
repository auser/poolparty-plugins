=begin rdoc

== Overview
Install a hadoop cluster

== Requirements
You'll need apache and php enabled in your clouds.rb. For example:

    apache do
      enable_php5
    end

== Bugs
This assumes your clouds are named "hadoop_master" and "hadoop_slave". That sucks. TODO: pass these in as variables

== References
=end



module PoolParty
  module Resources
    class Hadoop < Resource
      
      def before_load(o={}, &block)
        do_once do
          install_jdk
          install_dependencies
          # add_users_and_groups
          create_keys
          connect_keys
          build
          configure
          format_hdfs
          create_aliases
        end
      end

      def perform_just_in_time_operations
        create_reference_hosts
        create_ssh_configs
        create_master_and_slaves_files
      end

      def install_jdk
        # accept the sun license agreements. see: http://www.davidpashley.com/blog/debian/java-license
        has_exec "echo sun-java6-jdk shared/accepted-sun-dlj-v1-1 select true | /usr/bin/debconf-set-selections"
        has_exec "echo sun-java6-jre shared/accepted-sun-dlj-v1-1 select true | /usr/bin/debconf-set-selections"
        has_package(:name => "sun-java6-jdk")
        has_file(:name => "/etc/jvm") do
            mode 0644
            template File.dirname(__FILE__)+"/templates/jvm.conf"
         end
      end

      def install_dependencies
        has_package(:name => "dnsutils")
      end

      def add_users_and_groups
        has_group "hadoop", :action => :create
        has_user "hadoop", :gid => "hadoop"
        has_directory "/home/hadoop", :owner => "hadoop", :mode => "755"

        # TODO - ssh key code below needs to turn into these lines. those should become plugins
        # has_ssh_key :user => "hadoop", :name => "hadoop_id_rsa", :create => true
        # has_authorized_key :user => "hadoop", :name => "hadoop_id_rsa"
      end

      def create_keys
        unless File.exists?(hadoop_id_rsa)
          FileUtils.mkdir_p(cloud_keys_dir)
          cmd = "ssh-keygen -t rsa -N '' -f #{hadoop_id_rsa}" # todo, make into variables
          puts cmd
          `#{cmd}`
        end
      end

      # everything below should become methods and/or plugins
      def connect_keys
        # has_exec "ssh-keygen -t rsa -N '' -f /home/hadoop/.ssh/id_rsa", :user => "hadoop", :not_if => "test -e /home/hadoop/.ssh/id_rsa"

        # so annoying, chef/rsync/something doesn't copy over dotfiles, so upload it as non-dot
        has_directory :name => "#{home_dir}/ssh"
        has_directory :name => "#{home_dir}/.ssh"
        has_file :name => "#{home_dir}/ssh/#{hadoop_id_rsa_base}", :content => open(hadoop_id_rsa).read
        has_exec "mv #{home_dir}/ssh/hadoop_id_rsa #{home_dir}/.ssh/#{hadoop_id_rsa_base}"
        has_exec "chmod 600 #{home_dir}/.ssh/#{hadoop_id_rsa_base}"
        has_exec "chmod 700 #{home_dir}/.ssh"
        has_exec "rm -rf #{home_dir}/ssh"

        # setup authorized keys
        has_exec "touch #{home_dir}/.ssh/authorized_keys"
        has_exec "chmod 644 #{home_dir}/.ssh/authorized_keys"
        has_exec "chown -R #{user} #{home_dir}/.ssh"
        has_line_in_file :file => "#{home_dir}/.ssh/authorized_keys", :line => File.read("#{hadoop_id_rsa}.pub")
      end

      def create_reference_hosts
        each_node_with_type_and_index do |n, node_type, i|
          if n[:private_dns_name]
            has_exec "ghost modify #{node_type}#{i} \`dig +short #{n[:private_dns_name]}\`"
          else
            has_exec "ghost modify #{node_type}#{i} #{n[:ip]}"
          end
        end
      end

      def create_ssh_configs
        ssh_config = ""
        each_node_with_type_and_index do |n, node_type, i|
          has_exec "ssh -o 'StrictHostKeyChecking no' -i #{home_dir}/.ssh/#{hadoop_id_rsa_base} #{node_type}#{i} echo", 
            :user => user, # verify the host key
            :ignore_failure => true,
            :only_if => "grep #{node_type}#{i} /etc/hosts"
        end

        ssh_config << <<EOF
Host *
       IdentityFile #{home_dir}/.ssh/#{hadoop_id_rsa_base}
EOF

        # has_file("#{home_dir}/.ssh/known_hosts", :template => "known_hosts.erb", :owner => user, :group => user, :mode => "600") # clear out the known hosts file

        has_exec "ssh -o 'StrictHostKeyChecking no' -i #{home_dir}/.ssh/#{hadoop_id_rsa_base} localhost echo", :user => user # verify the host key

        has_file("#{home_dir}/ssh_config", :content => ssh_config)
        has_exec "mv #{home_dir}/ssh_config #{home_dir}/.ssh/config"
        has_exec "chmod 600 #{home_dir}/.ssh/config"
        has_exec "chown #{user}:#{group} #{home_dir}/.ssh/config"
      end

      def build
        has_directory "/usr/local/src"
        has_exec "wget http://www.gossipcheck.com/mirrors/apache/hadoop/core/hadoop-0.20.0/hadoop-0.20.0.tar.gz -O /usr/local/src/hadoop-0.20.0.tar.gz", 
          :not_if => "test -e /usr/local/src/hadoop-0.20.0.tar.gz"
        has_exec "cd /usr/local/src && tar -xzf hadoop-0.20.0.tar.gz",
          :not_if => "test -e /usr/local/src/hadoop"
        has_exec "mv /usr/local/src/hadoop-0.20.0 /usr/local/src/hadoop",
          :not_if => "test -e /usr/local/src/hadoop/hadoop-0.20.0-core.jar"
        has_exec "chown -R #{user}:#{group} /usr/local/src/hadoop",
          :not_if => "test -e #{hadoop_install_dir}"
        build_src
        has_exec "mv /usr/local/src/hadoop #{hadoop_install_dir}",
          :not_if => "test -e #{hadoop_install_dir}"
      end

      def build_src
        has_directory "/usr/local/src/hadoop/orig"
        has_exec "cp /usr/local/src/hadoop/hadoop-0.20.0-core.jar /usr/local/src/hadoop/orig/hadoop-0.20.0-core.jar",
          :not_if => "test -e /usr/local/src/hadoop/orig/hadoop-0.20.0-core.jar"

        has_package "ant"
        has_package "zlib1g-dev"
        has_directory "/usr/local/src/hadoop/patches"

        # get whatever patches you want here
        has_wget("https://issues.apache.org/jira/secure/attachment/12407207/HADOOP-4675-v7.patch", "/usr/local/src/hadoop/patches/0001-ganglia31-HADOOP-4675-v7.patch")

        # apply them
        has_exec "cd /usr/local/src/hadoop && for PATCH in `find patches -type f | grep -v applied`; do (patch -p0 < ${PATCH}); mv ${PATCH} ${PATCH}.applied ; done"

        # probably need to restart hadoop somewhere here

        has_exec :name => "upgrade-core-hadoop-jar", 
          # :command => "cp /usr/local/src/hadoop/build/hadoop-0.20.1-dev-core.jar /usr/local/src/hadoop/hadoop-0.20.0-core.jar", 
          :command => "cp -f /usr/local/src/hadoop/build/hadoop-0.20.1-dev-core.jar #{hadoop_install_dir}/hadoop-0.20.0-core.jar", 
          :action => :nothing

        has_exec "export JAVA_HOME=/usr/lib/jvm/java-6-sun && cd /usr/local/src/hadoop && ant jar" do
          not_if "test -e /usr/local/src/hadoop/build/hadoop-0.20.1-dev-core.jar"
          notifies get_exec("upgrade-core-hadoop-jar"), :run
        end
      end

      def hadoop_install_dir
        "/usr/local/hadoop"
      end

      def set_current_master(master_hostname="master0", port="54310")
        do_once do
          has_variable :name => "current_master", :value => master_hostname # todo, could eventually be made more dynamic here
          has_variable :name => "hadoop_fs_default_port", :value => port # todo, could eventually be made more dynamic here
        end
      end

      def configure
        has_gem_package("bjeanes-ghost")

        has_file(:name => hadoop_install_dir/"conf/hadoop-env.sh") do
          mode 0644
          template "hadoop-env.sh"
        end


        has_variable "block_replication_level", :value => 5 # this isn't the number of nodes, this is the block replication level
        # this should be able to be configured in the hadoop config

        has_directory hadoop_data_dir, :owner => user, :mode => "755"
        has_exec "chgrp -R #{group} #{hadoop_data_dir}"

        %w{logs name data mapred temp}.each do |folder|
          has_directory hadoop_data_dir/folder, :owner => user, :mode => "755"
        end
        has_directory hadoop_data_dir/:temp/:dfs/:data, :owner => user, :mode => "755"

        %w{local system temp}.each do |folder|
          has_directory hadoop_data_dir/:temp/:mapred/folder, :owner => user, :mode => "755"
        end

        has_variable "hadoop_data_dir",   :value => hadoop_data_dir
        has_variable "hadoop_mapred_dir", :value => hadoop_data_dir/:mapred

        has_variable("hadoop_this_nodes_ip", :value => lambda{ %Q{%x[curl http://169.254.169.254/latest/meta-data/local-ipv4]}})

        %w{core hdfs mapred}.each do |config|
          has_file(:name => hadoop_install_dir/"conf/#{config}-site.xml") do
            mode 0644
            template "#{config}-site.xml.erb"
          end
        end

        has_file(:name => hadoop_install_dir/"conf/log4j.properties") do
          mode 0644
          template "log4j.properties.erb"
        end

     end

     def number_of_running_nodes_in_pool
       # clouds.keys.inject(0) { |sum,cloud_name| sum = sum + clouds[cloud_name].nodes(:status => 'running').size; sum }
     end

     def configure_master
       # create_master_and_slaves_files
       set_current_master

       %w{datanode jobtracker namenode secondarynamenode}.each do |hadoop_role|
         has_hadoop_service(hadoop_role)
       end
     end

     def configure_slave
       set_current_master

       %w{datanode tasktracker}.each do |hadoop_role|
         self.send("configure_#{hadoop_role}")
       end
     end

     def configure_tasktracker
       set_current_master
       has_hadoop_service("tasktracker")
     end

     def configure_datanode
       set_current_master
       has_hadoop_service("datanode")
     end

     def has_hadoop_service(hadoop_role) 
        has_file(:name => "/etc/init.d/hadoop-#{hadoop_role}") do
          mode 0755
          template "init.d/hadoop-#{hadoop_role}"
        end
        has_service "hadoop-#{hadoop_role}", :enabled => true, :running => true, :supports => [:restart]
     end

     def format_hdfs
       has_directory hadoop_data_dir, :mode => "770"
       has_exec "chown -R #{user}:#{group} #{hadoop_data_dir}"

       has_exec "#{hadoop_install_dir}/bin/hadoop namenode -format", 
         # :not_if => "test -e #{hadoop_data_dir}/hadoop-hadoop/dfs", 
         :not_if => "test -e #{hadoop_data_dir}/dfs/name",  # this line depends on if you have user-based data directories in core-site.xml
         :user => user
     end

     # stuff for examples

     def prep_example_job
       download_sample_data
     end

     def run_example_job
       start_hadoop
       copy_sample_data_to_hdfs
       start_the_job
     end

     def start_hadoop
       has_exec hadoop_install_dir/"bin/start-all.sh", 
         :user => user
     end

     def download_sample_data
       has_directory "/tmp/gutenberg", :mode => "770", :owner => user
       # todo, create has_wget
       has_exec "wget http://www.gutenberg.org/files/20417/20417.txt -O /tmp/gutenberg/outline-of-science.txt", 
         :not_if => "test -e /tmp/gutenberg/outline-of-science.txt"
       has_exec "wget http://www.gutenberg.org/dirs/etext04/7ldvc10.txt -O /tmp/gutenberg/7ldvc10.txt", 
         :not_if => "test -e /tmp/gutenberg/7ldvc10.txt"
       has_exec "wget http://www.gutenberg.org/files/4300/4300.txt -O /tmp/gutenberg/ulysses.txt",
         :not_if => "test -e /tmp/gutenberg/ulysses.txt"
       has_exec "chown -R #{user}:#{group} /tmp/gutenberg"
     end

     def copy_sample_data_to_hdfs
       has_exec "#{hadoop_install_dir}/bin/hadoop dfs -rmr gutenberg", :user => user,
         :only_if => "sudo -H -u #{user} #{hadoop_install_dir}/bin/hadoop dfs -ls gutenberg"
       has_exec "#{hadoop_install_dir}/bin/hadoop dfs -rmr gutenberg-output", :user => user, 
         :only_if => "sudo -H -u #{user} #{hadoop_install_dir}/bin/hadoop dfs -ls gutenberg-output"
       has_exec "#{hadoop_install_dir}/bin/hadoop dfs -copyFromLocal /tmp/gutenberg gutenberg", 
         :not_if => "sudo -H -u #{user} #{hadoop_install_dir}/bin/hadoop dfs -ls gutenberg | grep ulysses",
         :user => user
     end

     def start_the_job
       has_exec "#{hadoop_install_dir}/bin/hadoop jar #{hadoop_install_dir}/hadoop-0.20.0-examples.jar wordcount gutenberg gutenberg-output", 
         :user => user
     end

     def create_master_and_slaves_files
       masters_file = ""
       slaves_file  = ""

       master_nodes.each_with_index do |n,i| 
         masters_file << "master#{i}\n"
       end 

       slave_nodes.each_with_index do |n, i|
         slaves_file << "slave#{i}\n"
       end

       # dont need tasktracker nodes here b/c this is for the dfs

       has_file(hadoop_install_dir/:conf/:masters, :content => masters_file)
       has_file(hadoop_install_dir/:conf/:slaves,  :content => slaves_file)
     end

     def create_aliases
        has_bash_alias :name => "cd-hadoop", :value => "pushd /usr/local/hadoop"
     end

     def create_client_user(username)
       has_user(username)
       has_directory("/home/#{username}/.ssh", :mode => "700", :owner => username, :group => username)
       has_exec "#{hadoop_install_dir}/bin/hadoop fs -mkdir /user/#{username}", :user => user,
         :only_if => "sudo -H -u #{user} #{hadoop_install_dir}/bin/hadoop fs -ls /user",
         :not_if =>  "sudo -H -u #{user} #{hadoop_install_dir}/bin/hadoop fs -ls /user/#{username}"

       has_exec "#{hadoop_install_dir}/bin/hadoop fs -chown #{username} /user/#{username}", :user => user,
         :only_if => "sudo -H -u #{user} #{hadoop_install_dir}/bin/hadoop fs -ls /user/#{username}"
     end

      private
      def cloud_keys_dir
        '/Users/mfairchild/Code/poolparty-examples/hadoop'/:keys
      end

      def hadoop_id_rsa
        "#{cloud_keys_dir}/#{hadoop_id_rsa_base}" 
      end

      def hadoop_id_rsa_base
        "hadoop_id_rsa"
      end

      def hadoop_data_dir
        "/mnt/hadoop-data"
      end

      def home_dir
        "/root" 
        # or
        # "/home/hadoop"
      end

      def user
        "root"
        # or
        # hadoop
      end

      def group
        "root"
        # or
        # hadoop
      end

      def my_line_in_file(file, line)
        has_exec "line_in_#{file}_#{line.safe_quote}" do
          command "grep -q \'#{line.safe_quote}\' #{file} || echo \'#{line.safe_quote}\' >> #{file}"
          not_if "grep -q \'#{line.safe_quote}\' #{file}"
        end
      end

      def master_nodes
        clouds['hadoop_master'].nodes(:status => 'running') || []
      end

      def slave_nodes
        clouds['hadoop_slave'].nodes(:status => 'running') || []
      end

      def tasktracker_nodes
        []
        # clouds['hadoop_tasktracker'].nodes(:status => 'running') || []
      end

      def node_types
        %w{master slave tasktracker}
      end

      # for each node type, yield all the running nodes with an index
      def each_node_with_type_and_index(&block)
        node_types.each do |node_type|
          self.send("#{node_type}_nodes").each_with_index do |n, i|
            block.call(n, node_type, i)
          end
        end
      end

      def has_wget(source_url, location)
        has_exec "wget --no-check-certificate #{source_url} -O #{location}", :not_if => "test -e #{location}"
      end
      
    end
  end
end
