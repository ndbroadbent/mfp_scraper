require 'mfp_scraper/version'
require 'mfp_scraper/exercise'
require 'mfp_scraper/food'
require 'mfp_scraper/food_nlp'

require 'active_support/core_ext/hash'
require 'mechanize'
require 'numerouno'

class MFPScraper
  include Exercise
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
      login_result = page.form_with(action: /\/account\/login$/) do |login|
        login.username = @username
        login.password = @password
      end.submit

      if login_result.search("p.flash").text[/Incorrect username or password/]
        @authenticated = false
      else
        @authenticated = true
      end
    end

    return @authenticated
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

    when :fetch_exercise_diary
      path = "/exercise/diary/#{username}"
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


    when :exercise_search
      path = '/exercise/search'

    when :add_exercise_entry
      path = "/exercise/update_exercise/#{params[:exercise_id]}"

    when :edit_exercise_entry
      path = "/exercise/edit_entry/#{params[:entry_id]}"

    when :delete_exercise_entry
      path = "/exercise/remove/#{params[:entry_id]}"


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
