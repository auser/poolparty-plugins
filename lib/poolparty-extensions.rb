class PoolpartyExtensions
end

["#{File.dirname(__FILE__)}/extensions/*.rb", "#{File.dirname(__FILE__)}/extensions/*/*.rb"].each do |dir|
  Dir[dir].each do |lib|
    PoolParty::Resources::File.add_searchable_path(File.dirname(lib)) if File.exists?(File.dirname(lib) + "/templates")
    require lib if ::File.stat(lib).file?
  end
end