#!/bin/bash
# -------
# This is script to convert RACI Excel to DMN which is later deployed into Camunda

# Configure constants
if [ -f "constants.sh" ]; then
	. constants.sh
else
	. ../constants.sh
fi

# Configure colors
if [ -f "colors.sh" ]; then
	. colors.sh
else
	. ../colors.sh	
fi

export fileBPMNExist=false
export fileRaciExist=false
export BPMN_PATH=$DEVOPS_HOME/eforms/bpmn

echogreen "Begin running script to deploy..........."

read -e -p "Do you want to deploy all package? [y/n] " -i "y" isDeployAll

if [ "$isDeployAll" = "y" ]; then
	if [ ! -d "$DEVOPS_HOME/eforms/dmn/input" ]; then
		mkdir -p $DEVOPS_HOME/eforms/dmn/input
		echored "There is no input file for this dmn conversion. Please put RACI excel file : RACI-Decision-Making-Criteria.xlsx into $DEVOPS_HOME/eform/dmn/input..."
	elif [ ! -f "$DEVOPS_HOME/eforms/dmn/input/RACI-Decision-Making-Criteria.xlsx" ]; then
		echored "There is no input file for this dmn conversion. Please put RACI excel file : RACI-Decision-Making-Criteria.xlsx into $DEVOPS_HOME/eform/dmn/input..."
	else
		fileRaciExist=true
	fi

	if [ ! -d "$DEVOPS_HOME/eforms/bpmn" ]; then
		mkdir -p $DEVOPS_HOME/eforms/bpmn
		echored "There is no bpmn input file. Please put bpmn file into $DEVOPS_HOME/eform/bpmn..."
	else
		exist=$(find /home/devops/eforms/bpmn -type f -name "*.bpmn")
		echo $exist
		if [ -z "${exist}" ]; then
			echored "There is no bpmn input file. Please put bpmn file into $DEVOPS_HOME/eform/bpmn..."
		else
			fileBPMNExist=true
		fi
	fi
	### check file exist
	if [ "$fileBPMNExist" = false ] || [ "$fileRaciExist" = false ]; then
		exit 0
	fi
else
	if [ ! -d "$DEVOPS_HOME/eforms/bpmn" ]; then
		mkdir -p $DEVOPS_HOME/eforms/bpmn
		echored "There is no bpmn input file. Please put bpmn file into $DEVOPS_HOME/eform/bpmn..."
	else
		exist=$(find /home/devops/eforms/bpmn -type f -name "*.bpmn")
		echo $exist
		if [ -z "${exist}" ]; then
			echored "There is no bpmn input file. Please put bpmn file into $DEVOPS_HOME/eform/bpmn..."
		else
			fileBPMNExist=true
		fi
	fi

	if [ ! -d "$DEVOPS_HOME/eforms/dmn/input" ]; then
		mkdir -p $DEVOPS_HOME/eforms/dmn/input
		echored "There is no input file for this dmn conversion. Please put RACI excel file : RACI-Decision-Making-Criteria.xlsx into $DEVOPS_HOME/eform/dmn/input..."
	elif [ ! -f "$DEVOPS_HOME/eforms/dmn/input/RACI-Decision-Making-Criteria.xlsx" ]; then
		echored "There is no input file for this dmn conversion. Please put RACI excel file : RACI-Decision-Making-Criteria.xlsx into $DEVOPS_HOME/eform/dmn/input..."
	else
		fileRaciExist=true
	fi

	### check file exist
	if [ "$fileBPMNExist" = false ] && [ "$fileRaciExist" = false ]; then
		exit 0
	fi
fi

if [ -d "$TMP_INSTALL/workplacebpm" ]; then
	sudo rm -rf $TMP_INSTALL/workplacebpm
fi

git clone https://bitbucket.org/eworkforce/workflow.git $TMP_INSTALL/workplacebpm

