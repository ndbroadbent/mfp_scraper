require 'spec_helper'

# This is an integration test to ensure that exercises can be
# added, fetched, updated, and deleted.
describe MFPScraper::Food, :vcr do
  before :all do
    @mfp = authenticated_client
  end

  let(:food_description) { "Starbucks - Mocha Tall" }
  let(:food_id) { 134750757 }
  let(:food_weight_id) { 187219924 }

  it 'should be able to add, fetch, update, and delete a food entry' do
    # Add entry
    expect(
      @mfp.add_food_entry(
        food_id:   food_id,
        quantity:  1,
        weight_id: food_weight_id,
        meal_id:   MFPScraper::MEAL_IDS[:breakfast]
      )
    ).to eq true

    # Fetch entries
    food_entries = @mfp.fetch_food_diary
    entry  = food_entries["Breakfast"].find {|e| e[:description] == food_description }
    expect(entry).to_not eq nil
    expect(entry[:serving_size]).to eq "12 oz"

    # Update entry
    expect(
      @mfp.update_food_entry(
        entry_id: entry[:entry_id],
        quantity:  2
      )
    ).to eq true

    # Fetch entries
    food_entries = @mfp.fetch_food_diary
    entry  = food_entries["Breakfast"].find {|e| e[:description] == food_description }
    expect(entry).to_not eq nil
    expect(entry[:serving_size]).to eq "24 oz"

    # Delete entry
    expect(
      @mfp.delete_food_entry(entry[:entry_id])
    ).to eq true

    # Fetch entries
    food_entries = @mfp.fetch_food_diary
    entry  = food_entries["Breakfast"].find {|e| e[:description] == food_description }
    expect(entry).to eq nil
  end
end
