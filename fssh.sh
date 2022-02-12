#!/usr/bin/env bash

#--------------------------------------[ HEADER ]
#
# NAME
#	fssh
#
# Description
#	Simple way to manage your SSH connections
#
# Author
#	Felipe Fernandes
#

#----------------------------------------[ VARS ]
dependenceis=("ssh" "dialog" "sed" "cut")
i_mode=1 # Interactive mode
base_path="${HOME}/.config/fssh"
db="${base_path}/connections" # FSSH file

#---------------------------------[ VALIDATIONS ]
# Check dependencies
for dep in ${dependenceis[@]}; do
	if [[ -z $(type -P ${dep}) ]] ; then

		# Check essential dependency
		if [[ ${dep} == "dialog" ]] ; then
			i_mode=0
		else
			echo "[ ${dep} ] - not installed"
			echo -e "\nExiting..."
			exit 1;
		fi
	fi
done

# Check fssh files
if [[ ! -d ${base_path} ]] ; then
	echo "Creating config directory in [ ${base_path} ]"
	mkdir -p ${base_path} || { echo -e "\nError creating ${base_path}"; exit 1; }
fi

if [[ ! -f ${db} ]] ; then
	echo "Creating connections file in [ $db ]"
	> ${db}
elif [[ ! -r ${db} ]]; then
	echo -e "[ ${db} ] don't have read permission \nExiting..."
	exit 1
elif [[ ! -w ${db} ]]; then
	echo -e "[ ${db} ] don't have write permission \nExiting..."
	exit 1
fi

#----------------------------------------[ MAIN ]

function _HELP {
	cat << END

		[ FSSH ]

	Manage your ssh connections


	[ Usage ]

Connect to a saved host
	fssh <name>

Send a remote command to a saved host
	fssh <name> <command>

Manage your connections
	fssh <options>


	[ Options ]

-h | --help) 
	Show this help menu

-E | --regex)
	Send commands to connections in a pattern
	Usage: fssh -E <regex> <command>
	Example: fssh -E '(master|slave)[0-2][0-9]' uname -a

-a | --add)
	Add a new SSH connection
	Must be used with:
		-n - Connection name
		-h - Host
		-u - Username
		-i - Path to private key - [ optional ]
	Usage: fssh -a -n <name> -h <host> -u <username> -i <key-path>
	Example: fssh -a -n vps -h 123.123.123.123 -u user -i /home/user/.ssh/id_rsa

-l | --list)
	List your saved connections

-d | --delete)
	Delete a saved SSH connection
	Usage: fssh -d <name>

END
}

function _AUTOCOMPLETE {
	conn=""
	# Read each connection to show in autocomplete
	while IFS= read -r c; do
    	name=$(echo ${c} | cut -d '|' -f 1)
    	conn="${conn}${name} "
	done < "${db}"

	echo -e "${conn}"
}

function _LIST_CONNECTIONS {
	conn_qtd=0
	echo -e "\t[ FSSH - Connections ]\n"

	# Read each connection in fssh db connections
	while IFS= read -r c; do
    	name=$(echo ${c} | cut -d '|' -f 1)
    	host=$(echo ${c} | cut -d '|' -f 2)
    	user=$(echo ${c} | cut -d '|' -f 3)
    	pkey=$(echo ${c} | cut -d '|' -f 4)

    	if [[ -n ${pkey} ]] ; then
	    	echo -e "[ $name ] - Access: ${user}@${host} - Private Key: ${pkey}"
    	else
    		echo -e "[ $name ] - Access: ${user}@${host}"
    	fi
    	((conn_qtd++))
	done < "${db}"

	return ${conn_qtd}
}

