FROM ruby:slim
MAINTAINER Duncan Rutland <duncan.rutland@gmail.com>

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app
ADD trinity.tar /usr/src/app

RUN bundle install --deployment

EXPOSE 80
CMD ["bundle", "exec", "ruby", "app.rb", "-p 80"]
