# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mfp_scraper/version'

Gem::Specification.new do |spec|
  spec.name          = "mfp_scraper"
  spec.version       = MFPScraper::VERSION
  spec.authors       = ["Nathan Broadbent"]
  spec.email         = ["nathan.f77@gmail.com"]
  spec.summary       = "Web Scraper for MyFitnessPal"
  spec.description   = "A simple API client for MyFitnessPal, which requires a user's username and password"
  spec.homepage      = "https://github.com/ndbroadbent/mfp_scraper"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"

  spec.add_dependency "mechanize"
  spec.add_dependency "activesupport"
  spec.add_dependency "numerouno"
end