function _ADD_CONNECTION {
	while [[ $# > 0 ]] ; do
		case $1 in
			-n )
				shift
				name=${1//|/} # Remove any | character
				shift
			;;

			-h )
				shift
				host=${1//|/} # Remove any | character
				shift
			;;

			-u )
				shift
				user=${1//|/} # Remove any | character
				shift
			;;

			-i )
				shift
				pkey=${1//|/} # Remove any | character
				shift
			;;

			*)
				echo -e "Unexpected parameter [ $1 ] used"
				return
			;;
		esac
	done

	# Check if every essential parameter was informed
	if [[ -z ${name} ]] ; then
		echo -e "Name to connection not informed \nMust use [ -n <name> ] option"
		return
	elif [[ -z ${host} ]] ; then
		echo -e "Host to connection not informed \nMust use [ -h <host> ] option"
		return
	elif [[ -z ${user} ]] ; then
		echo -e "User to connection not informed \nMust use [ -u <user> ] option"
		return
	fi

	# Avoid duplicated insertion
	conn=$(grep -c "^${name}|" $db)
	if [[ ${conn} > 0 ]] ; then
		echo -e "Name [ ${name} ] already in use \nChoose another name to connection"
		return
	fi

	# Check valid private key
	if [[ -n ${pkey} ]] && [[ ! -f ${pkey} ]] ; then
		echo -e "Private key [ ${pkey} ] not find \nMust inform entire path to private key"
		return
	fi

	if [[ -n ${pkey} ]] ; then
	    	echo -e "Adding connection [ ${name} ] - Access: ${user}@${host} - Private Key: ${pkey}"
    	else
    		echo -e "Adding connection [ ${name} ] - Access: ${user}@${host}"
    fi
	
	echo "${name}|${host}|${user}|${pkey}" >> ${db} 
}

function _DELETE_CONNECTION {
	conn=$(grep "^${1}|" $db)

	# Connection not find
	if [[ -z ${conn} ]]; then
		echo -e "Connection name [ ${1} ] not find\nListing all connections available\n"
		_LIST_CONNECTIONS
		return
	fi

	sed -i "/^${1}|/d" ${db} && \
	echo -e "Successfully deleted [ ${1} ] connection" || \
	echo -e "Fail to delete [ ${1} ] connection"
}

function _CONNECT_TO_HOST {
	conn=$(grep -m 1 "^${1}|" $db)

	# Connection not find
	if [[ -z ${conn} ]]; then
		echo -e "Connection name [ ${1} ] not find\nListing all connections available\n"

		_LIST_CONNECTIONS
		if [[ $conn_qtd == 0 ]] ; then
			echo -e "No connections registered \nCreate one using [ -a ] option"
		else
			echo -e "\nUse [ fssh <name> ] to connect into a host"
			echo -e "Use [ fssh <name> <command> ] to send a remote commando to a host"
		fi
		return
	fi

    name=$(echo ${conn} | cut -d '|' -f 1)
	host=$(echo ${conn} | cut -d '|' -f 2)
	user=$(echo ${conn} | cut -d '|' -f 3)
	pkey=$(echo ${conn} | cut -d '|' -f 4)

	echo "Connection to [ $name ] - Access: ${user}@${host}"
	if [[ -n ${pkey} ]] ; then
		ssh -o ConnectTimeout=5 ${user}@${host} -i ${pkey}
	else
		ssh -o ConnectTimeout=5 ${user}@${host}
	fi
}

function _FIND_CONNECTIONS_REGEX {
	conns=$(cut -d '|' -f 1 ${db} | grep -E "$1")

	# Connection not find
	if [[ -z ${conns} ]]; then
		echo -e "Pattern [ ${1} ] not find any connections"
		return
	fi

	# Iterate over each connection
	shift
	for conn in ${conns}; do
		_SEND_REMOTE_COMMAND ${conn} $@
	done
}

function _SEND_REMOTE_COMMAND {
	conn=$(grep -m 1 "^${1}|" $db)

	# Connection not find
	if [[ -z ${conn} ]]; then
		echo -e "Connection name [ ${1} ] not find\nListing all connections available\n"

		_LIST_CONNECTIONS
		if [[ $conn_qtd == 0 ]] ; then
			echo -e "No connections registered \nCreate one using [ -a ] option"
		else
			echo -e "\nUse [ fssh <name> ] to connect into a host"
			echo -e "Use [ fssh <name> <command> ] to send a remote commando to a host"
		fi
		return
	fi

    name=$(echo ${conn} | cut -d '|' -f 1)
	host=$(echo ${conn} | cut -d '|' -f 2)
	user=$(echo ${conn} | cut -d '|' -f 3)
	pkey=$(echo ${conn} | cut -d '|' -f 4)

	shift
	echo "Send command [ ${@} ] to [ $name ] - Access: ${user}@${host}"
	if [[ -n ${pkey} ]] ; then
		ssh -o ConnectTimeout=5 ${user}@${host} -i ${pkey} -t "${@}"
	else
		ssh -o ConnectTimeout=5 ${user}@${host}	-t "${@}"
	fi
}

function _SELECT_CONNECTION_INTERACTIVE {
	DIALOG_CANCEL=1
	DIALOG_ESC=255
	HEIGHT=0
	WIDTH=0

	connections=()
	conn_qtd=0

	# Read each connection in fssh db connections
	while IFS= read -r c; do
    	name=$(echo ${c} | cut -d '|' -f 1)
    	host=$(echo ${c} | cut -d '|' -f 2)
    	user=$(echo ${c} | cut -d '|' -f 3)

		#connections="${connections}$name ${user}@${host}\n"
		connections+=("${name}" "${user}@${host}")
		((conn_qtd++))
	done < "${db}"

	# Select a connection
	while true; do
	 	exec 3>&1
	 	machine=$(dialog \
			--backtitle "FSSH" \
			--title "Select" \
			--clear \
			--ok-label "Connect" \
			--cancel-label "Back" \
			--menu "Select a connection:" $HEIGHT $WIDTH ${conn_qtd} \
				${connections[@]} 2>&1 1>&3)
		exit_status=$?
		exec 3>&-
		case $exit_status in
			$DIALOG_CANCEL | $DIALOG_ESC)
				break
			;;
		esac

		if [[ $1 == "--connect" ]]; then
			clear
			_CONNECT_TO_HOST "${machine}"
		elif [[ $1 == "--send-command" ]]; then
			_SEND_REMOTE_COMMAND_INTERACTIVE "${machine}" "${user}@${host}"
		elif [[ $1 == "--delete" ]]; then
			_DELETE_CONNECTIONS_INTERACTIVE "${machine}" "${user}@${host}"
			break
		fi
	done
}

