#!/bin/sh

# perform flutter clean to clean all the current build
flutter clean

# perform the flutter pub get
# flutter pub get

# perform the flutter pub upgrade
# flutter pub upgrade

# rebuild the flutter web apps
flutter build web --release -t lib/main.prod.dart

# build the docker based on the build
docker build -t adimartha/my_expense .

# once finished build then get the current tag from the environment file
tag=`cat conf/.prod.env | sed '2q;d' | awk -F "=" '{print $2}' | sed "s/['\"]//g" | awk -F "-" '{print $1}'`
echo current tag is $tag

# then tag the latest docker image to the current tag
echo tag latest image to $tag
docker image tag adimartha/my_expense:latest adimartha/my_expense:$tag

# push both of the image to the docker repo
echo push latest docker image
docker image push adimartha/my_expense:latest

echo push $tag docker image
docker image push adimartha/my_expense:$tag