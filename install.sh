#!/usr/bin/env bash

#----------------------------------------[ VARS ]
path="/usr/bin/"
file="fssh.sh"

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

echo -e "Installation completed \nUse fssh to use the program"