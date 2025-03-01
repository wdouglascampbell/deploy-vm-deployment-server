# deploy-vm-deployment-server

## Introduction
This repository provides a Windows batch file and a Fedora kickstart configuration file for creating a Virtual Box VM capable of running Ansible, AWS CLI, Terraform, and [pass](https://www.passwordstore.org)

You may connect to the VM by using SSH to connect to localhost and logging in with the following credentials:

**username**: `admin`  
**password**: `admin`

Passwordless sudo has been enabled for the admin user.

> Note: This batch script and kickstart file could also be used as a template to create VMs for other purposes by modifying the `ks.cfg` kickstart file.

## Prerequisites
 + [VirtualBox](https://www.virtualbox.org) installed
 + [Fedora Server NetInstall ISO](https://fedoraproject.org/server/download) downloaded

## Usage
 1. Edit `create-deployment-server.bat` and modify any of the configuration variables. The ones that might need changing are:
    + **VM_NAME** -- VM name
    + **ISO_PATH** -- Path to the Fedora Server NetInstall ISO file
    + **BASE_FOLDER** -- Folder where Virtual Box stores VMs on your computer
    + **SSH_PORT** -- Port for accessing SSH on the server
 1. Double-click `create-deployment-server.bat`.

      The batch file will self-elevate its privileges causing a UAC prompt to appear.

 1. Click **Yes**.

      A log of what is happening will be displayed in the command window. After the VM is started a set of instructions will be displayed.

 1. Follow the instructions provided on the screen to ensure that it uses the kickstart file during the installation. If you are unable to act quickly enough the VM will proceed with a default installation and you will need to close the VM window, run VirtualBox and start the VM again manually.
 1. Once you have completed the instructions and the installation has continued, return to the command window and press any key so that it can continue monitoring the progress of the installation.

      The installation will take a little while so please wait patiently. You will be able to see some feedback of the process in the VM window.  Once the installation is completed the VM will shutdown and the command window will indicate that the installation is complete.

 1. Press any key to acknowledge that the installation has finished and the command window will close.
