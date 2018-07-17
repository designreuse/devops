#!/bin/bash
# -------
# Jenkins > Branch Specifier (blank for 'any'): */dev
# Bitbucket > Settings > Webhooks: http://54.178.223.121:8081/bitbucket-hook/
# .conf: 
# -------

npm install

export BUILD_ID=dontKillMe 
pm2 stop SalesforceChatbot || true
npm test
pm2 start index.js --name=SalesforceChatbot 

pm2 save 
pm2 startup || true