function _SEND_REMOTE_COMMAND_INTERACTIVE {
	DIALOG_OK=0
	DIALOG_CANCEL=1
	DIALOG_ESC=255

	exec 3>&1
	
	command=$(dialog \
		--backtitle "FSSH" \
		--title "Send Command" \
		--clear \
		--ok-label "Send" \
		--cancel-label "Back" \
		--inputbox \
	"Machine selected: ${1} \nSending to: ${2} \n\nType a command:" \
	0 0 2>&1 1>&3)

	# Get dialog's exit status
	return_value=$?

	exec 3>&-

	case $return_value in
		$DIALOG_OK )
			clear
	    	_SEND_REMOTE_COMMAND ${1} ${command}
	    	echo -e "\n[ FSSH ] - Command executed.\n[ FSSH ] - Type ENTER to continue"
	    	read
	    ;;
		
		$DIALOG_CANCEL | $DIALOG_ESC )
	    	return
		;;
	esac
}

function _LIST_CONNECTIONS_INTERACTIVE {
	connections=""
	title="Connections"

	# Read each connection in fssh db connections
	while IFS= read -r c; do
    	name=$(echo ${c} | cut -d '|' -f 1)
    	host=$(echo ${c} | cut -d '|' -f 2)
    	user=$(echo ${c} | cut -d '|' -f 3)
    	pkey=$(echo ${c} | cut -d '|' -f 4)

		if [[ -n ${pkey} ]] ; then
			connections="${connections}[ $name ] \nAccess: ${user}@${host}\nPrivate Key: ${pkey}\n\n"
		else
			connections="${connections}[ $name ] \nAccess: ${user}@${host}\n\n"
		fi
    	
	done < "${db}"

	if [[ -z ${connections} ]] ; then
		connections="No connections registered"
	fi

	_DISPLAY_INTERACTIVE ${title} "${connections}"
}

