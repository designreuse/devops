#!/bin/bash
# -------
# Jenkins > Branch Specifier (blank for 'any'): */master
# Bitbucket > Settings > Webhooks: http://54.178.223.121:8081/bitbucket-hook/
# .conf: 
# -------

npm install
chmod -R 777 download

export BUILD_ID=dontKillMe 
pm2 stop CommerceChatbot || true
npm test
pm2 start index.js --name=CommerceChatbot

pm2 save
pm2 startup || true