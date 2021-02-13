#!/usr/bin/env bash

docker-compose down --remove-orphans

rm -rf ./docker/logs/*
rm -rf ./docker/run/var/*
rm -rf ./docker/wp-uploads/*
rm ./wp-config.php

docker-compose build --no-cache && docker-compose up
