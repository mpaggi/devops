#!/bin/bash
EC2_NAME="mpaggi-assessment"

######## getting variables from TF template ############
KEY_PAIR_NAME=$(grep private_key_path -A2 vars.tf | grep default | awk -F'=' '{print $2}' | tr -d ' '|tr -d '"')
HOSTNAME=$(grep hostname -A2 vars.tf | grep default | awk -F'=' '{print $2}' | tr -d ' ' | tr -d '"')
SERVER_PORT=$(grep server_port -A2 vars.tf | grep default | awk -F'=' '{print $2}' | tr -d ' ' | tr -d '"')
####### creating needed folders ##########
TEMPDIR=$(mktemp -d)
WKDIR="$(pwd)"
mkdir "${WKDIR}/.travis" 
######## prerequisites checks ############
echo -e "INFO: Checking prerequisites"
AWS="$(aws --version 2>&1 | cut -c1-7)"
if [[ -z "$AWS" ]]; then
	echo -e "ERROR: Cannot find AWS Command Line Interface (CLI), it is needed to execute this script."
	exit 1
else
	echo -e "INFO: AWS Command Line Interface (CLI) found."
fi

GIT=$(which git)
if [[ -z "$GIT" ]]; then
	echo -e "ERROR: Cannot find 'git' command, it is needed to execute this script."
	exit 1
fi


TF=$(which terraform)
if [[ -z "$TF" ]]; then
	UNZIP=$(which unzip)
	WGET=$(which wget)
	echo -e "WARNING: Cannot find 'terraform' binary, will try to download from releases.hashicorp.com"
	if [[ -z "$UNZIP" ]]; then 
		echo -e "ERROR: Cannot find 'unzip' binary, exiting."
		exit 1
	fi
	if [[ -z "$WGET" ]]; then
		echo -e "ERROR: Cannot find 'wget' binary, exiting."
		exit 1
	fi
	ARCH=$(uname -m)
	cd "${TEMPDIR}" || exit 1
	if [[ "$ARCH" == "x86_64" ]]; then
		wget 'https://releases.hashicorp.com/terraform/0.10.8/terraform_0.10.8_linux_amd64.zip' -O terraform.zip
	else 
		wget 'https://releases.hashicorp.com/terraform/0.10.8/terraform_0.10.8_linux_386.zip' -O terraform.zip
	fi
	unzip terraform.zip
	rm terraform.zip
	chmod u+x terraform
	cd "$WKDIR" || exit 1
	TF="${TEMPDIR}/terraform"
else
	echo -e "INFO: 'terraform' binary found."
fi
######## end prerequisites checks ########

echo -e "INFO: Generating Key Pairs for EC2 instance, Dokku and Travis."
ssh-keygen -t rsa -f "${KEY_PAIR_NAME}" -N "" -q

echo -e "INFO: Initializing Terraform plugins"
${TF} init
echo -e "INFO: Generating EC2 instance."
${TF} apply
if [ $? -ne 0 ]; then
	echo "ERROR: terraform encountered an error"
	exit 1
fi

EC2_ID=$($TF output id)
if [[ -z "$EC2_ID" ]]; then
	echo -e "ERROR: terraform did not return any instance ID"
	exit 1
fi

echo -e "INFO: Getting IPv4 Public Ip, do not trust terraform (bug #676)."
EC2_IP=$(aws ec2 describe-instances --filter Name=tag:Name,Values=${EC2_NAME} --filters "Name=instance-state-name,Values=running" --query 'Reservations[0].Instances[0].PublicIpAddress'|tr -d '"')

echo -e "INFO: add EC2 instance for initial git push"
git add .
git commit -m "runme commit" --quiet
git remote add mpaggidokku dokku@${EC2_IP}:sample-node-app

echo -e "INFO: checking for EC2 custom script completition."
while true; do 
	ssh -i "${WKDIR}/${KEY_PAIR_NAME}" -o "StrictHostKeyChecking no" "ubuntu@${EC2_IP}" "test -e /home/ubuntu/cloud-init-complete"
	if [ $? -ne 0 ]; then
		echo -e "INFO: Waiting for EC2 custom script. Sleeping 30 sec. It might take up to 5 min"
		sleep 30
	else 
		break
		echo -e "INFO: custom script ended"
	fi
done

echo -e "INFO: Initial sample-node-app push to EC2 instance"
GIT_SSH_COMMAND="ssh -i ${WKDIR}/${KEY_PAIR_NAME}" git push mpaggidokku master

cd "${WKDIR}" || exit 1
TRAVIS="sudo: false
language: node_js
node_js:
  - '7'
after_success:
  - eval \"\$(ssh-agent -s)\"
  - chmod 600 ${KEY_PAIR_NAME}
  - ssh-add ${KEY_PAIR_NAME}
  - ssh-keyscan ${EC2_IP} >> ~/.ssh/known_hosts
  - git remote add deploy2dokku dokku@${EC2_IP}:sample-node-app
  - git config --global push.default simple
  - git push -f deploy2dokku master"
echo "${TRAVIS}" >> "${WKDIR}/.travis.yml"

echo -e "INFO: Testing app with curl -H \"Host: sample-node-app.${HOSTNAME}\" http://${EC2_IP}:${SERVER_PORT}"
curl -H "Host: sample-node-app.${HOSTNAME}" "http://${EC2_IP}:${SERVER_PORT}"
echo -e ""
echo -e "INFO: script complete"
echo -e "INFO: 1. Add a hosts line '${EC2_IP}  sample-node-app.${HOSTNAME}' to your system if you want to use your browser for http://sample-node-app.${HOSTNAME}:${SERVER_PORT}"
echo -e "INFO: 2. Create a new github repository with all this folder content, enable it on travis, and it should be able to push on the EC2 istance directly."
