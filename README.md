# DevOps Task

* AWS EC2 instance (Ubuntu) + Dokku + Nodejs app automatized installation
* Travis CI configuration files creation

## Steps to execute
* mkdir foldername && cd foldername
* git clone https://github.com/mpaggi/ .
* ./runme.bash
* Create a new repository *newrepository* on github, sync Travis CI and enable the new repository on Travis CI
* git add .
* git commit -m "commit for travis" --quiet
* git remote add *newrepository* https://github.com/*youraccount*/*newrepository*.git
* git push -u *newrepository* master
* Feel free to edit the node app and push changes to github. Travis will automatically buid and push the latest version to EC2.

## Prerequisites
* Terraform - https://www.terraform.io/
* AWS EC2 CLI - https://aws.amazon.com/it/cli/ 
* git binary
* ssh-keygen

## Notes
* If "terraform" binary is not installed, runme.bash will try automatically to download and use (wget + unzip needed) 
* aws key pair are dinamically generated and stored on the working directory (ssh-keygen needed) and are used also for Dokku and Travis CI.
