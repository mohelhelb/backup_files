#!/bin/bash

# Backup Files
##############

# set -eux

# --> Script functions
# Display help
function Help {
	local script_filename=$1
	printf "\nNAME\n\n${script_filename} - make a backup of files\n\n"
	printf "SYNOPSIS\n\n${script_filename} [-a|-d dir|-D file|-e file|-h]\n\n"
	printf "DESCRIPTION\n\nThis Bash shell script is aimed at backing up the files in the Archive Configuration File (ACF). By default, the directory that serves the purpose of containing the tarfiles, Archive Directory (AD), is created in the user's home directory (/home/'user'/backup_files/). However, it can also be specified by invoking the script along with the appropriate option (d). Since the ACF plays a major role in that it contains the user-chosen files to be backed up, the user is asked to create it, if it does not exist, and/or populate it, if it is empty, at runtime. The non-existent files and duplicate ones in the ACF are discarded; only the valid files are archived and compressed into a tarfile in a directory within the AD. It is also worth mentioning that running this script always generates separate tarfiles that do not overwrite one another.\n\n"
	printf "OPTIONS\n\n"
	echo -e "-a\n\tDisplay all the entries in the ACF other than empty lines and exit.\n"
	echo -e "-d dir\n\tSet user-defined AD.\n"
	echo -e "-e file\n\tAppend file to the ACF and exit.\n"
	echo -e "-D file\n\tRemove file from the ACF and exit.\n"
	echo -e "-h\n\tDisplay this help and exit.\n"
}
# Set archive-related variables
function set_arch_vars {
	local arch_dir=$1
	arch_config_file=${arch_dir}/config_file.txt
	arch_daily=${arch_dir}/${year}_${month}_${day}
	arch=${arch_daily}/arch_${timestamp}.tar
	arch_gz="${arch}.gz"
}
# Retrieve input from user and write it to ACF
function input_fls {
	local arch_config_file=$1
	local fullpath
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
	local fl
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
	local fl
	# Create daily archive directory
 	mkdir -p ${arch_daily}
	# Archive files
	for fl in "${fls[@]}"
   	do
   		tar --exclude="${arch_daily}" --append --file ${arch} ${fl} 2> /dev/null
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
# <-- Script functions
# Fetch user
user=$(whoami)
# Get time-related variables
year=$(date +%Y)
month=$(date +%m)
day=$(date +%d)
timestamp=$(date +%s)
# Create array of valid/invalid files 
valid_files=()
invalid_files=()
# Script filename
script_filename=$(basename $0)
# Set default Archive Directory
arch_dir="/home/${user}/backup_files"
# Set archive-related variables
set_arch_vars "${arch_dir}"
while getopts :ad:e::hD: opt
do
	case ${opt} in
		a)
			# Show all the entries in the ACF other than empty lines and exit
			sed -n '/^$/d ; p' ${arch_config_file} 2> /dev/null
			exit
			;;
		d)
			if [[ -d ${OPTARG} ]] && [[ -w ${OPTARG} ]]; then
				# Set user-defined Archive Directory
				arch_dir=$(realpath ${OPTARG})
				# Set archive-related variables
				set_arch_vars "${arch_dir}"
				continue
			else
				printf "Bad Usage: ${script_filename} [-a|-d dir|-D file|-e file|-h]\nTry: Create dir and/or grant write permission to dir\n"
				exit
			fi
			;;
		D)
			# Remove entry from ACF and exit
			sed -i "s:^${OPTARG}\$:target: ; /target/d" ${arch_config_file} 2> /dev/null
			sed -n '/^$/d ; p' ${arch_config_file} 2> /dev/null
			exit
			;;

		e)
			# Add entry to ACF and exit
			sed -i "\$a\\${OPTARG}" ${arch_config_file} 2> /dev/null
			sed -n '/^$/d ; p' ${arch_config_file} 2> /dev/null
			exit
			;;
		h)
			# Display help message and exit
			Help "${script_filename}"
			exit
			;;
		*)
			printf "Bad Usage: ${script_filename} [-a|-d dir|-D file|-e file|-h]\nTry: Invoke valid option along with dir\n"
			exit
			;;
	esac
done
# Create Archive Directory
mkdir -p ${arch_dir}
# Check ACF existence
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
	printf "Archive Configuration File: None\n"
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
		valid_files+=("$(realpath ${entry})")
	else
		invalid_files+=("${entry}")
	fi	
done < <(sed "/^$/d ; s:^~/:${HOME}/: ; s:/$::" ${arch_config_file} | sort -u)
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
