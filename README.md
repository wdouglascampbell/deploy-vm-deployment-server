# deploy-vm-deployment-server

This repository provides a Windows batch file and a Fedora kickstart configuration file.

## Prerequisites
VirtualBox installed
Fedora Server NetInstall ISO downloaded

## Usage Instructions

Edit create-deployment-server.bat and modify any of the configuration variables.  The ones that might need changing are:

VM_NAME -- VM name
ISO_PATH -- Path to the Fedora Server NetInstall ISO file
BASE_FOLDER -- Folder where Virtual Box stores VMs on your computer
SSH_PORT -- Port for accessing SSH on the server

Double-click create-deployment-server.bat.

The batch file will self-elevate its privileges causing a UAC prompt to appear. Click Yes.

A log of what is happening will be displayed in window. When the VM gets started you will need to follow the instructions provided on the screen to ensure that it uses the kickstart file during the installation.

The VM will shutdown once everything has completed and the log will indicate that the installation is complete.

The VM will have Ansible, AWS CLI, Terraform, and pass (https://www.passwordstore.org/) which is what I am using at the moment for handling deployments.

The VM is intended to be connected to using SSH to localhost and uses the following credentials:

username: admin
password: admin

It also has passwordless sudo enabled for the admin user.

