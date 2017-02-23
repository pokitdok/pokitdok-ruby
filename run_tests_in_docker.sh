#!/bin/bash

for VERSION in J9.1 1.9 2.0 2.1 2.2 2.3
do
    docker build -f Dockerfile-$VERSION .
done