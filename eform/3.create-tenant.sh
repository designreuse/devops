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

read -e -p "Is this tenant a child tenant? [y/n] " -i "y" isChildTenant

if [ "$isChildTenant" = "y"  ]; then
	echo -ne "Name of parent tenant: "
	read parentTenantId
	echogreen "Creating new tenant..."
	curl -G localhost:8300/eform/tenant/$tenantId?parentTenant=$parentTenantId
else
	echogreen "Creating new tenant..."
	curl -G localhost:8300/eform/tenant/$tenantId
fi

