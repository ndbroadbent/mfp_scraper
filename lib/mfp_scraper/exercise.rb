class MFPScraper
  module Exercise
    EXERCISE_DATA_COLUMNS = %w(minutes calories).map(&:to_sym)
    EXERCISE_TYPE_IDS = [:cardio, :weight].
              each_with_index.each_with_object({}) {|(m,i), h| h[m] = i }

    def fetch_exercise_diary(date = Date.today)
      authenticate! unless authenticated?

      exercise_diary = {}

      agent.get(url_for(:fetch_exercise_diary, date: date)) do |page|
        container = page.search('.container')

        container.search('table').each do |table|
          exercise = table.search('thead td.first').text.strip
          exercise_diary[exercise] = []

          table.search('tbody tr').each do |row|
            break if row.attr('class').to_s.include?('bottom')

            exercise_data = {}

            exercise_link = row.search('td.first a')[0]
            exercise_data[:description] = exercise_link.text.strip
            exercise_data[:entry_id] = exercise_link.attr('onclick')[/showEditExercise\((\d+)/, 1]

            exercise_data_values = row.search('td')[1..2].map {|t| t.text.strip.to_i }
            exercise_data.merge! Hash[EXERCISE_DATA_COLUMNS.zip(exercise_data_values)]

            exercise_diary[exercise] << exercise_data
          end
        end

        return exercise_diary
      end
    end


    def add_exercise_entry(options)
      puts "Adding exercise:"
      puts options.inspect

      authenticate! unless authenticated?
      options[:start_time] ||= Time.now

      agent.get(url_for(:exercise_search)) do |page|
        ajax_container = page.search('form[action="/exercise/add"] #servings')[0]

        # Load food form into ajax container, from ajax endpoint
        form_page = agent.get(url_for(:add_exercise_entry, exercise_id: options[:exercise_type_id]))
        ajax_container.inner_html = form_page.body

        form = page.form_with(action: '/exercise/add')

        form['exercise_entry[date]'] = options[:start_time].to_date
        form['exercise_entry[type]'] = options[:exercise_type_id]
        form['exercise_entry[quantity]'] = options[:minutes]
        form['exercise_entry[calories]'] = options[:calories]

        options[:start_time].strftime("%Y/%m/%d/%H/%M").split('/').each_with_index do |date_component, i|
          form["exercise_entry[start_time(#{i + 1}i)]"] = date_component
        end

        form.submit
      end

      return true
    end

    def update_exercise_entry(options)
      return nil unless (options.keys & [:start_time, :minutes, :calories]).any?

      authenticate! unless authenticated?

      agent.get(url_for(:edit_exercise_entry, entry_id: options[:entry_id])) do |entry_form_page|
        form = entry_form_page.forms.first

        form['exercise_entry[quantity]'] = options[:minutes]
        form['exercise_entry[calories]'] = options[:calories]

        if options[:start_time]
          options[:start_time].strftime("%Y/%m/%d/%H/%M").split('/').each_with_index do |date_component, i|
            form["exercise_entry[start_time(#{i + 1}i)]"] = date_component
          end
        end

        form.submit
      end

      return true
    end

    def delete_exercise_entry(entry_id)
      puts "Deleting entry: #{entry_id}"
      agent.get(url_for(:delete_exercise_entry, entry_id: entry_id))
      return true
    end

    def delete_all_exercise_entries_for_date(date)
      entries = fetch_exercise_diary(date)

      entries.each do |_, entries|
        entries.each do |entry|
          delete_exercise_entry(entry[:entry_id])
        end
      end

      return true
    end


    # Returns a hash of "Food name" => "food_id"
    # def search_exercises(query)
    #   authenticate! unless authenticated?

    #   agent.get(url_for(:food_search)) do | page|
    #     page = page.form_with(action: "/food/search") do |form|
    #       form.search = query
    #     end.submit

    #     foods = {}
    #     page.search('ul#matching li a.search').each do |link|
    #       food_id = link.attr('href')[/food\/update_servings\/(.*)/, 1]
    #       foods[link.text] = food_id
    #     end

    #     return foods
    #   end
    # end

  end
end
