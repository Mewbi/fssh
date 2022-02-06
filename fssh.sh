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
dependenceis=("ssh" "dialog" "sed")
i_mode=1 # Interactive mode
base_path="${HOME}/.config/fssh"
db="${base_path}/connections" # FSSH file

#--------------------------------[ VALIDANTIONS ]
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
			echo -e "\nUse [ ffsh <name> ] to connect into a host"
			echo -e "Use [ ffsh <name> <command> ] to send a remote commando to a host"
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

function _SEND_REMOTE_COMMAND {
	conn=$(grep -m 1 "^${1}|" $db)

	# Connection not find
	if [[ -z ${conn} ]]; then
		echo -e "Connection name [ ${1} ] not find\nListing all connections available\n"

		_LIST_CONNECTIONS
		if [[ $conn_qtd == 0 ]] ; then
			echo -e "No connections registered \nCreate one using [ -a ] option"
		else
			echo -e "\nUse [ ffsh <name> ] to connect into a host"
			echo -e "Use [ ffsh <name> <command> ] to send a remote commando to a host"
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

function _MAIN {
	# Parse Parameters
	if [[ $# == 0 ]] ; then
		_LIST_CONNECTIONS
		if [[ $conn_qtd == 0 ]] ; then
			echo -e "No connections registered \nCreate one using [ -a ] option"
		else
			echo -e "\nUse [ ffsh <name> ] to connect into a host"
			echo -e "Use [ ffsh <name> <command> ] to send a remote commando to a host"
		fi
		exit
	fi


	case $1 in
		-h|--help )
			_HELP
		;;

		-l|--list )
			_LIST_CONNECTIONS
			if [[ $conn_qtd == 0 ]] ; then
				echo -e "No connections registered \nCreate one using [ -a ] option"
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