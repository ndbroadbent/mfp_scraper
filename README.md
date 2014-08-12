# MFPScraper

Because MyFitnessPal is taking forever to open up their API.

## Installation

Add this line to your application's Gemfile:

    gem 'mfp_scraper'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mfp_scraper

## Usage

Initialize a new scraper:

```
require 'mfp_scraper'
mfp = MFPScraper.new(username: 'username', password: 'password')
```

Just check out the methods in `./lib/mfp_scraper/food.rb`.

### Batch import:

Add some batch entries from formatted text. You should be able to dictate
most items to Siri. You can say things like "colon", "comma", 
and "new paragraph" to format the output.

Example:

```
text = <<EOM
Breakfast: one mocha, one bowl of chex cereal, 1.5 cups of 2% milk, one cup of orange juice
Lunch: two cups of caesar salad
Dinner: 1 bacon cheeseburger
Snacks: one mocha
EOM

mfp.add_food_entries_from_text(text, Date.today)
```


## Contributing

1. Fork it ( http://github.com/<my-github-username>/mfp_scraper/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