function _ADD_CONNECTIONS_INTERACTIVE {
	DIALOG_OK=0
	DIALOG_CANCEL=1
	DIALOG_ESC=255

	name=""
	user="$(whoami)"
	host=""
	pkey=""

	# Form
	exec 3>&1

	values=$(dialog --backtitle "FSSH" \
			--title "Add Connection" \
			--clear \
			--ok-label "Add" \
			--cancel-label "Cancel" \
			--form "Private key is optional field" \
				0 0 0 \
		"Connection Name:"	1 1	"$name" 	1 20 25 100 \
		"User:"				2 1	"$user"  	2 20 25 100 \
		"Host:"				3 1	"$host"  	3 20 25 100 \
		"Private Key Path:"	4 1	"$pkey" 	4 20 25 150 \
	2>&1 1>&3)

	# Get dialog's exit status
	return_value=$?
	
	exec 3>&-

	if [[ ${return_value} != ${DIALOG_OK} ]]; then
		return
	fi

	# Set variables
	name=$(echo "${values}" | sed -n 1p)
	user=$(echo "${values}" | sed -n 2p)
	host=$(echo "${values}" | sed -n 3p)
	pkey=$(echo "${values}" | sed -n 4p)

	# Check valid input
	# Check if every essential parameter was informed
	if [[ -z ${name} ]] ; then
		_DISPLAY_INTERACTIVE "Invalid Insertion" "Name to connection not informed"
		return
	elif [[ -z ${host} ]] ; then
		_DISPLAY_INTERACTIVE "Invalid Insertion" "Host to connection not informed"
		return
	elif [[ -z ${user} ]] ; then
		_DISPLAY_INTERACTIVE "Invalid Insertion" "User to connection not informed"
		return
	fi

	# Avoid duplicated insertion
	conn=$(grep -c "^${name}|" $db)
	if [[ ${conn} > 0 ]] ; then
		_DISPLAY_INTERACTIVE "Invalid Insertion" "Name [ ${name} ] already in use"
		return
	fi

	# Check valid private key
	if [[ -n ${pkey} ]] && [[ ! -f ${pkey} ]] ; then
		_DISPLAY_INTERACTIVE "Invalid Insertion" "Private key [ ${pkey} ] not find \n\nMust inform entire path to private key"
		return
	fi

	# Confirm Value
	if [[ -n ${pkey} ]] ; then
    	validation="Connection name: ${name}\nAccess: ${user}@${host}\nPrivate Key: ${pkey}"
    else
		validation="Connection name: ${name}\nAccess: ${user}@${host}"
    fi

    exec 3>&1
	
	use_pkey=$(dialog \
		--backtitle "FSSH" \
		--title "Confirm Values" \
		--clear \
		--yesno \
	"The information below is correct?\n\n${validation}" \
	0 0 2>&1 1>&3)

	# Get dialog's exit status
	return_value=$?
	exec 3>&-

	if [[ ${return_value} != ${DIALOG_OK} ]] && [[ ${return_value} != ${DIALOG_CANCEL} ]]; then
		return
	fi

	if [[ ${return_value} == ${DIALOG_OK} ]]; then
		echo "${name}|${host}|${user}|${pkey}" >> ${db} \
		&& _DISPLAY_INTERACTIVE "Insertion" "Data successfully inserted" \
		|| _DISPLAY_INTERACTIVE "Insertion" "Failed to insert data"
	fi
}

