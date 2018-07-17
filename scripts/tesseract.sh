#!/bin/bash

## Install Dependencies
sudo apt-get install libtesseract-dev &&
sudo apt-get install g++ &&
sudo apt-get install autoconf automake libtool &&
sudo apt-get install autoconf-archive &&
sudo apt-get install pkg-config &&
sudo apt-get install libpng-dev &&
sudo apt-get install libjpeg8-dev &&
sudo apt-get install libtiff5-dev &&
sudo apt-get install zlib1g-dev &&
sudo apt-get install zip unzip


## Install Leptonica 1.74.4 for tesseract 4.0
cd ~ &&
wget http://www.leptonica.com/source/leptonica-1.74.4.tar.gz &&
tar xvf leptonica-1.74.4.tar.gz &&
cd leptonica-1.74.4 &&
./configure &&
make &&
sudo make install &&
leoptonica -v &&

## Install tesseract 4.0
cd ~ &&
wget https://github.com/tesseract-ocr/tesseract/archive/4.0.0-beta.1.zip &&
unzip 4.0.0-beta.1.zip &&
mv tesseract-4.0.0-beta.1 tesseract4 &&
cd tesseract4 &&
./autogen.sh &&
./configure --enable-debug &&
LDFLAGS="-L/usr/local/lib" CFLAGS="-I/usr/local/include" make &&
sudo make install &&
sudo ldconfig &&
tesseract -v &&

## Download tessdata
cd ~ &&
wget https://github.com/tesseract-ocr/tessdata/archive/master.zip tessdata &&
unzip master.zip &&
mv tessdata-master tessdata

echo "export TESSDATA_PREFIX=~/tessdata" >> ~/.bash_profile
source ~/.bash_profile
