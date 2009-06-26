require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "poolparty-extensions"
    gem.summary = %Q{Extensions on to of poolparty}
    gem.email = "arilerner@mac.com"
    gem.homepage = "http://github.com/auser/poolparty-extensions"
    gem.authors = ["Ari Lerner, Nate Murray, & Michael Fairchild"]

    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = false
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/*_test.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end


task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  if File.exist?('VERSION.yml')
    config = YAML.load(File.read('VERSION.yml'))
    version = "#{config[:major]}.#{config[:minor]}.#{config[:patch]}"
  else
    version = ""
  end

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "poolparty-extensions #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

desc "Push to github with new gemspec and readme"
task :gh => [:readme, :gemspec] do
  %x{git commit -a -m "Added new readme and gemspec for github" && git push origin master}
end

desc "Generate new readme"
task :readme do
  base =<<-EOM
= poolparty-extensions

  Extensions to PoolParty!

  Just install and include in your clouds.rb

  clouds.rb
    require "poolparty"
    require "poolparty-extensions"
  EOM
  
  footer =<<-EOF
== Copyright

Copyright (c) 2009 Ari Lerner & Cloudteam. See LICENSE for details.  
  EOF
  
  extensions = FileList["#{File.dirname(__FILE__)}/lib/extensions/*.rb"]
  avail = extensions.inject([]) do |s,f|
    desc = begin
      str = open(f).read#[/\=begin rdoc(\n)*(.)*/].gsub(/\=begin rdoc\n/, '')
      if str =~ /\A=begin\s+rdoc/i
        str.sub!(/\A=begin.*\n/, '')
        str.sub!(/^=end.*/m, '')
      end
    rescue Exception => e
      "Installs #{::File.basename(f, ".rb")}"
    end
    
    s << {
      :name => ::File.basename(f, ".rb"),
      :desc => desc
    }
  end
  
  File.open("README.rdoc", "w") do |f|
    f << base
    f << "\n= Available extensions\n\n"
    f << avail.map do |h|
      "== #{h[:name]}\n#{h[:desc]}"
    end.join("\n")
    f << "\n\n"
    f << footer
  end
end

task :gem => [:build] do

end