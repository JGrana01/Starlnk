# Starlnk

## About
starlnk is a utility that is used to monitor and do some management of a Starlink system on an Asus Router running Asuswrt-Merlin

It can display information about the Satellite Dish and router and also can be used to stow or reboot Starlink.

## Prerequsite

Starlnk assumes you are running the Starlink router in bypass mode (no WiFi) and using it as a WAN modem for a router.

Entware will also be required since starlnk uses dialog for the menu/GUI system and numfmt, jq and grpcurl.

## Installation
Using your preferred SSH client/terminal, copy and paste the following command, then press Enter:

For Asuswrt-Merlin:
```sh
/usr/sbin/curl --retry 3 "https://raw.githubusercontent.com/JGrana01/starlnk/master/starlnk" -o "/jffs/scripts/starlnk" && chmod 0755 /jffs/scripts/starlnk && /jffs/scripts/starlnk install
```
Install will first check Entware being installed. If not installed, starlnk will point you to amtm for Entware installation and exit.

If Entware is installed, it will create a directory in /jffs/addons or $HOME/.config, create a config file there and setup a symbolic ink in /opt/bin. It will also check for dialog, jq, numfmt and grpcurl and install them if missing.

## Uninstallation
To remove starlnk and it's addon directory as well as grpcurl, run either in Menu mode, "U" uninstall or from the command line:

$ starlnk uninstall

## Usage
starlnk runs either a menu based system using dialog without any command line
arguments or in script mode where it will return results of a command or do an
action on the command.

To run starlnk after installation, use:
```sh
starlnk
```

If this does not work, you will need to use the full path:
```sh
/jffs/scripts/starlnk
```
To run in menu mode, just type:
```sh
starlnk
```
In script mode, enter an argument. To see available arguments, type help:
```sh
starlnk help
```

## Menu/GUI Mode
When started without a command line argument, starlnk will display (using the fine Linux dialog utility) its main menu

![image](https://github.com/JGrana01/Starlnk/assets/11652784/0b539b16-c2e1-48e7-86ec-a4f42391700c)

You can use the keyboard arrow keys or type the menu item directly.

The first selection, "Monitor Sat. Link Statistics" will show a screen with the present uplink/downlink speeds and latency. It will refresh every 3 seconds until you press the Enter key. It looks like this:

![image](https://github.com/JGrana01/Starlnk/assets/11652784/f1f6f3d6-f190-46dd-b349-986ada88bff7)

Keep in mind, this is the Satellite to dish rates and NOT the actual download or upload speeds. For those, use somehting like spdMerlin.

Another example of one of the screens (Show Present Status) shows various details about the dish and router:

![image](https://github.com/JGrana01/Starlnk/assets/11652784/45e267ae-3b36-401f-8106-bc8a5301b774)

## Script Mode

With an argument, starlnk will take a command line argument and return the requested results.

The list of arguments are:

menu    - Run starlnk in a menu driven mode using Linux dialog. This is the default
          mode when run without a command line argument

rates - displays Downlink and Uplink throughputs continuously until a return is entered

status - displays the state of both Starlink Dish and Router

linkstate - displays detailed information on the sattelite link

maxmin - shows maximum and minimum Downlink/Uplink Throughput rates from history log

router - shows information about the Starlink router

all - displays all information on the system

gps - show gps information

reboot - will issue a reboot command to Starlink

stow - will issue a stow command to Starkink

unstow - unstow and put Starlink back into operation

help - show this help info

install - setup the script directory, copy the program, link to /opt/bin (if its
                 there!) and setup a default config file

uninstall - remove starlnk and its data/directories

update - download the most recent version. Will check for existing installation.

## Important Notes

In order to allow starlnk to accces the Starlink router on the local network (192.168.100.1) you will have needed to login once using the Android/iOS Starlink app. You should only need to do this once.

I have NOT tested the reboot, stow and unstow commands. For now, they will not actually perform the action. They will "pretend".
If you want to test them, send me a PM on www.snbforums.com - user JGrana.
Keep in mind, these commands will take your Starlink system out of service for quite some time...

For any of the GPS readings, you will be required to have "Allow access on local network" enabled. You will find this setting by selecting ADVANCED at the bottom of the Android/iOS Starlink app then select DEBUG DATA and scroll down towards the bottom of that page.

