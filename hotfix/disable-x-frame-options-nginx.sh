#!/bin/bash
# -------
# This is standalone script which disable x-frame-options in nginx
# -------

sudo sed -i "s/add_header X-Frame-Options/#add_header X-Frame-Options/g" /etc/nginx/snippets/ssl.conf

sudo service nginx restart