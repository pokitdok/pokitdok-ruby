#!/bin/bash

for VERSION in 1.9 2.0 2.1 2.2 2.3
do
  docker run --rm -it \
  --env-file ./env.list \
  -v $PWD:/app/pokitdok ruby:$VERSION \
  /bin/sh /app/pokitdok/setup_and_test.sh
done

for VERSION in J9.1
do
  docker run --rm -it \
  --env-file ./env.list \
  -v $PWD:/app/pokitdok jruby:$VERSION \
  /bin/sh /app/pokitdok/setup_and_test.sh
done