require 'mfp_scraper/version'
require 'mfp_scraper/food'
require 'mfp_scraper/food_nlp'

require 'active_support/core_ext/hash'
require 'mechanize'
require 'numerouno'

class MFPScraper
  include Food
  include FoodNLP

  HOST = 'www.myfitnesspal.com'

  attr_accessor :authenticated, :username
  alias :authenticated? :authenticated

  def initialize(options)
    @username = options[:username]
    @password = options[:password]
  end

  def authenticate!
    agent.get(url_for(:login)) do |page|
      page.form_with(action: /\/account\/login$/) do |login|
        login.username = @username
        login.password = @password
      end.submit
    end

    @authenticated = true
  end


  def url_for(action, params = {})
    query_hash = {}
    case action
    when :login
      path = "/"

    when :fetch_food_diary
      path = "/food/diary/#{username}"
      if params[:date]
        query_hash[:date] = params[:date].strftime("%Y-%m-%d")
      end

    when :food_search
      path = '/food/search'

    when :add_food_entry
      path = "/food/update_servings/#{params[:food_id]}"

    when :edit_food_entry
      path = "/food/edit_entry/#{params[:entry_id]}"

    when :delete_food_entry
      path = "/food/remove/#{params[:entry_id]}"

    else
      path = action
    end

    URI::HTTP.build({host: HOST, path: path, query: query_hash.to_query}).to_s
  end

  def agent
    @agent ||= Mechanize.new do |agent|
      agent.user_agent_alias = 'Mac Safari'
    end
  end
end
