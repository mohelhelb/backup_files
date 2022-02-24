#!/bin/bash

# Backup Files
##############

# set -eux

# --> Script functions
# Display help
function Help {
	local script_filename=$1
	printf "\nNAME\n\n${script_filename} - make a backup of files\n\n"
	printf "SYNOPSIS\n\n${script_filename} [-d dir|-h]\n\n"
	printf "DESCRIPTION\n\nThis Bash shell script is aimed at backing up the files in the config_file.txt file. By default, the parent directory that serves the purpose of containing the directories that, in turn, contain the tarfiles, backup_files directory, is created in the user's home directory (/home/'user'/backup_files). However, it can also be specified by invoking the script along with the appropriate option (d). Since the config_file.txt file plays a major role in that it contains the user-chosen files to be backed up, the user is asked to create it, if it does not exist, and/or populate it, if it is empty, at runtime. The non-existent files and duplicate ones in the config_file.txt file are discarded; only the valid files are archived and compressed into a tarfile in a directory within the backup_files directory. It's also worth mentioning that running this script generates separate tarfiles provided that it is executed on different dates. Otherwise, the existing tarfile is overwritten by the new created one.\n\n"
	printf "OPTIONS\n\n-d dir\n\tSet user-defined archive directory.\n\n-h \n\tDisplay this help and exit.\n\n"
}
# Set archive-related variables
function set_arch_vars {
	local arch_dir=$1
	arch_config_file=${arch_dir}/config_file.txt
	arch_daily=${arch_dir}/${year}_${month}_${day}
	arch=${arch_daily}/arch.tar
	arch_gz="${arch}.gz"
}
# Retrieve input from user and write it to ACF
function input_fls {
	local arch_config_file=$1
	printf "Enter the full path of the files/directories to be backed up:\n"
	while read -p "> " fullpath
	do
		if [[ -n ${fullpath} ]]; then
			echo ${fullpath} >> ${arch_config_file}
		else
			break
		fi
	done
}
# Print valid/invalid files
function print_fls {
	local fls=("$@")
	for fl in "${fls[@]}"
	do
		printf "%s\n" "${fl}"
	done
}
# Archive files
function archive_fls {
	local arch_daily=$1
	local arch=$2
	shift 2
	local fls=("$@")
	# Create daily archive directory
 	mkdir -p ${arch_daily}
	# Archive files
	for fl in "${fls[@]}"
   	do
   		tar --append --file ${arch} ${fl} 2> /dev/null
   	done
 	# Compress archive file
   	gzip -f ${arch}
}
# Display closure message
function closure {
	local acf=$1
	if [[ ${acf} == "empty" ]]; then
		printf "Archive Configuration File: Empty\nArchive: None\nBackup Process: Complete\n"
		exit
	elif [[ ${acf} == "none" ]]; then
		printf "Archive Configuration File: None\nArchive: None\nBackup Process: Aborted\nExiting script...\n"
		exit
	fi
}
#
# function sep {
# 	echo
# 	echo $(printf "#%.0s" {1..50})
# 	echo
# }
# <-- Script functions
# Fetch user
user=$(whoami)
#
year=$(date +%Y)
month=$(date +%m)
day=$(date +%d)
# Create array of valid/invalid files 
valid_files=()
invalid_files=()
# Script filename
script_filename=$(basename $0)
# Set default Archive Directory
arch_dir="/home/${user}/backup_files/"
# Set archive-related variables
set_arch_vars "${arch_dir}"
while getopts :ad:e::hD: opt
do
	case ${opt} in
		a)
			# Show entries in the ACF. Suppress empty lines
			sed -n '/^$/d ; p' "${arch_config_file}" 2> /dev/null
			exit
			;;
		d)
			if [[ -d ${OPTARG} ]] && [[ -w ${OPTARG} ]]; then
				# Set user-defined Archive Directory
				arch_dir="${OPTARG}"
				# Set archive-related variables
				set_arch_vars "${arch_dir}"
				continue
			else
				printf "Bad Usage: ${script_filename} [-d dir|-h]\nTry: Create dir and/or grant write permission to dir\n"
				exit
			fi
			;;
		e)
			sed -i "\$a\\${OPTARG}" "${arch_config_file}" 2> /dev/null
			exit
			;;
		h)
			# Display help and exit
			Help "${script_filename}"
			exit
			;;
		D)
			sed -i "s:^${OPTARG}\$:target: ; /target/d" "${arch_config_file}" 2> /dev/null
			exit
			;;
		*)
			printf "Bad Usage: ${script_filename} [-d dir|-h]\nTry: Invoke valid option along with dir\n"
			exit
			;;
	esac
