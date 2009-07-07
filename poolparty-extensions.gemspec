# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{poolparty-extensions}
  s.version = "0.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Ari Lerner, Nate Murray, & Michael Fairchild"]
  s.date = %q{2009-07-07}
  s.email = %q{arilerner@mac.com}
  s.extra_rdoc_files = [
    "LICENSE",
    "README.rdoc"
  ]
  s.files = [
    "LICENSE",
    "README.rdoc",
    "Rakefile",
    "VERSION.yml",
    "lib/extensions/bash_alias.rb",
    "lib/extensions/convenience_helpers.rb",
    "lib/extensions/development_gem_package.rb",
    "lib/extensions/dynomite.rb",
    "lib/extensions/ganglia/ganglia.rb",
    "lib/extensions/ganglia/templates/bin/gmetad.erb",
    "lib/extensions/ganglia/templates/bin/gmond.erb",
    "lib/extensions/ganglia/templates/ganglia-web-conf.php.erb",
    "lib/extensions/ganglia/templates/gmetad.conf.erb",
    "lib/extensions/ganglia/templates/gmond.conf.erb",
    "lib/extensions/ganglia/templates/hadoop-metrics.properties.erb",
    "lib/extensions/hadoop/hadoop.rb",
    "lib/extensions/hadoop/templates/core-site.xml.erb",
    "lib/extensions/hadoop/templates/hadoop-env.sh",
    "lib/extensions/hadoop/templates/hadoop-site.xml.erb",
    "lib/extensions/hadoop/templates/hadoop_hosts.erb",
    "lib/extensions/hadoop/templates/hdfs-site.xml.erb",
    "lib/extensions/hadoop/templates/init.d/hadoop-datanode",
    "lib/extensions/hadoop/templates/init.d/hadoop-jobtracker",
    "lib/extensions/hadoop/templates/init.d/hadoop-namenode",
    "lib/extensions/hadoop/templates/init.d/hadoop-secondarynamenode",
    "lib/extensions/hadoop/templates/init.d/hadoop-tasktracker",
    "lib/extensions/hadoop/templates/jvm.conf",
    "lib/extensions/hadoop/templates/log4j.properties.erb",
    "lib/extensions/hadoop/templates/mapred-site.xml.erb",
    "lib/extensions/hive/hive.rb",
    "lib/extensions/lightcloud.rb",
    "lib/extensions/nanite.rb",
    "lib/extensions/tokyo_tyrant.rb",
    "lib/poolparty-extensions.rb",
    "test/extensions/rails_deploy_test.rb",
    "test/poolparty_extensions_test.rb",
    "test/test_helper.rb"
  ]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/auser/poolparty-extensions}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.2}
  s.summary = %q{Extensions on to of poolparty}
  s.test_files = [
    "test/extensions/rails_deploy_test.rb",
    "test/poolparty_extensions_test.rb",
    "test/test_helper.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
