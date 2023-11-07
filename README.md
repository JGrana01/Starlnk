# Starlnk
starlnk is a utility that is used to monitor and do some management of a Starlink system on an Asus Router running Asuswrt-Merlin

It can display information about the Satellite Dish and router and also can be used to stow or reboot Starlink.

starlnk runs either a menu based system using dialog or non-menu by running without any command line
arguments or in script mode where it will return results of a command or do an
action on the command.
To run in menu mode, just type:

$ starlnk

In scripts mode, enter an argument:

$ starlnk arg

The list of script arguments are:

menu    - Run starlnk in a menu driven mode using Linux dialog. This is the default
          mode when run without a command line argument

status - displays the state of both Starlink Dish and Router

linkstate - displays detailed information on the sattelite link

router - shows information about the Starlink router

all - displays all information on the system

gps - show gps information

reboot - will issue a reboot command to Starlink

stow - will issue a stow command to Starkink

help - show this help info

install - setup the script directory, copy the program, link to /opt/bin (if its
                 there!) and setup a default config file

uninstall - remove starlnk and its data/directories

