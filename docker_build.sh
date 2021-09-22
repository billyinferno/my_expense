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
