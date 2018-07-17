#!/bin/bash
# Configure and install ocr services
#

# Configure constants
if [ -f "constants.sh" ]; then
	. constants.sh
else
	. ../constants.sh
fi

# Configure colors
if [ -f "colors.sh" ]; then
	. colors.sh
else
	. ../colors.sh	
fi

export BASE_WP=~


echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echogreen "Begin running...."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo

cd $BASE_WP

if [ ! -d "$BASE_WP/ocr-services" ]; then
  git clone https://bitbucket.org/bot-blockchain/ocr-services.git	$BASE_WP/ocr-services
else
  cd ocr-services
  git pull
fi

.	$BASE_WP/ocr-services/bin/setup.sh

cd $BASE_WP/ocr-services
yarn

if [ ! -d "$BASE_WP/blocklancer" ]; then
  git clone https://bitbucket.org/bot-blockchain/blocklancer.git	$BASE_WP/blocklancer
else
  cd blocklancer
  git pull
fi

cd $BASE_WP/blocklancer
yarn
yarn build

rsync -avz $BASE_WP/blocklancer/build/* $BASE_WP/ocr-services/src/server/services/www/public/
rsync -avz $BASE_WP/blocklancer/build/index.html $BASE_WP/ocr-services/src/server/services/www/views/

echo "export API_PORT=3000
export WWW_PORT=3001
export FACE_DETECT_SCRIPT=/root/darknet/python/ttv_face.py
export DARKNET_DIR=/root/darknet
export AWS_KEY=AKIAJG544ZDNMLKVK3EA
export AWS_SECRET=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
export AWS_REGION=us-east-1
export AWS_BUCKET=ocr-service" >> ~/.bash_profile

source ~/.bash_profile

echogreen "Please make sure the version of node is : v8.11.2 (node -v)"
echogreen "Please make sure the version of pm2 is : 2.10.4 (pm2 -v)"
echogreen "Please make sure python and python3.5 has been installed : (which python && which python3.5)"
echored "If those requirements have not been satisfied, please run 1.ubuntu.upgrade.sh to initialize some stuffs before continuing..."

if [ "`which tesseract`" = "" ]; then
	.	$BASE_INSTALL/scripts/tesseract.sh
fi

echogreen "Please make sure the version of tesseract is greater than 4.0.0 (tesseract --version)"

if [ -z "$TESSDATA_PREFIX" ]; then
	echo "export TESSDATA_PREFIX=$HOME/tessdata" >> ~/.bash_profile
	source ~/.bash_profile
fi

sudo ufw allow 22
sudo ufw allow 2222
sudo ufw allow 80
sudo ufw allow 443
sudo ufw allow 3000
sudo ufw allow 3330

cd $BASE_WP/ocr-services
pm2 start pm2-ocr-services.json

echogreen "Check logs of `pm2` to ensure there is nothing wrong occurred during the installation : pm2 logs OCR_Services."
echogreen "If everything is good, you should see something like this : API-GATEWAY: API Gateway listening on http://0.0.0.0:3000 in the log"
echogreen "Press `CTRL+C` to exit the internal, you can access this service via browser with this url : [http:https]://domain_server:3000"