if [ "$isDeployAll" = "y" ]; then
    sudo sed -i "s/\(^eform.cli.deployAll=\).*/\1true/" 	$TMP_INSTALL/workplacebpm/RACE-Excel-BPMN-DMN/xlsx-dmn-cli/src/main/resources/application.properties
fi

if [ "$fileBPMNExist" = true ]; then
    sudo sed -i "s/\(^eform.cli.deployBpmn=\).*/\1true/" 	$TMP_INSTALL/workplacebpm/RACE-Excel-BPMN-DMN/xlsx-dmn-cli/src/main/resources/application.properties
fi

if [ "$fileRaciExist" = true ]; then
	sudo sed -i "s/\(^eform.cli.convertDmn=\).*/\1true/" 	$TMP_INSTALL/workplacebpm/RACE-Excel-BPMN-DMN/xlsx-dmn-cli/src/main/resources/application.properties
    sudo sed -i "s/\(^eform.cli.deployDmn=\).*/\1true/" 	$TMP_INSTALL/workplacebpm/RACE-Excel-BPMN-DMN/xlsx-dmn-cli/src/main/resources/application.properties
fi

if [ ! -d "$DEVOPS_HOME/eforms/dmn/output" ]; then
	mkdir -p $DEVOPS_HOME/eforms/dmn/output
else
	sudo rm -rf $DEVOPS_HOME/eforms/dmn/output/*.*
fi

read -e -p "Please enter the tenant id for DMN deployment${ques} [TTV] " -i "TTV" TENANT_ID
if [ -z "$TENANT_ID"  ]; then
    sudo sed -i "s/\(^eform.cli.dmn.camunda.tenantId=\).*/\1$TENANT_ID/" 	$TMP_INSTALL/workplacebpm/RACE-Excel-BPMN-DMN/xlsx-dmn-cli/src/main/resources/application.properties
fi

read -e -p "Please enter the public host name for Camunda server (fully qualified domain name): " camunda_hostname

