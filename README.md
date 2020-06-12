# Strategic Review of Charges - Tactical Charging Module

The Tactical Charging Module (TCM) is a web application designed to enable billing adminstrators to apply new categories to permit charges to enable correct amounts to be processed.

This service is an internally facing service only, used by billing administration staff.  Despite being a tactical solution the system is developed in accordance with the [Digital by Default service standard](https://www.gov.uk/service-manual/digital-by-default), where possible, putting user needs first and delivered iteratively.

The application sends emails using the Send-grid e-mail service.

## Development Environment

## Install global system dependencies

The following system dependencies are required, regardless of how you install the development environment.

* [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)

### Obtain the source code

Clone the repository, copying the project into a working directory:

    git clone https://github.com/DEFRA/sroc-tcm-admin.git
    cd sroc-tcm-admin

The TCM application relies on the [sroc-charging-service](https://github.com/DEFRA/sroc-charging-service) to communicate with an externally hosted Rules Execution service enabling the calculation of new permit charges.

The SRoC Charging Service should be configured and running on the local system and be able to communicate with an instance of the Rules Execution Service if you wish to generate charges.

### Local Installation

#### Local system dependencies

* [Ruby 2.4.x](https://www.ruby-lang.org) (e.g. via [RVM](https://rvm.io) or [Rbenv](https://github.com/sstephenson/rbenv/blob/master/README.md))
* [Postgresql](http://www.postgresql.org/download)
* [Redis](https://redis.io)
* [Phantomjs](https://github.com/teampoltergeist/poltergeist#installing-phantomjs) (test specs)

#### Application gems _(local)_

Run the following to download the app dependencies ([rubygems](https://www.ruby-lang.org/en/libraries/))

```sh
cd sroc-tcm-admin
gem install bundler
bundle install
```

#### .env configuration file

The project uses the [dotenv](https://github.com/bkeepers/dotenv)
gem which allows enviroment variables to be loaded from a
`.env` configuration file in the project root.

Duplicate `./dotenv.example` and rename the copy as `./.env`.
Open it and update `SECRET_KEY_BASE` and settings for database, email etc.


#### Databases _(local)_

There are several databases per environment, therefore, ensure you run the following:

```sh
bundle exec rake db:create:all
bundle exec rake db:migrate
bundle exec rake db:seed
```

#### Start the service _(local)_

To start the service locally simply run:

    bundle exec rails server

You can then access the web site at http://localhost:3000

#### Intercepting email in development

You can use mailcatcher to trap and view outgoing email.

Make sure you have the following in your `.env` or `.env.development` file:

```conf
EMAIL_USERNAME=''
EMAIL_PASSWORD=''
EMAIL_APP_DOMAIN=''
EMAIL_HOST='localhost'
EMAIL_PORT='1025'
```

Start mailcatcher with `$ mailcatcher` and navigate to
[http://127.0.0.1:1080](http://127.0.0.1:1080) in your browser.

Note that [mail_safe](https://github.com/myronmarston/mail_safe) maybe also be running in which
case any development email will seem to be sent to your global git config email address.


##### To create and use a new user

1. add a user to the DB with desired details: role:1 active_regime:1
2. add row to regime_users
3. start mailcatcher
4. go through reset password flow

## Quality

We use tools like [rubocop](https://github.com/bbatsov/rubocop), [brakeman](https://github.com/presidentbeef/brakeman) to help maintain quality, reusable code.


## Tests

We use [minitest](https://github.com/seattlerb/minitest) for unit testing.

### Test database seeding

Before executing the tests for the first time, you will need to seed the database:

    bundle exec rake db:seed RAILS_ENV=test

To execute the unit tests simply enter:

    bundle exec rails test


## Contributing to this project

If you have an idea you'd like to contribute please log an issue.

All contributions should be submitted via a pull request.

## License

THIS INFORMATION IS LICENSED UNDER THE CONDITIONS OF THE OPEN GOVERNMENT LICENCE found at:

http://www.nationalarchives.gov.uk/doc/open-government-licence/version/3

The following attribution statement MUST be cited in your products and applications when using this information.

> Contains public sector information licensed under the Open Government license v3

### About the license

The Open Government Licence (OGL) was developed by the Controller of Her Majesty's Stationery Office (HMSO) to enable information providers in the public sector to license the use and re-use of their information under a common open licence.

It is designed to encourage use and re-use of information freely and flexibly, with only a few conditions.
