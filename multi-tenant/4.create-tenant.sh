#!/bin/bash
# -------
# This is script to create tenant

# Configure colors
if [ -f "../colors.sh" ]; then
	. ../colors.sh
fi

echogreen "Begin running script to create tenant..........."

echo -ne "Name of tenant you want to create: "
read tenantId

curl -G localhost:8300/multi-tenant/tenant/$tenantId