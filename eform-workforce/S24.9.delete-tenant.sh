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

camunda_line=$(grep "ecashflow" $BASE_INSTALL/domain.txt)
IFS='|' read -ra arr <<<"$camunda_line"
camunda_port="$(echo -e "${arr[3]}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

curl -G localhost:$camunda_port/multi-tenant/tenant/delete/$tenantId