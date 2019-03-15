#!/usr/bin/env bash

set -ex

VERSION=$1

if [ "" == "$VERSION" ]; then
    echo "Failed to specify version required"
    exit 1
fi

mkdir -p h3/out
rm -rf h3c
git clone https://github.com/uber/h3.git h3c

pushd h3c
git pull origin master --tags
git checkout "$VERSION"

if command -v make; then
  # Run CMake, installing a recent version if not found or not compatible
  {
    cmake -DENABLE_FORMAT=OFF -DBUILD_SHARED_LIBS=ON .
  } || {
    # Install modern CMake
    mkdir cmake-download
    pushd cmake-download
    curl -O https://cmake.org/files/v3.10/cmake-3.10.0-rc5-Linux-x86_64.sh
    bash cmake-3.10.0-rc5-Linux-x86_64.sh --skip-license
    export PATH=`pwd`/bin:$PATH
    echo $PATH
    popd
    cmake -DENABLE_FORMAT=OFF -DBUILD_SHARED_LIBS=ON .
  }

  make
  ls -l lib/libh3*
  cp lib/libh3* ../h3/out
  if [ -e ../build ] && [ -d ../build ]; then
      LIBNAME=`ls ../build/ | grep '^lib'`
      mkdir -p ../build/$LIBNAME/h3/out
      cp lib/libh3* ../build/$LIBNAME/h3/out
  fi
else
  if [[ "$PYTHON_ARCH" == "64" ]]; then
    cmake . -DENABLE_FORMAT=OFF -DBUILD_SHARED_LIBS=ON -DCMAKE_VS_PLATFORM_NAME=$PLATFORM -G "Visual Studio 14 Win64" && cmake --build . --target h3 --config Release;
  else
    cmake . -DENABLE_FORMAT=OFF -DBUILD_SHARED_LIBS=ON -DCMAKE_VS_PLATFORM_NAME=$PLATFORM && cmake --build . --target h3 --config Release;
  fi
  ls -l bin/Release/*
  cp bin/Release/h3.dll ../h3/out
fi
popd
rm -rf h3c
