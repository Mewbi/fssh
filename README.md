# FSSH
Fast and simple way to manage your SSH connections and send remote commands to another server.

## Install
Install dependencies:
- sed
- ssh
- cut
- dialog (optional to use interactive mode)

Clone repository:
```bash
git clone https://github.com/Mewbi/fssh.git
```

Run installation script with root privilegies:
```bash
chmod +x install.sh
sudo ./install.sh
```

## CLI Mode 
CLI mode is a straightforward way to use the program.

### Usage
- Connect to a saved host
Press `tab` will show a list of available connections
```
fssh <name>
```

- Send a remote command to a saved host
```
fssh <name> <command>
```

- Manage your connections
```
fssh <options>
```

### Options
- `-h, --help`
Show help menu

- `-E, --regex`
Send commands to connections in a pattern
Usage: `fssh -E <regex> <command>`
Example: `fssh -E '(master|slave)[0-2][0-9]' uname -a`

- `-a, --add`
Add a new SSH connection
Must be used with:
	`-n` - Connection name
	`-h` - Host
	`-u` - Username
	`-i` - Path to private key - [ optional ]
Usage: `fssh -a -n <name> -h <host> -u <username> -i <key-path>`
Example: `fssh -a -n vps -h 123.123.123.123 -u user -i /home/user/.ssh/id_rsa`

- `-l, --list`
	List your saved connections

- `-d, --delete`
	Delete a saved SSH connection
	Usage: `fssh -d <name>`

### Examples
Create a connection
```bash
$ fssh -a -n my-second-machine -h mwb.domain.com.br -u mewbi -i ~/.ssh/id_rsa
Adding connection [ my-second-machine ] - Access: mewbi@mwb.domain.com.br - Private Key: /home/felipe/.ssh/id_rsa
```

Connect to a machine
```bash
$ fssh my-second-machine
Connection to [ my-second-machine ] - Access: mewbi@mwb.domain.com.br
```

Send a command to multiple connections
```bash
$ fssh -E 'bian1[3-6]' uname -a
Send command [ uname -a ] to [ debian13 ] - Access: mewbi@127.0.0.1
Linux debian 4.19.0-18-amd64 #1 SMP Debian 4.19.208-1 (2021-09-29) x86_64 GNU/Linux
Shared connection to 127.0.0.1 closed.
Send command [ uname -a ] to [ debian14 ] - Access: mewbi@127.0.0.1
Linux debian 4.19.0-18-amd64 #1 SMP Debian 4.19.208-1 (2021-09-29) x86_64 GNU/Linux
Shared connection to 127.0.0.1 closed.
Send command [ uname -a ] to [ debian15 ] - Access: mewbi@127.0.0.1
Linux debian 4.19.0-18-amd64 #1 SMP Debian 4.19.208-1 (2021-09-29) x86_64 GNU/Linux
Shared connection to 127.0.0.1 closed.
Send command [ uname -a ] to [ debian16 ] - Access: mewbi@127.0.0.1
Linux debian 4.19.0-18-amd64 #1 SMP Debian 4.19.208-1 (2021-09-29) x86_64 GNU/Linux
Shared connection to 127.0.0.1 closed.
```

Send multiple commands to multiple connections
```bash
$ fssh -E 'bian1[3-6]' "uname -r && hostname"
Send command [ uname -r && hostname ] to [ debian13 ] - Access: mewbi@127.0.0.1
4.19.0-18-amd64
debian
Shared connection to 127.0.0.1 closed.
Send command [ uname -r && hostname ] to [ debian14 ] - Access: mewbi@127.0.0.1
4.19.0-18-amd64
debian
Shared connection to 127.0.0.1 closed.
Send command [ uname -r && hostname ] to [ debian15 ] - Access: mewbi@127.0.0.1
4.19.0-18-amd64
debian
Shared connection to 127.0.0.1 closed.
Send command [ uname -r && hostname ] to [ debian16 ] - Access: mewbi@127.0.0.1
4.19.0-18-amd64
debian
Shared connection to 127.0.0.1 closed.
```

## Interactive Mode 
Interactive mode is a friendly interface to use the program.

### Usage Examples

#### Add a connection
![Add Connection](https://i.imgur.com/dNl3ctH.gif)

#### Connect to a machine
![Connect to Machine](https://i.imgur.com/VmhJfGV.gif)

#### Send remote command
![Send a Command](https://i.imgur.com/AZz1zEm.gif)