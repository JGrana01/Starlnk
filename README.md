# Starlnk

## About
starlnk is a utility that is used to monitor and do some management of a Starlink system on an Asus Router running Asuswrt-Merlin

It can display information about the Satellite Dish and router and also can be used to stow or reboot Starlink.

## Prerequsites

For now, starlnk can only run on Asuswrt-Merlin aarch64 based routers. It will check during install.
Starlnk assumes you are running the Starlink router in bypass mode (no WiFi) and using it as a WAN modem for the Asus Router.

This addon requires an additional program called grpcurl which will be downloaded from the grpcurl project page on github
(https://github.com/fullstorydev/grpcurl/releases/download/).
A request has been made to the Entware team to include grpcurl in the Entware repository.
starlnk will download grpcurl and install it in /opt/sbin.
Entware will also be required.

## Installation
Using your preferred SSH client/terminal, copy and paste the following command, then press Enter:

```sh
/usr/sbin/curl --retry 3 "https://raw.githubusercontent.com/JGrana01/starlnk/master/starlnk.sh" -o "/jffs/scripts/starlnk" && chmod 0755 /jffs/scripts/starlnk && /jffs/scripts/starlnk install
```
## Usage
starlnk runs either a menu based system using dialog without any command line
arguments or in script mode where it will return results of a command or do an
action on the command.

To run in menu mode, just type:
$ starlnk

In script mode, enter an argument:

$ starlnk arg

## Menu Mode
When started without a command line argument, starlnk will display (using the fine Linux dialog utility) its main menu

![image](https://github.com/JGrana01/Starlnk/assets/11652784/0b539b16-c2e1-48e7-86ec-a4f42391700c)

You can use the keyboard arrow keys or type the menu item directly

An example of one of the screens (Show Present Status)

![image](https://github.com/JGrana01/Starlnk/assets/11652784/37aa1c04-61ac-4649-8603-b40b36cbb2c7)
## Script Mode

With an argument, starlnk will take a command line argument and return the requested results.

The list of arguments are:

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

## Important Notes
I have NOT tested the reboot and stow commands. For now, they will not actually perform the action. They will "pretend".
If you want to test them, send me a PM on www.snbforums.com - user JGrana.

