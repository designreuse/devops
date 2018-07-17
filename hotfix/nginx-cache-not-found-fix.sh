#!/bin/bash
# -------
# This is standalone script which fix nginx cache not found
# -------

sudo service nginx stop

# Extract domain name from SSL key path
hostname=$(basename /etc/letsencrypt/live/*/)

sudo sed -i "s/alfrescocache/devopscache/g" /etc/nginx/sites-available/$hostname.conf

sudo service nginx start