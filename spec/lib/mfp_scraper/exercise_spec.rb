require 'spec_helper'

# This is an integration test to ensure that exercises can be
# added, fetched, updated, and deleted.
describe MFPScraper::Exercise, :vcr do
  before :all do
    @mfp = authenticated_client
  end

  let(:moves_cycling_description) { "Moves - Cycling" }
  let(:moves_cycling_exercise_id) { 38869108 }
  let(:start_time) { Time.now }

  it 'should be able to add, fetch, update, and delete an exercise' do
    # Add entry
    expect(
      @mfp.add_exercise_entry(
        exercise_id: moves_cycling_exercise_id,
        start_time:  start_time,
        minutes:     24,
        calories:    234
      )
    ).to eq true

    # Fetch entries
    exercises = @mfp.fetch_exercise_diary
    exercise  = exercises["Cardiovascular"].find {|e| e[:description] == moves_cycling_description }
    expect(exercise).to_not eq nil
    expect(exercise[:minutes]).to  eq 24
    expect(exercise[:calories]).to eq 234

    # Update entry
    expect(
      @mfp.update_exercise_entry(
        entry_id: exercise[:entry_id],
        minutes:  32,
        calories: 345
      )
    ).to eq true

    # Fetch entries
    exercises = @mfp.fetch_exercise_diary
    exercise  = exercises["Cardiovascular"].find {|e| e[:description] == moves_cycling_description }
    expect(exercise).to_not eq nil

    expect(exercise[:minutes]).to  eq 32
    expect(exercise[:calories]).to eq 345

    # Delete entry
    expect(
      @mfp.delete_exercise_entry(exercise[:entry_id])
    ).to eq true

    # Fetch entries
    exercises = @mfp.fetch_exercise_diary
    exercise  = exercises["Cardiovascular"].find {|e| e[:description] == moves_cycling_description }
    expect(exercise).to eq nil
  end
end
