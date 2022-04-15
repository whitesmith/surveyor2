# Surveyor2

![Continuous Integration](https://github.com/whitesmith/surveyor2/actions/workflows/build.yml/badge.svg)

Fork of [surveyor](https://github.com/NUBIC/surveyor) to be compatible with rails 5 and more modern

Still a work in progress

### Installation

`gem 'surveyor2', require: 'surveyor'`

### Requirements

* `Ruby >= 2.7.0`
* `Rails >= 5.1`

### TODO

* [X] Models
* [X] Translations
* [X] Parser
* [X] Generators
  * [X] Migrations
  * [X] Routes
  * [X] Controller
  * [X] Views
  * [X] Example Survey
* [X] Tasks
  * [ ] Update from Surveyor
  * [X] Parse
  * [ ] Unparse
  * [X] Remove
  * [X] Dump
* [X] Controller
* [ ] Unparser
* [ ] Views
  * [X] Index
  * [ ] Show
  * [ ] Answer

### Improvement to dependencies

A couple of improvement have been made to the original surveyor dependency strings:

* Accept parenthesis
* Accept negations

A couple of examples of possible dependencies strings now:

* `A and B`
* `(A and B) or C`
* `!(A and !B) or C`
* `(!(A and B) and C or !(D or !E) and F) and !(C or B)`

### Development

Clone, test with docker by running the `docker-ci` script in the `bin/` folder from the root directory, example:

To run rake spec, with ruby `2.7` and rails `6.1` do:

`./bin/docker-ci 2.7 spec 6.1`

For usage instructions run the script without any arguments

`./bin/docker-ci`

## Dummy Apps

The test suite makes use of dummy apps to test the installation of surveyor on a "real" app.

If you need to add a new version, do the following:

1. Generate a minimal rails app with the target version
  ```
    rails _RAILS_VERSION_ new --skip-gemfile --skip-javascript--skip-webpack-install --skip-bootsnap --skip-turbolinks --skip-jbuilder --skip-test --skip-system-test --skip-listen --skip-spring --skip-sprockets --skip-action-cable --skip-active-job --skip-active-storage --skip-action-text --skip-action-mailbox --skip-action-mailer --skip-hotwire
  ```
  Where `_RAILS_VERSION_` will be something like `_7.0.1_`.
2. Copy over `app/assets/images/rails.png` from a previous dummy (there's a test that involves loading of images from the app)
3. Run `rails db:create db:migrate` on the dummy app folder to create the schema file`
4. Add `require "surveyor"` on config/application.rb.
5. On most recent versions of Rails (7.0 onwards), `sprockets-rails` is not included by default, so we need to remove references to `config.assets` in some places.