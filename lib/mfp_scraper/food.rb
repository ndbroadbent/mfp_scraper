class MFPScraper
  module Food
    extend ActiveSupport::Concern

    included do
      register_path :food_diary, ->(params) {
        path = "/food/diary/#{username}"
        if params[:date]
          path << '?date=' << params[:date].strftime("%Y-%m-%d")
        end
        path
      }
      register_path :food_search, '/food/search'
      register_path :add_food_entry, ->(params) { "/food/update_servings/#{params[:food_id]}" }
      register_path :edit_food_entry, ->(params) { "/food/edit_entry/#{params[:entry_id]}" }
      register_path :delete_food_entry, ->(params) { "/food/remove/#{params[:entry_id]}" }
    end


    FOOD_DATA_COLUMNS = %w(calories carbs fat protein sodium sugar).map(&:to_sym)
    MEAL_IDS = [:breakfast, :lunch, :dinner, :snacks].
                  each_with_index.each_with_object({}) {|(m,i), h| h[m] = i }


    def fetch_food_diary(date = Date.today)
      authenticate! unless authenticated?

      food_diary = {}

      agent.get(url_for(:food_diary, date: date)) do |page|
        food_container = page.search('.food_container')

        current_meal = nil
        food_container.xpath('table/tbody/tr').each do |row|
          case row.attr('class')
          when 'meal_header'
            current_meal = row.search('.first').text
            food_diary[current_meal] = []

          when nil
            if current_meal
              food_data = {}

              food_link = row.search('td.first a').first
              food_data[:description], food_data[:serving_size] = food_link.text.strip.split(',').map(&:strip)
              # Get rid of star in description
              food_data[:description].gsub!(/^\*/, '')
              food_data[:entry_id] = food_link.attr('data-food-entry-id')

              food_data_values = row.search('td')[1..6].map {|t| t.text.strip.to_i }
              food_data.merge Hash[FOOD_DATA_COLUMNS.zip(food_data_values)]

              food_diary[current_meal] << food_data
            end

          when 'bottom'
            current_meal = nil
          end
        end

        return food_diary
      end
    end


    def add_food_entry(options)
      authenticate! unless authenticated?
      options[:date] ||= Date.today

      agent.get(url_for(:food_search)) do |page|
        ajax_container = page.search('form[action="/food/add"] #loaded_item')[0]

        # Load food form into ajax container, from ajax endpoint
        food_form_page = agent.get(url_for(:add_food_entry, food_id: options[:food_id]))
        ajax_container.inner_html = food_form_page.body

        food_form = page.form_with(action: '/food/add')

        food_form['food_entry[date]']      = options[:date].strftime("%Y-%m-%d")
        food_form['food_entry[food_id]']   = options[:food_id]
        food_form['food_entry[quantity]']  = options[:quantity] || 1.0
        food_form['food_entry[weight_id]'] = options[:weight_id]
        food_form['food_entry[meal_id]']   = options[:meal_id]

        food_form.submit
      end

      return true
    end

    def update_food_entry(options)
      return nil unless (options.keys & [:quantity, :weight_id, :meal_id]).any?

      authenticate! unless authenticated?

      agent.get(url_for(:edit_food_entry, entry_id: options[:entry_id])) do |entry_form_page|
        food_form = entry_form_page.forms.first

        food_form['food_entry[quantity]']  = options[:quantity]  if options[:quantity]
        food_form['food_entry[weight_id]'] = options[:weight_id] if options[:weight_id]
        food_form['food_entry[meal_id]']   = options[:meal_id]   if options[:meal_id]

        food_form.submit
      end

      return true
    end

    def delete_food_entry(entry_id)
      agent.get(url_for(:delete_food_entry, entry_id: entry_id))
      return true
    end

    def delete_all_food_entries_for_date(date)
      meal_entries = fetch_food_diary(date)

      meal_entries.each do |meal, entries|
        entries.each do |entry|
          delete_food_entry(entry[:entry_id])
        end
      end

      return true
    end


    # Returns a hash of "Food name" => "food_id"
    def search_foods(query)
      authenticate! unless authenticated?

      agent.get(url_for(:food_search)) do | page|
        page = page.form_with(action: "/food/search") do |form|
          form.search = query
        end.submit

        foods = {}
        page.search('ul#matching li a.search').each do |link|
          food_id = link.attr('href')[/food\/update_servings\/(.*)/, 1]
          foods[link.text] = food_id
        end

        return foods
      end
    end

    # Returns a hash of "Weight name" => "weight_id"
    def weights_for_food_id(food_id)
      authenticate! unless authenticated?

      food_form = agent.get(url_for(:add_food_entry, food_id: food_id))

      weight_ids = {}
      food_form.search('select#food_entry_weight_id option').each do |option|
        weight_ids[option.text] = option.attr('value')
      end

      return weight_ids
    end

  end
end
