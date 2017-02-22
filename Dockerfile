FROM jruby:9.1-onbuild
RUN bundle exec rake spec
FROM ruby:1.9-onbuild
RUN bundle exec rake spec
FROM ruby:2.0-onbuild
RUN bundle exec rake spec
FROM ruby:2.1-onbuild
RUN bundle exec rake spec
FROM ruby:2.2-onbuild
RUN bundle exec rake spec
FROM ruby:2.3-onbuild
RUN bundle exec rake spec
