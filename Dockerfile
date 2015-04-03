FROM ruby:2.2.1-wheezy

ADD lennart.rb /
ADD Gemfile /
ADD Gemfile.lock /

RUN bundle install
CMD bundle exec ruby lennart.rb