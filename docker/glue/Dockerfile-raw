FROM ruby:2.4-alpine

LABEL maintainer="mkonda@jemurai.com"
LABEL maintainer="omer.levihevroni@owasp.org"

WORKDIR /glue

RUN apk add --update build-base curl-dev

COPY Gemfile Gemfile.lock glue.gemspec /glue/
COPY ./bin/glue /glue/bin/glue
COPY ./lib/glue/version.rb /glue/lib/glue/

RUN bundle install --without development test

COPY /lib /glue/lib

CMD ./bin/glue