### 1. https://bitbucket.org/bot-blockchain/blocklancer

```
npm install
node scripts/build.js
cp -R $WORKSPACE/build/index.html $WORKSPACE/../ocr-services/src/server/services/www/views/
cp -R $WORKSPACE/build/* $WORKSPACE/../ocr-services/src/server/services/www/public/
```


### 2. https://bitbucket.org/bot-blockchain/ocr-services

```
npm install
cp ~/ocr-services/.env $WORKSPACE/.env

pm2 start pm2-ocr-services.json

pm2 save
pm2 startup || true
```


### 3. https://DigitalBusiness@bitbucket.org/DevOpsDEC/smartcontract-flightdelay.git

```
# Submodule
git submodule init
git submodule update --remote --merge

npm install

cd mockserver
npm install
npm run build

cd ..

export BUILD_ID=dontKillMe
export MOCK_SERVER_IP=52.197.90.86

pm2 stop FlightDelayServer || true
pm2 start bin/run-demo.js --name=FlightDelayServer

cd client
npm install

pm2 stop FlightDelayUI || true
pm2 start ./node_modules/react-scripts/scripts/start.js --name=FlightDelayUI

pm2 save
pm2 startup || true
```



### 4. https://github.com/o2oprotocol/o2oprotocol.git

```
npm install
npm link

export BUILD_ID=dontKillMe

# Not graceful shutdown IPFS > error on lockfile
# Make sure lockfile removed
ipfs repo fsck
pm2 delete pm2-o2oprotocol-services.json
pm2 start pm2-o2oprotocol-services.json

pm2 save
pm2 startup || true
```

### 5. https://github.com/o2oprotocol/dapp-boilerplate  

```
npm install
npm link o2oprotocol
export BUILD_ID=dontKillMe
cp ~/dapp-boilerplate/.env $WORKSPACE/.env
pm2 stop Dapp || true
pm2 start ./node_modules/react-scripts/scripts/start.js —name=Dapp
pm2 save
pm2 startup
```

### 6. https://github.com/o2oprotocol/digital-identity.git

```
#!/bin/bash
# -------
# Jenkins > Branch Specifier (blank for 'any'): */master
# Bitbucket > Settings > Webhooks: http://52.197.90.86:8080/bitbucket-hook/
# .conf: 
# -------

echo $WORKSPACE

# OAUTH Services
cd issuer-services
pwd
npm install
cp /var/lib/jenkins/digital-identity/issuer-services/config.json $WORKSPACE/issuer-services/config.json

export BUILD_ID=dontKillMe
pm2 stop DigitalIdentity || true
pm2 start standalone.js --no-autorestart --name=DigitalIdentity

# UI
cd ..
pwd
npm install

export BUILD_ID=dontKillMe
cp /var/lib/jenkins/digital-identity/.env $WORKSPACE/.env
pm2 stop DigitalIdentityUI || true
pm2 start index.js --node-args="-r @babel/register" --no-autorestart --name=DigitalIdentityUI

pm2 save
pm2 startup || true
```