### Backup Files

This bash shell script has the following functionalities:

- Backing up the user-chosen files in the *config_file.txt* file.
- Discarding the non-existent files and/or duplicate ones in the *config_file.txt* file.
- Archiving and compressing the valid files to be backed up into a tarfile.
- Creating the *archive* directory that serves the purpose of containing the tarfiles in the user's *home* directory (*/home/"user"/backup_files/*), if not specified by the user.
- Allowing the user to specify the *archive* directory by invoking the script along with the *d* option.
- Displaying a short description of the script by executing it with the *h* flag.

The steps that should be taken to set up this script are as follows:

- Clone the GitHub repository (preferably into */home/"user"/projects/*).
```
[cd ~]
[mkdir projects/]
[cd ~/projects/]
git clone git@github.com:mohelhelb/backup_files.git
```
- Modify the *arch_dir* variable (`arch_dir="/home/${user}/backup_files"`) in the *backup_files.sh* script accordingly.
