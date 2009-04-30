class PoolpartyExtensions
end

Dir["#{File.dirname(__FILE__)}/extensions/*"].each do |lib|
  require lib
end