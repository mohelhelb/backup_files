### Backup Files

#### Description

The main functionality of this Bash shell script is to make a backup of files by archiving and compressing them into a tarball.

#### Setup

The steps that should be taken to set up this script are as follows:

- Clone the GitHub repository (preferably into */home/"user"/projects/*).
	```
	[mkdir ~/projects/]
	git clone git@github.com:mohelhelb/backup_files.git [~/projects/backup_files/]
	```
- Modify the *arch_dir* variable (`arch_dir="/home/${user}/backup_files/"`) in the *backup_files.sh* script accordingly.
- Execute the script.
	```
	[sudo chmod a+x ~/projects/backup_files/backup_files.sh]
	bash ~/projects/backup_files/backup_files.sh
	```
