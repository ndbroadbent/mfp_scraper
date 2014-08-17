#!/usr/bin/env ruby
$:.push File.expand_path("../lib", __FILE__)
require 'mfp_scraper'
require 'yaml'

if ARGV.length != 1
  puts "Usage: #{$0} \"MEAL: QUANTITY UNIT ITEM, ...\""
  exit 1
end

if File.exist?('config.yml')
  config = YAML.load_file('config.yml')
else
  puts "Please setup config.yml!"
  exit 1
end

mfp = MFPScraper.new(username: config['username'], password: config['password'])




mfp.add_food_entries_from_text(ARGV[0])
