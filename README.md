# README for `almabulk`

Almabulk is a Sinatra application that supports bulk item data export and bulk item data updates for a given Alma instance.

## Requirements

* Ruby 2.3.1 or higher
* An Alma API key with write access to Bibs API
* Docker for production and docker-compose version 2 or higher

## Functionalities

The application supports the following features:

* `bulk item metadata export` - export item data to a spreadsheet given an MMSID and holding ID
* `bulk item metadata update` - update item data by uploading a spreadsheet of item data typically modified from an export

## Development Setup

* Clone the repository.
* Run ```bundle install```
* Copy ```.env.example``` into a file alongside it called ```.env```
* Populate the new file with a valid Alma API key
* Run ```dotenv rackup```
* Visit [http://localhost:9292](http://localhost:9292) to access export/update functionality

## Production Setup

* Clone the repository.
* Copy ```.env.example``` into a file alongside it called ```.env```
* Populate the new file with a valid Alma API key
* Run ```docker build -t almabulk:latest .```
* Run ```docker-compose up```
* Visit [http://localhost:9292](http://localhost:9292) to access export/update functionality

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/upenn-libraries/almabulk](https://github.com/upenn-libraries/almabulk).

## License

This code is available as open source under the terms of the [Apache 2.0 License](https://opensource.org/licenses/Apache-2.0).