done
# Create Archive Directory
mkdir -p ${arch_dir}
# Set archive-related variables
# Check ACF availability
if [[ -f ${arch_config_file} ]]; then
	acf_size=$(stat -c %s ${arch_config_file})
	case ${acf_size} in
		0)
			# Case 1
			# ACF exists and is empty
			printf "Archive Directory: ${arch_dir}\n"
			printf "Archive Configuration File: Empty\n"
			read -p "Do you want to populate the archive configuration file? [y/n] " answer
			case ${answer} in
				[yY]|"")
					# Write entries to ACF
					input_fls "${arch_config_file}"
					# If ACF is still empty, then display closure message and exit
					if [[ ! -s ${arch_config_file} ]]; then
						closure "empty"
					fi
					;;
				[nN])
					closure "empty"
					;;
				*)
					printf "Wrong answer\nExiting script...\n"
					exit
					;;
			esac
			;;
		*)
			# Case 2
			# ACF exists and is not empty
			# Do nothing
			true
			;;
	esac
else
	# Case 3
	# ACF does not exist
	printf "Archive Directory: ${arch_dir}\n"
	printf "Archive Configuration File: Missing\n"
	read -p "Do you want to create the archive configuration file? [y/n] " answer
	case ${answer} in
		[yY]|"")
			# Create ACF
			touch ${arch_config_file}
			# Write entries to ACF
			input_fls "${arch_config_file}"
			# If ACF is still empty, then display closure message and exit
			if [[ ! -s ${arch_config_file} ]]; then
				closure "empty"
			fi
			;;
		[nN])
			closure "none"
			;;
		*)
			printf "Wrong answer\nExiting script...\n"
			exit
			;;
	esac
fi
# Filter out duplicate entries in ACF and classify them into two categories (valid files & invalid files)
while read entry
do
	# Check if entry is a regular file or directory
	if [[ -f ${entry} ]] || [[ -d ${entry} ]]; then
		valid_files+=("${entry}")
	else
		invalid_files+=("${entry}")
	fi	
done < <(sort -u ${arch_config_file})
# Ratio
num_valid_files=${#valid_files[@]}
num_invalid_files=${#invalid_files[@]}
num_total_files=$[ ${num_valid_files} + ${num_invalid_files} ]
# Evaluate different cases
if [[ ${num_invalid_files} -eq ${num_total_files} ]]; then
	# Case 1
	# All the files in ACF are invalid
	printf "Invalid Files: %d/%d\n" ${num_invalid_files} ${num_total_files}
	# Print invalid files
	print_fls "${invalid_files[@]}"
	printf "Archive: None\nBackup Process: Complete\n"
	exit
elif [[ ${num_valid_files} -eq ${num_total_files} ]]; then
	# Case 2
	# All the files in ACF are valid
	# Archive files
	archive_fls "${arch_daily}" "${arch}" "${valid_files[@]}"
	printf "Valid Files: %d/%d\n" ${num_valid_files} ${num_total_files}
	# Print valid files
	print_fls "${valid_files[@]}"
	printf "Archive: %s\nBackup Process: Complete\n" "${arch_gz}"
	exit
else
	# Case 3
	# Not all the files in ACF are valid
	# Archive files
	archive_fls "${arch_daily}" "${arch}" "${valid_files[@]}"
	printf "Valid Files: %d/%d\n" ${num_valid_files} ${num_total_files}
	# Print valid files
	print_fls "${valid_files[@]}"
	printf "Invalid Files: %d/%d\n" ${num_invalid_files} ${num_total_files}
	# Print invalid files
	print_fls "${invalid_files[@]}"
	printf "Archive: %s\nBackup Process: Complete\n" "${arch_gz}"
	exit
fi
