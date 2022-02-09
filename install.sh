#!/usr/bin/env bash

#----------------------------------------[ VARS ]
path="/usr/bin/"
file="fssh.sh"
autocomplete_path="/etc/bash_completion.d/"
autocomplete_file="fssh-autocomplete"

#--------------------------------[ VALIDANTIONS ]
# Check root permission
if [[ $(id -u) != 0 ]] ; then
	echo -e "Must run as root or using sudo"
	exit
fi

# Check file existence
if [[ ! -f ${file} ]] ; then
	echo -e "Script [ ${file} ] not find in actual directory"
	exit
fi


#----------------------------------------[ Main ]
echo -e "Setting execution permission"
chmod +x ${file}

echo -e "Installing in system"
mv ${file} ${path}${file} || { echo "Fail to install in ${path}"; exit; }
ln -s ${path}${file} ${path}fssh || { echo "Fail to create symbolic link"; exit; }

echo -e "Setting autocomplete"
if [[ ! -d ${autocomplete_path} ]] ; then
	echo "Creating directory [ ${autocomplete_path} ]"
	mkdir -p ${autocomplete_path} || { echo -e "\nError creating ${autocomplete_path}"; exit 1; }
fi
mv ${autocomplete_file} ${autocomplete_path}${autocomplete_file}

echo -e "Installation completed \nUse fssh to use the program"