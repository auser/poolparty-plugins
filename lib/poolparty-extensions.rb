class PoolpartyExtensions
end

arr = []
["#{File.dirname(__FILE__)}/extensions/*.rb", "#{File.dirname(__FILE__)}/extensions/*/*.rb"].each do |dir|
  Dir[dir].each do |lib|
    templates_dir = File.expand_path(File.join(File.dirname(lib), "templates"))
    if File.exists?(templates_dir)
      arr << templates_dir
    end
    require lib if ::File.stat(lib).file?
  end
end
PoolParty::Resources::FileResource.has_searchable_paths :prepend_paths=> arr
PoolParty::Resources::FileResource.searchable_paths
# p PoolParty::Resources::FileResource.searchable_paths