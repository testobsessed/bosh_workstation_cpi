module BoshWorkstationCpi::Actions; end

actions_dir_path = File.expand_path("#{__FILE__}/../actions")
Dir["#{actions_dir_path}/*.rb"].each { |f| require(f) }
