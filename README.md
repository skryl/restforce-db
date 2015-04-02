# Restforce::DB

Restforce::DB is an attempt at simplifying data integrations between a Salesforce setup and a Rails application. It provides a background worker which continuously polls for updated records both in Salesforce and in the database, and updates both systems with that data according to user-defined attribute mappings.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "restforce-db"
```

And then execute:

    $ bundle

## Usage

First, you'll want to install the default bin and configuration files, which is handled by the included Rails generator:

    $ bundle exec rails g restforce:install

This gem assumes that you're running Rails 4 or greater, therefore the `bin` file should be checked into the repository with the rest of your code. The `config/restforce-db.yml` file should be managed the same way you manage your secrets files, and probably not checked into the repository.

### Update your model schema

In order to keep your database records in sync with Salesforce, the table will need to store a reference to its associated Salesforce record. A generator is included to trivially add a generic `salesforce_id` column to your tables:

    $ bundle exec rails g restforce:migration MyModel
    $ bundle exec rake db:migrate

If you need to activate multiple Salesforce mappings within a single model, you can do this with scoped column names. For example, if your Salesforce object types are named "Animal__c" and "Cat__c", `Restforce::DB` will look for columns named `animal_salesforce_id` and `cat_salesforce_id`.

### Register a mapping

To register a Salesforce mapping in an `ActiveRecord` model, you'll need to add a few lines of DSL-style code to the relevant class definitions:

```ruby
class Restaurant < ActiveRecord::Base

  include Restforce::DB::Model
  has_one :specialty, class_name: "Dish"

  sync_with(
    "Restaurants__c",
    fields: {
      name:  "Name",
      style: "Style__c",
    },
    associations: {
      specialty: "Specialty__c",
    },
  )

end

class Dish < ActiveRecord::Base

  include Restforce::DB::Model
  belongs_to :restaurant

  sync_with(
    "Dish__c",
    through: "Specialty__c",
    fields: {
      name:       "Name",
      ingredient: "Ingredient__c",
    },
  )
end
```

This will automatically register the models with entries in the `Restforce::DB::Mapping` collection. This collection defines the manner in which the database and Salesforce systems will be synchronized.

There are a few options to be aware of when describing a mapping:

- `fields`: These are direct field-to-field mappings. The keys should line up with your ActiveRecord attribute names, while the values should line up with the matching field names in Salesforce.
- `associations`: These are mappings of ActiveRecord associations to Salesforce lookups. Associations defined here will be built as part of the creation process for a newly-synced record. 
- `through`: This should be set for models which are created through an association. It references the lookup field on its parent's Salesforce object type.

### Run the daemon

To actually perform this system synchronization, you'll want to run the binstub installed through the generator (see above). This will daemonize a process which loops repeatedly to continuously synchronize your database and your Salesforce account, according to the established mappings.

    $ bundle exec bin/restforce-db start

By default, this will load the credentials at the same location the generator installed them. You can explicitly pass the location of your configuration file with the `-c` option:

    $ bundle exec bin/restforce-db -c /path/to/my/config.yml start

For additional information and a full set of options, you can run:

    $ bundle exec bin/restforce-db -h

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Caveats

- **Update Prioritization.** When synchronization occurs, newly-updated records in Salesforce are prioritized over newly-updated database records. This means that any changes to records in the database may be overwritten if changes were made to the Salesforce at the same time.
- **API Usage.** This gem performs most of its functionality via the Salesforce API (by way of the [`restforce`](https://github.com/ejholmes/restforce) gem). If you're at risk of hitting your Salesforce API limits, this may not be the right approach for you.

## Contributing

1. Fork it ( https://github.com/tablexi/restforce-db/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Ensure that your changes pass all style checks and tests (`rake`)
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create a new Pull Request
