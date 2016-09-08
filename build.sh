#!/bin/bash -x

# this is just a devel script, it's not used in teamcity

pushd ruby

gem build vm-builder.gemspec
mv *.gem ../docker

popd
pushd docker

docker build -t vm-builder .
