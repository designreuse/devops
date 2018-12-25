#!/bin/bash
# -------
# This is script to create tenant

# Configure constants
if [ -f "../constants.sh" ]; then
	. ../constants.sh
fi

# Configure colors
if [ -f "../colors.sh" ]; then
	. ../colors.sh
fi

echogreen "Begin running script to create tenant..........."

echo -ne "Name of tenant you want to create: "
read tenantId

read -e -p "Is this tenant a child tenant? [y/n] " -i "y" isChildTenant

camunda_line=$(grep "ecashflow" $BASE_INSTALL/domain.txt)
IFS='|' read -ra arr <<<"$camunda_line"
camunda_port="$(echo -e "${arr[3]}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

if [ "$isChildTenant" = "y"  ]; then
	echo -ne "Name of parent tenant: "
	read parentTenantId
	echogreen "Creating new tenant..."
	curl -G localhost:$camunda_port/eform/tenant/$tenantId?parentTenant=$parentTenantId
else
	echogreen "Creating new tenant..."
	curl -G localhost:$camunda_port/eform/tenant/$tenantId
fi

