#! /bin/bash

if [ ! -f data/madoola.chr ]
then
    echo "data/madoola.chr not found!"
    exit -1
fi

if [ ! -f a65n/build/a65n ]
then
    echo "a65n not found, building..."
    cd a65n
    cmake -B build
    if [ $? -ne 0 ]
    then
        echo "CMake configure failed"
        exit -1
    fi
    cmake --build build
    if [ $? -ne 0 ]
    then
        echo "CMake build failed"
        exit -1
    fi
    cd ..
fi

if [ ! -d build ]
then
    mkdir build
fi

a65n/build/a65n madoola.asm -l build/madoola.lst -o build/madoola.prg
if [ $? -ne 0 ]
then
    echo "Build failed"
    exit -1
fi

cat data/header.bin build/madoola.prg data/madoola.chr > build/madoola.nes
if [ $? -ne 0 ]
then
    echo "Failed to create build/madoola.nes"
    exit -1
fi

echo "build/madoola.nes successfully created"
good_checksum="57abe0373bba73b412d32f061bf685a4a0035a5be58e34b5398ba8970a9263a7"
echo "$good_checksum build/madoola.nes" | sha256sum --check --status
if [ $? -eq 0 ]
then
    echo "built ROM matches original"
fi

exit 0
