#!/bin/bash
# -------
# Script to setup, install and configure magento devops environment
#
# -------

# Configure constants
. magento2/constants.sh

# Configure colors
. magento2/colors.sh

# Run initializing script to setup environment for magento (Nginx, Composer, PHP)
. magento2/install-lemp.sh

# Run script to generate and configure magento project
. magento2/install-magento.sh

