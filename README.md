# DB Fuel

[![CircleCI](https://circleci.com/bb/bluemarble-ondemand/db_fuel/tree/master.svg?style=svg&circle-token=f1b2aed3fa173235db39da671c5b5db22e061609)](https://circleci.com/bb/bluemarble-ondemand/db_fuel/tree/master)

This library is a plugin for [Burner](https://github.com/bluemarblepayroll/burner).  Burner, by itself, cannot use a database.  So, if you wish to use a database as a data source or as a target for mutation then you need to add a library similar to this.

## Installation

To install through Rubygems:

````bash
gem install db_fuel
````

You can also add this to your Gemfile:

````bash
bundle add db_fuel
````

## Jobs

Refer to the [Burner](https://github.com/bluemarblepayroll/burner) library for more specific information on how Burner works.  This section will just focus on what this library directly adds.

### ActiveRecord Jobs

* **db_fuel/active_record/find_or_insert** [name, table_name, attributes, debug, primary_keyed_column, keys_register, register, separator, timestamps, unique_attributes]: An extension of the `db_fuel/active_record/insert` job that adds an existence check before SQL insertion. The  `unique_attributes` will be converted to WHERE clauses for performing the existence check.
* **db_fuel/active_record/insert** [name, table_name, attributes, debug, primary_keyed_column, keys_register, register, separator, timestamps]: This job can take the objects in a register and insert them into a database table.  If primary_keyed_column is specified then its key will be set to the primary key.  Note that composite primary keys are not supported.  Attributes defines which object properties to convert to SQL.  Refer to the class and constructor specification for more detail.
* **db_fuel/active_record/update_all** [name, table_name, attributes, debug, keys_register, register, separator, timestamps, unique_attributes]: This job can take the objects in a register and updates them within a database table.  Attributes defines which object properties to convert to SQL SET clauses while unique_attributes translate to WHERE clauses. One or more records may be updated at a time.  Refer to the class and constructor specification for more detail.
* **db_fuel/active_record/update** [name, table_name, attributes, debug, keys_register, register, primary_keyed_column, separator, timestamps, unique_attributes]: This job can take the unique objects in a register and updates them within a database table.  Attributes defines which object properties to convert to SQL SET clauses while unique_attributes translate to WHERE clauses to find the records to update. The primary_keyed_column is used to update the unique record. Only one record will be updated per statement. Note that composite primary keys are not supported.  Refer to the class and constructor specification for more detail.
* **db_fuel/active_record/upsert** [name, table_name, attributes, debug, primary_keyed_column, keys_register, register, separator, timestamps, unique_attributes]: This job can take the objects in a register and either inserts or updates them within a database table.  Attributes defines which object properties to convert to SQL SET clauses while each key in unique_attributes become a WHERE clause in order to check for the existence of a specific record. The updated record will use the primary_keyed_column specified to perform the UPDATE operation. Note that composite primary keys are not supported. Refer to the class and constructor specification for more detail.

### Dbee Jobs

* **db_fuel/dbee/query** [model, query, register, debug]:  Pass in a [Dbee](https://github.com/bluemarblepayroll/dbee) model and query and store the results in the specified register.  Refer to the [Dbee](https://github.com/bluemarblepayroll/dbee) library directly on how to craft a model or query.
* **db_fuel/dbee/range** [key, key_path, model, query, register, separator, debug]: Similar to `db_fuel/dbee/query` with the addition of being able to grab a list of values from the register to use as a Dbee EQUALS/IN filter.  This helps to dynamically limit the resulting record set.  The key is used to specify where to grab the list of values, while the key_path will be used to craft the [Dbee equal's filter](https://github.com/bluemarblepayroll/dbee/blob/master/lib/dbee/query/filters/equals.rb).  Separator is exposed in case nested object support is necessary.

## Examples

In all the examples we will assume we have the following schema:

````ruby
ActiveRecord::Schema.define do
  create_table :statuses do |t|
    t.string  :code,     null: false, limit: 25
    t.integer :priority, null: false, default: 0
    t.timestamps
  end

  create_table :patients do |t|
    t.string     :chart_number
    t.string     :first_name
    t.string     :middle_name
    t.string     :last_name
    t.references :status
    t.timestamps
  end
end
````

### Querying the Database

The `db_fuel/dbee/query` job can be utilized to process a SQL query and store the results in a Burner::Payload register.

Let's say for example we have a list of patients we would like to retrieve:

````ruby
pipeline = {
  jobs: [
    {
      name: 'retrieve_patients',
      type: 'db_fuel/dbee/query',
      model: {
        name: :patients
      },
      query: {
        fields: [
          { key_path: :id },
          { key_path: :first_name }
        ],
        sorters: [
          { key_path: :first_name }
        ]
      },
      register: :patients
    }
  ]
}

payload = Burner::Payload.new

Burner::Pipeline.make(pipeline).execute(payload: payload)
````

If we were to inspect the contents of `payload` we should see the patient's result set loaded:

````ruby
payload['patients'] # array in form of: [ { "id" => 1, "first_name" => "Something" }, ... ]
````

Notes

* Set `debug: true` to print out SQL statement in the output (not for production use.)

### Limiting Result Sets

The `db_fuel/dbee/query` does not provide a way to dynamically connect the query to existing data.  You are free to put any Dbee query filters in the query declaration, but what if you would like to further limit this based on the knowledge of a range of values?  The `db_fuel/dbee/range` job is meant to do exactly this.  On the surface it is mainly an extension of the `db_fuel/dbee/query` job.

Let's say we would like to query patients but we want to limit it to an inputted list of first names:

````ruby
pipeline = {
  jobs: [
    {
      name: :load_first_names,
      type: 'b/value/static',
      register: :patients,
      value: [
        { fname: 'Bozo' },
        { fname: 'Bugs' },
      ]
    },
    {
      name: 'retrieve_patients',
      type: 'db_fuel/dbee/range',
      model: {
        name: :patients
      },
      query: {
        fields: [
          { key_path: :id },
          { key_path: :first_name }
        ],
        sorters: [
          { key_path: :first_name }
        ]
      },
      register: :patients,
      key: :fname,
      key_path: :first_name
    }
  ]
}

payload = Burner::Payload.new

Burner::Pipeline.make(pipeline).execute(payload: payload)
````

If we were to inspect the contents of `payload` we should see the patient's result set loaded:

````ruby
payload['patients'] # array in form of: [ { "id" => 1, "first_name" => "Something" }, ... ]
````

The only difference between the query and range jobs should be the latter is limited based on the incoming first names.

Notes

* Set `debug: true` to print out SQL statement in the output (not for production use.)

### Updating the Database

#### Inserting Records

We can deal with persistence using the db_fuel/active_record/* jobs.  In order to insert new records we can use the `db_fuel/active_record/insert` job.  For example:

````ruby
pipeline = {
  jobs: [
    {
      name: :load_patients,
      type: 'b/value/static',
      register: :patients,
      value: [
        { chart_number: 'B0001', first_name: 'Bugs', last_name: 'Bunny' },
        { chart_number: 'B0002', first_name: 'Babs', last_name: 'Bunny' }
      ]
    },
    {
      name: 'insert_patients',
      type: 'db_fuel/active_record/insert',
      register: :patients,
      attributes: [
        { key: :chart_number },
        { key: :first_name },
        { key: :last_name }
      ],
      table_name: 'patients',
      primary_keyed_column: {
        key: :id
      }
    }
  ]
}

payload = Burner::Payload.new

Burner::Pipeline.make(pipeline).execute(payload: payload)
````

There should now be two new patients, AB0 and AB1, present in the table `patients`.

Notes:

* Since we specified the `primary_keyed_column`, the records' `id` attributes should be set to their respective primary key values.
* Composite primary keys are not currently supported.
* Set `debug: true` to print out each INSERT statement in the output (not for production use.)

#### Inserting Only New Records

Another job `db_fuel/active_record/find_or_insert` allows for an existence check to performed each insertion.  If a record is found then it will not insert the record.  If `primary_keyed_column` is set then the existence check will also still set the primary key on the payload's respective object.  Note that composite primary keys are not currently supported. We can build on the above insert example for only inserting new patients if their chart_number is unique:

````ruby
pipeline = {
  jobs: [
    {
      name: :load_patients,
      type: 'b/value/static',
      register: :patients,
      value: [
        { chart_number: 'B0001', first_name: 'Bugs', last_name: 'Bunny' },
        { chart_number: 'B0002', first_name: 'Babs', last_name: 'Bunny' }
      ]
    },
    {
      name: 'insert_patients',
      type: 'db_fuel/active_record/insert',
      register: :patients,
      attributes: [
        { key: :chart_number },
        { key: :first_name },
        { key: :last_name }
      ],
      table_name: 'patients',
      primary_keyed_column: {
        key: :id
      },
      unique_attributes: [
        { key: :chart_number }
      ]
    }
  ]
}

payload = Burner::Payload.new

Burner::Pipeline.make(pipeline).execute(payload: payload)
````

Now only records where the chart_number does not match an existing record will be inserted.

#### Updating Records

Let's say we now want to update these unique records' last names:

````ruby
pipeline = {
  jobs: [
    {
      name: :load_patients,
      type: 'b/value/static',
      register: :patients,
      value: [
        { chart_number: 'B0001', last_name: 'Fox' },
        { chart_number: 'B0002', last_name: 'Smurf' }
      ]
    },
    {
      name: 'update_patients',
      type: 'db_fuel/active_record/update',
      register: :patients,
      attributes: [
        { key: :last_name }
      ],
      table_name: 'patients',
      primary_keyed_column: {
        key: :id
      },
      unique_attributes: [
        { key: :chart_number }
      ]
    }
  ]
}

payload = Burner::Payload.new

Burner::Pipeline.make(pipeline).execute(payload: payload)
````

Each database record should have been updated with their new respective last names based on the primary key specified.

#### Updating All Records

Let's say we want to update those records' midddle names:

````ruby
pipeline = {
  jobs: [
    {
      name: :load_patients,
      type: 'b/value/static',
      register: :patients,
      value: [
        { chart_number: 'B0001', middle_name: 'Rabbit' },
        { chart_number: 'C0001', middle_name: 'Elf' }
      ]
    },
    {
      name: 'update_patients',
      type: 'db_fuel/active_record/update_all',
      register: :patients,
      attributes: [
        { key: :last_name }
      ],
      table_name: 'patients',
      unique_attributes: [
        { key: :chart_number }
      ]
    }
  ]
}

payload = Burner::Payload.new

Burner::Pipeline.make(pipeline).execute(payload: payload)
````

Each database record should have been updated with their new respective middle names based on chart_number.

#### Upserting Records

Let's say we don't know if these chart_number values already exist or not.
So we want db_fuel to either insert a record if the chart_number doesn't exist or update the record if the chart_number already exists.

````ruby
pipeline = {
  jobs: [
    {
      name: :load_patients,
      type: 'b/value/static',
      register: :patients,
      value: [
        { chart_number: 'B0002', first_name: 'Babs', last_name: 'Bunny' },
        { chart_number: 'B0003', first_name: 'Daffy', last_name: 'Duck' }
      ]
    },
    {
      name: 'update_patients',
      type: 'db_fuel/active_record/upsert',
      register: :patients,
      attributes: [
        { key: :chart_number },
        { key: :first_name },
        { key: :last_name }
      ],
      table_name: 'patients',
      primary_keyed_column: {
        key: :id
      },
      unique_attributes: [
        { key: :chart_number }
      ]
    }
  ]
}

payload = Burner::Payload.new

Burner::Pipeline.make(pipeline).execute(payload: payload)
````

Each database record should have been either inserted or updated with their corresponding values. In this case Babs' last name
was switched back to Bunny and a new record was created for Daffy Duck.

Notes:

* The `unique_attributes` translate to WHERE clauses.
* Set `debug: true` to print out each UPDATE statement in the output (not for production use.)

#### Limiting The Columns Being Inserted/Updated

All the db_fuel/active_record/* jobs now feature an optional `keys_register` option.  If this is set, the register will be read and used as a key filter for which fields to set.  For example, if you configure a db_fuel/active_record/insert job to update A, B, C, and D, but your keys_register contains [A,B] then only A and B will be inserted/set.  This is helpful in scenarios where you may want to outline how to update _all_ possible fields but your input set only contains a subset of those fields and you do not wish to set the others to null.
## Contributing

### Development Environment Configuration

Basic steps to take to get this repository compiling:

1. Install [Ruby](https://www.ruby-lang.org/en/documentation/installation/) (check db_fuel.gemspec for versions supported)
2. Install bundler (gem install bundler)
3. Clone the repository (git clone git@github.com:bluemarblepayroll/db_fuel.git)
4. Navigate to the root folder (cd db_fuel)
5. Install dependencies (bundle)

### Running Tests

To execute the test suite run:

````bash
bundle exec rspec spec --format documentation
````

Alternatively, you can have Guard watch for changes:

````bash
bundle exec guard
````

Also, do not forget to run Rubocop:

````bash
bundle exec rubocop
````

### Publishing

Note: ensure you have proper authorization before trying to publish new versions.

After code changes have successfully gone through the Pull Request review process then the following steps should be followed for publishing new versions:

1. Merge Pull Request into master
2. Update `version.rb` using [semantic versioning](https://semver.org/)
3. Install dependencies: `bundle`
4. Update `CHANGELOG.md` with release notes
5. Commit & push master to remote and ensure CI builds master successfully
6. Run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Code of Conduct

Everyone interacting in this codebase, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/bluemarblepayroll/db_fuel/blob/master/CODE_OF_CONDUCT.md).

## License

This project is MIT Licensed.
