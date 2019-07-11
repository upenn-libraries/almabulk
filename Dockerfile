FROM ruby:2.5.1-slim

MAINTAINER Christopher Clement <clemenc@upenn.edu>

EXPOSE 9292

RUN apt-get update && apt-get install -qq -y --no-install-recommends \
         build-essential \
         libpq-dev

RUN mkdir -p /usr/src/app

WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock /usr/src/app/

RUN bundle install

COPY app.rb config.ru /usr/src/app/
COPY public/ /usr/src/app/public/
COPY views/ /usr/src/app/views/

RUN rm -rf /var/lib/apt/lists/*

CMD ["bundle", "exec", "rackup", "-o", "0.0.0.0"]