function _DELETE_CONNECTIONS_INTERACTIVE {
	conn=$(grep "^${1}|" $db)

	# Connection not find
	if [[ -z ${conn} ]]; then
		echo -e "Connection name [ ${1} ] not find\nListing all connections available\n"
		_LIST_CONNECTIONS
		return
	fi

	success=false
	sed -i "/^${1}|/d" ${db} && success=true
	if [[ ${success} == true ]]; then
		_DISPLAY_INTERACTIVE "Delete" "Succefully deleted\n\nConnection: ${1}\nAccess: ${2}"
	else
		_DISPLAY_INTERACTIVE "Delete" "Failed to delete\n\nConnection: ${1}\nAccess: ${2}"
	fi
}

function _DISPLAY_INTERACTIVE {
	dialog --backtitle "FSSH" \
		--title "${1}" \
		--no-collapse \
		--clear \
		--ok-label "OK" \
		--msgbox "${2}" 0 0
}

function _MAIN_INTERACTIVE {
	DIALOG_CANCEL=1
	DIALOG_ESC=255
	HEIGHT=0
	WIDTH=0

	while true; do
	 	exec 3>&1
	 	selection=$(dialog \
			--backtitle "FSSH" \
			--title "Menu" \
			--clear \
			--ok-label "Choose" \
			--cancel-label "Exit" \
			--menu "Select an option:" $HEIGHT $WIDTH 5 \
				"Connect" "Connect to a host" \
				"Send" "Send a commmand remotly to a host" \
				"List" "List registered connections" \
				"Add" "Add a new connection" \
				"Delete" "Delete a connection" \
			2>&1 1>&3)
		exit_status=$?
		exec 3>&-
		case $exit_status in
			$DIALOG_CANCEL )
				clear
				echo "Program terminated"
				exit
			;;
			$DIALOG_ESC )
				clear
				echo "Program aborted" >&2
				exit
			;;
		esac

		case $selection in

			"Connect" )
				_SELECT_CONNECTION_INTERACTIVE --connect
			;;

			"Send" )
				_SELECT_CONNECTION_INTERACTIVE --send-command
			;;

			"List" )
				_LIST_CONNECTIONS_INTERACTIVE
			;;

			"Add" )
				_ADD_CONNECTIONS_INTERACTIVE
			;;

			"Delete" )
				_SELECT_CONNECTION_INTERACTIVE --delete
			;;
		esac
	done
}

function _MAIN {
	# Parse Parameters
	if [[ $# == 0 ]] ; then
		_LIST_CONNECTIONS
		if [[ $conn_qtd == 0 ]] ; then
			echo -e "No connections registered \nCreate one using [ -a ] option"
		else
			echo -e "\nUse [ fssh <name> ] to connect into a host"
			echo -e "Use [ fssh <name> <command> ] to send a remote command to a host"
		fi
		exit
	fi


	case $1 in
		-h|--help )
			_HELP
		;;

		-l|--list )
			shift
			if [[ $1 == "--autocomplete" ]]; then
				_AUTOCOMPLETE
			else
				_LIST_CONNECTIONS
				if [[ $conn_qtd == 0 ]] ; then
					echo -e "No connections registered \nCreate one using [ -a ] option"
				fi
			fi
		;;

		-a|--add )
			shift
			_ADD_CONNECTION $@
		;;

		-d|--delete )
			shift
			_DELETE_CONNECTION $1
		;;

		-i|--interactive )
			if [[ ${i_mode} == 1 ]]; then
				_MAIN_INTERACTIVE	
			else
				echo -e "Interactive mode disabled \nCheck if [ dialog ] is installed in system"
			fi
		;;

		-E|--regex )
			shift
			if [[ $# < 2 ]]; then
				echo -e "Invalid number of parameters sended"
			else
				regex=$1
				shift
				_FIND_CONNECTIONS_REGEX ${regex} $@
			fi

		;;

		*)
			if [[ $# == 1 ]]; then
				_CONNECT_TO_HOST $1
			else
				_SEND_REMOTE_COMMAND $@
			fi
		;;
	esac
}

_MAIN $@