#!/bin/bash
set -euo pipefail

VERSION=$1
TIME=$(date +%s)

if [ -z "$VERSION" ]; then
	echo "You must call this script with a version as first argument"
	exit 1
fi

cd ui/src && npm run build && cd ../../

rm -rf build
mkdir build

go generate github.com/shimberger/gohls/internal/api

function make_release() {
	NAME=$1
	GOOS=$2
	GOARCH=$3
	SUFFIX=$4
	EXTRA_ENV=${5:-}
	RELEASE_PATH=build/gohls-$NAME-${VERSION}
	RELEASE_FILE=gohls-$NAME-${VERSION}.tar.gz
	mkdir $RELEASE_PATH
	cp README.md $RELEASE_PATH
	cp LICENSE.txt $RELEASE_PATH
	echo $GOOS
	echo $GOARCH
	cat internal/buildinfo/buildinfo.go.in | sed "s/##VERSION##/${VERSION}/g" | sed "s/##COMMIT##/$(git rev-parse HEAD)/g" | sed "s/##BUILD_TIME##/$TIME/g" > internal/buildinfo/buildinfo.go
	env GOOS="$GOOS" GOARCH="$GOARCH" $EXTRA_ENV go build -o $RELEASE_PATH/gohls${SUFFIX} *.go
	PREV_WD=$(pwd)
	cd  $RELEASE_PATH
	tar cvfz ../$RELEASE_FILE .
	cd ../../
}

make_release "osx" "darwin" "amd64" ""
make_release "osx-arm64" "darwin" "arm64" ""
make_release "linux-386" "linux" "386" ""
make_release "linux-amd64" "linux" "amd64" ""
make_release "linux-armv6" "linux" "arm" "" "GOARM=6"
make_release "linux-armv7" "linux" "arm" "" "GOARM=7"
make_release "linux-arm64" "linux" "arm64" ""
make_release "windows-386" "windows" "386" ".exe"
make_release "windows-amd64" "windows" "amd64" ".exe"
make_release "windows-arm64" "windows" "arm64" ".exe"
make_release "freebsd-amd64" "freebsd" "amd64" ""
make_release "freebsd-arm64" "freebsd" "arm64" ""
