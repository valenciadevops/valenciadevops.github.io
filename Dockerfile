FROM ruby:3.4
WORKDIR /app

RUN apt-get update && apt-get install -y nodejs

COPY Gemfile Gemfile.lock /app
RUN bundle install

COPY . /app
RUN bundle exec nanoc
CMD bundle exec nanoc view --host 0.0.0.0
