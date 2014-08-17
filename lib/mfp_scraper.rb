require 'active_support/concern'
require 'active_support/core_ext/hash'
require 'mechanize'
require 'numerouno'

require 'mfp_scraper/version'
require 'mfp_scraper/authentication'
require 'mfp_scraper/exercise'
require 'mfp_scraper/food'
require 'mfp_scraper/food_nlp'

class MFPScraper
  PROTOCOL = 'http://'
  HOST = 'www.myfitnesspal.com'

  @action_paths = {}
  class << self
    def register_path(action, proc_or_string)
      @action_paths[action] = proc_or_string
    end
  end

  def action_paths
    self.class.instance_variable_get("@action_paths")
  end

  include Authentication
  include Exercise
  include Food
  include FoodNLP

  attr_accessor :username, :password


  def initialize(options)
    @username = options[:username]
    @password = options[:password]
  end


  def path_for(action, params = {})
    proc_or_string = action_paths[action]
    raise "Invalid action! (#{action})" unless proc_or_string

    case proc_or_string
    when String then
      proc_or_string
    when Proc
      instance_exec(params, &proc_or_string)
    else
      raise "Don't know how to handle a: #{path.class}"
    end
  end

  def url_for(action, params = {})
    path = path_for(action, params)
    [PROTOCOL, HOST, path].join
  end

  def agent
    @agent ||= Mechanize.new do |agent|
      agent.user_agent_alias = 'Mac Safari'
    end
  end
end
