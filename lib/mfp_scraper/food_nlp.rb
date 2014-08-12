# Add food items from natural language

class MFPScraper
  module FoodNLP

    # Example:
    #
    #   Breakfast: one bowl puffins peanut butter cereal, 1.5 cup 2% milk, one cup orange juice, one slice chocolate chip banana bread
    #   Lunch: one chicken skewer, one beef skewer, half cup salad, 3 tablespoons Aioli
    #   Dinner: 1 Chicken Soft Tacos, 2 tbsp sour cream
    #   Snacks: one mocha, one diet Coke

    def add_food_entries_from_text(text, date = Date.today)
      food_entries = parse_food_entries_from_text(text)

      food_entries.each do |meal, entries|
        entries.each do |entry|
          food_attributes = find_food_attributes_for_entry(entry)

          if food_attributes
            # We've found an appropriate food item + weight quantities. Now we add the entry.
            meal_id = MFPScraper::MEAL_IDS[meal]

            attributes = {
              date:    date,
              meal_id: meal_id,
              food_id: food_attributes[:food_id],
              weight_id: food_attributes[:weight_id],
              quantity: food_attributes[:quantity]
            }

            puts "Adding food entry for '#{entry[:description]}' -- Found '#{food_attributes[:food_name]}'"
            puts(attributes.inspect)
            puts

            add_food_entry(attributes)
          end

        end
      end

      return true
    end

    def find_food_attributes_for_entry(entry)
      # Look up food on MFP
      results = search_foods(entry[:description])
      if results.present?

        # Find the first result with appropriate weights,
        # and adjust weights accordingly
        results.first(3).each do |food_name, food_id|
          weight = find_weight_for_food_id_and_entry(food_id, entry)

          if weight
            # If types match or conversion succeeded, return attributes.
            return {
              food_name: food_name,
              food_id: food_id,
              weight_id: weight[:id],
              weight_description: weight[:description],
              quantity: weight[:quantity]
            }
          else
            puts "Could not find any weight for '#{food_name}' (#{food_id}) that matches: #{entry[:serving_type]}"
          end
        end

        puts "Could not find any foods for '#{entry[:description]}', with weights matching: #{entry[:serving_type]}"

      else
        puts "Could not find any foods for '#{entry[:description]}'!"
      end

      return false
    end

    def find_weight_for_food_id_and_entry(food_id, entry)
      weights = weights_for_food_id(food_id)

      # If entry serving type is nil, just take the first weight.
      if entry[:serving_type].nil?
        weight_description, weight_id = weights.first

        return {
          description: weight_description,
          id: weight_id,
          quantity: entry[:serving_quantity]
        }
      end

      weights.each do |weight_description, weight_id|
        weight_serving_text = process_serving_text(weight_description)
        weight_quantity, weight_serving_type = weight_serving_text.scan(/^([^ ]+) (.*)/)[0]

        if weight_serving_type.downcase == 'tbsp'
          weight_serving_type = 'tbs'
        end
        weight_serving_type.downcase!

        if weight_quantity[/\d+\/\d+/]
          weight_quantity = weight_quantity.split('/').map(&:to_f).reduce(:/)
        end
        weight_quantity = weight_quantity.to_f

        # Don't bother with fractional serving quantities
        next if weight_quantity < 1

        serving_quantity = entry[:serving_quantity]

        # If types don't match, try to convert.
        if weight_serving_type != entry[:serving_type]
          serving_quantity = convert_units(weight_serving_type, entry[:serving_type], entry[:serving_quantity])

          # Try next weight if types don't match, and could not convert between types
          next unless serving_quantity
        end

        return {
          description: weight_description,
          id: weight_id,
          quantity: serving_quantity
        }
      end

      return nil
    end


    def parse_food_entries_from_text(text)
      food_entries = {}
      text.scan(/^([^:]*): (.*)$/).each do |meal, food_items_text|
        food_items = food_items_text.split(',').map(&:strip).map do |item|

          serving_text, description = item.scan(/^(.*) of (.*)/)[0]
          if serving_text
            serving_text = process_serving_text(serving_text)
            serving_quantity, serving_type = serving_text.scan(/^([^ ]+) (.*)/)[0]

          else
            # If there is no "of", then first token must be a number
            serving_quantity, description = item.scan(/^([^ ]+) (.*)/)[0]
            serving_quantity = process_serving_text(serving_quantity)
            serving_type = nil
          end

          if serving_quantity[/\d+\/\d+/]
            serving_quantity = serving_quantity.split('/').map(&:to_f).reduce(:/)
          end
          serving_quantity = serving_quantity.to_f

          { serving_type: serving_type, serving_quantity: serving_quantity.to_f, description: description }
        end

        food_entries[meal.strip.downcase.to_sym] = food_items
      end

      food_entries
    end


    private

    def process_serving_text(serving_text)
      serving_text.sub_numbers.
        sub(/half( a)?/, '0.5').
        sub('quarter', '0.25').
        sub(/tablespoons?/, 'tbs').
        sub('cups', 'cup')
    end

    def convert_units(from, to, quantity)
      case from
      when 'cup'
        case to
        when 'bowl'
          return quantity * 1.5
        end
      when 'bowl'
        case to
        when 'cup'
          return quantity / 1.5
        end
      end

      false
    end

  end
end