DEVOPS_HOME_PATH=${DEVOPS_HOME//\//\\/}
sudo sed -i "s/\(^eform.cli.raci.filePath=\).*/\1$DEVOPS_HOME_PATH\/eforms\/dmn\/input\/RACI-Decision-Making-Criteria.xlsx/" 	$TMP_INSTALL/workplacebpm/RACE-Excel-BPMN-DMN/xlsx-dmn-cli/src/main/resources/application.properties
sudo sed -i "s/\(^eform.cli.departmentMaster.filePath=\).*/\1$DEVOPS_HOME_PATH\/eforms\/dmn\/input\/RACI-Decision-Making-Criteria.xlsx/" 	$TMP_INSTALL/workplacebpm/RACE-Excel-BPMN-DMN/xlsx-dmn-cli/src/main/resources/application.properties
sudo sed -i "s/\(^eform.cli.bom.filePath=\).*/\1$DEVOPS_HOME_PATH\/eforms\/dmn\/input\/RACI-Decision-Making-Criteria.xlsx/" 	$TMP_INSTALL/workplacebpm/RACE-Excel-BPMN-DMN/xlsx-dmn-cli/src/main/resources/application.properties
sudo sed -i "s/\(^eform.cli.bufferDepartment.filePath=\).*/\1$DEVOPS_HOME_PATH\/eforms\/dmn\/input\/RACI-Decision-Making-Criteria.xlsx/" 	$TMP_INSTALL/workplacebpm/RACE-Excel-BPMN-DMN/xlsx-dmn-cli/src/main/resources/application.properties
sudo sed -i "s/\(^eform.cli.dmn.bom.outputFilePath=\).*/\1$DEVOPS_HOME_PATH\/eforms\/dmn\/output\/BOMApproval.dmn/" 	$TMP_INSTALL/workplacebpm/RACE-Excel-BPMN-DMN/xlsx-dmn-cli/src/main/resources/application.properties
sudo sed -i "s/\(^eform.cli.dmn.bom.bufferFilePath=\).*/\1$DEVOPS_HOME_PATH\/eforms\/dmn\/input\/RACI-Decision-Making-Criteria.xlsx/" 	$TMP_INSTALL/workplacebpm/RACE-Excel-BPMN-DMN/xlsx-dmn-cli/src/main/resources/application.properties

sudo sed -i "s/\(^eform.cli.dmn.department.outputFilePath=\).*/\1$DEVOPS_HOME_PATH\/eforms\/dmn\/output\/DepartmentApproval.dmn/" 	$TMP_INSTALL/workplacebpm/RACE-Excel-BPMN-DMN/xlsx-dmn-cli/src/main/resources/application.properties
sudo sed -i "s/\(^eform.cli.dmn.department.bufferFilePath=\).*/\1$DEVOPS_HOME_PATH\/eforms\/dmn\/input\/RACI-Decision-Making-Criteria.xlsx/" 	$TMP_INSTALL/workplacebpm/RACE-Excel-BPMN-DMN/xlsx-dmn-cli/src/main/resources/application.properties

BPMN_PATH_ESC="${BPMN_PATH//\//\\/}"
sudo sed -i "s/\(^eform.cli.bpmn.deployFolderPath=\).*/\1$BPMN_PATH_ESC/" 	$TMP_INSTALL/workplacebpm/RACE-Excel-BPMN-DMN/xlsx-dmn-cli/src/main/resources/application.properties

camunda_protocol=http
if [[ $camunda_hostname = *tctav* ]]; then
	camunda_protocol=https
fi

sudo sed -i "s/\(^eform.cli.dmn.camunda.deploymentName=\).*/\1$TENANT_ID-archive/" 	$TMP_INSTALL/workplacebpm/RACE-Excel-BPMN-DMN/xlsx-dmn-cli/src/main/resources/application.properties
sudo sed -i "s/\(^eform.cli.dmn.camunda.tenantId=\).*/\1$TENANT_ID/" 	$TMP_INSTALL/workplacebpm/RACE-Excel-BPMN-DMN/xlsx-dmn-cli/src/main/resources/application.properties
sudo sed -i "s/\(^eform.cli.dmn.camunda.url.deployment=\).*/\1$camunda_protocol:\/\/$camunda_hostname\/engine-rest\/engine\/$TENANT_ID\/deployment\/create/" 	$TMP_INSTALL/workplacebpm/RACE-Excel-BPMN-DMN/xlsx-dmn-cli/src/main/resources/application.properties

cd $TMP_INSTALL/workplacebpm/RACE-Excel-BPMN-DMN
#source /etc/profile.d/maven.sh
mvn clean install -Dmaven.test.skip=true

sudo java -jar $TMP_INSTALL/workplacebpm/RACE-Excel-BPMN-DMN/xlsx-dmn-cli/target/dmn-xlsx-cli-0.2.1-SNAPSHOT.jar

# Copy generated DMN into eform source and deploy eform
# sudo rsync -avz $DEVOPS_HOME_PATH/dmn/output/*.dmn $TMP_INSTALL/workplacebpm/src/eForm/workflow/src/main/resources/processes/$TENANT_ID
# cd $TMP_INSTALL/workplacebpm/src/eForm

# mkdir $TMP_INSTALL/temp
# cp $CATALINA_HOME/webapps/eform/WEB-INF/classes/application.properties $TMP_INSTALL/temp
# mvn clean install
# if [ -d "$CATALINA_HOME/webapps/eform" ]; then
	# sudo rm -rf $CATALINA_HOME/webapps/eform*
# fi
# sudo rsync -avz $TMP_INSTALL/workplacebpm/src/eForm/gateway/target/eform.war $CATALINA_HOME/webapps

# echo "We are waiting for eform being deployed...."

# sleep 20

# sudo rsync -avz $TMP_INSTALL/temp/application.properties $CATALINA_HOME/webapps/eform/WEB-INF/classes/application.properties

# sudo rm -rf $TMP_INSTALL/temp

# sudo $DEVOPS_HOME/devops-service.sh restart
