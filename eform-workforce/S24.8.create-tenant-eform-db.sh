#!/bin/bash
# -------
# This is script to install multitenant

# Configure constants
if [ -f "../constants.sh" ]; then
	. ../constants.sh
fi

# Run script to create databases for multitenant
. S24.1.install-db.sh

# Run script to install eform
. S24.2.install-eform-api.sh

# Create tenant scenario
camunda_line=$(grep "ecashflow" $BASE_INSTALL/domain.txt)
IFS='|' read -ra arr <<<"$camunda_line"
camunda_port="$(echo -e "${arr[3]}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

curl -G localhost:$camunda_port/eform/tenant/TCI
curl -G localhost:$camunda_port/eform/tenant/TAPAC?parentTenant=TCI
curl -G localhost:$camunda_port/eform/tenant/TTV?parentTenant=TAPAC


