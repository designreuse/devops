#!/bin/bash
# -------
# This is script to create tenant

# Configure colors
if [ -f "../colors.sh" ]; then
	. ../colors.sh
fi

echogreen "Begin running script to delete tenant..........."

echo -ne "Name of tenant you want to delete: "
read tenantId

curl -G localhost:8300/multi-tenant/tenant/delete/$tenantId