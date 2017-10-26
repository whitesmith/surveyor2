# Surveyor2

Fork of [surveyor](https://github.com/NUBIC/surveyor) to be compatible with rails 5 and more modern

Still a work in progress

### Installation

`gem 'surveyor2', require: 'surveyor'`

### Requirements

* `Ruby >= 2.2.0`
* `Rails >= 4.0 `

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

### Development

Clone, test with docker by running the `docker-ci` script in the `bin/` folder from the root directory, example:

To run rake spec, with ruby `2.4` and rails `5.1` do:

`./bin/docker-ci 2.4 spec 5.1`

For usage instructions run the script without any arguments

`./bin/docker-ci`
