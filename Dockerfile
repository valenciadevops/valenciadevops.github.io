FROM ruby:3.3
WORKDIR /app

COPY Gemfile Gemfile.lock /app
RUN bundle install
RUN apt-get update && apt-get install -y nodejs

COPY . /app
RUN bundle exec nanoc
