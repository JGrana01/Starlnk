#!/bin/sh

#
# starlnk.sh - an Asuswrt-Merlin script to monitor and make changes to the 
# Starlink Dishy
#
# You can check status, run a speedtest, reboot and stow the dish
# And examine some of the existing dish configuration
#
# this version (starlnk.sh) uses dialog for a more graphical UI
# but also supports a non-interactive mode
#

# location where configutration data is read from the Sagemcom and stored

SCRIPTNAME="starlnk"

SCRIPTDIR="/jffs/addons/$SCRIPTNAME"
SCRIPTLOC="/jffs/scripts/$SCRIPTNAME"
SCRIPTVER="0.2.1"
CONFIG="$SCRIPTDIR/config.txt"
STRLTMP="$SCRIPTDIR/stl.tmp"
SLSTATETMP="$SCRIPTDIR/lstate.tmp"
SLHISTORY="$SCRIPTDIR/slhistory.log"
SPDLOG=/jffs/logs/starlnklog

INTESTMODE=1
DEBUG=0

GRPCURLAPP="https://github.com/fullstorydev/grpcurl/releases/download/v1.8.9/grpcurl_1.8.9_linux_arm64.tar.gz"
GRPZIP="$SCRIPTDIR/grpcurl.zip"




# dialog text formatting

BOLD="\Zb"
NORMAL="\Zn"
RED="\Z1"
GREEN="\Z2"

# dialog variables

DIALOG_CANCEL=1
DIALOG_ESC=255
DIALOG_QUIT="Q"
HEIGHT=16
WIDTH=0

display_result() {
  dialog --title "$1" \
    --no-collapse \
    --colors \
    --msgbox "$result" 8 20
}

display_file() {
 dialog --title "$1" \
    --no-collapse \
    --textbox "$2" 0 0
}


display_info() {
  dialog --infobox "$1" "$2" "$3"
  sleep $4
}

showorking() {
   dialog --infobox "Working..." 4 20
}


#
# setup links and any stored configuration
#

init_starlnk() {
	if [ -d "/opt/bin" ] && [ ! -L "/opt/bin/starlnk" ]; then
		ln -s "/jffs/scripts/starlnk.sh" /opt/bin/starlnk
		chmod 0755 "/opt/bin/starlnk"
	fi
	write_starlnk_config
}

write_starlnk_config() {
	mkdir -p "${SCRIPTDIR}"
	echo "# Starlink settings  #" > "${CONFIG}"
	echo "USER="admin"" >> "${CONFIG}"
	echo "STARLNKIP=192.168.100.1" >> "${CONFIG}"
	if [ ! -x /opt/bin/opkg ]; then
		echo "NOMENU=1" >> "${CONFIG}"
	else
		echo "NOMENU=0" >> "${CONFIG}"
	fi

}

starlinkon() {

if ! ping -q -c 1 -W 1 $STARLNKIP >/dev/null; then
	cat << EOF
Starlink does not appear to be online at $STARLNKIP.
Please check your network and Starlink router.
If the IP address is not $STARLNKIP (highly unusual) then edit $CONFIG
and update the IP address.
EOF
exit 1
fi

}

starlnkcmd() {
grpcurl -plaintext -d {\"$1\":{}} $STARLNKIP:9200 SpaceX.API.Device.Device/Handle | \
sed /{/d | sed /}/d | sed 's/,//' | sed 's/"//g' | awk 'BEGIN { FS = ":" }; { print $1 $2 }' > $2
}

starlnkstatus() {

	starlnkcmd get_status "$STRLTMP"
}

showall() {

	starlnkcmd get_status "$STRLTMP"
}

showstats() {

	gospeed 1
}


showdevinfo() {

	starlnkcmd get_device_info "$STRLTMP"
}


pullarg() {

	cat $1 | sed /{/d | sed /}/d | sed 's/,//' | sed 's/"//g' | awk 'BEGIN { FS = ":" }; { print $1 $2 }' | grep $2 | awk '{ print $2 }'
}

getarg() {

	echo $(grep -m 1 "$1" $STRLTMP | awk '{print $2}')
}

rebootstarlink() {

	if [ "$INTESTMODE" = "0" ]; then
		echo starlnkcmd reboot "$STRLTMP"
	else
		echo testmode
	fi
	

}

stowdish() {

	if [ "$INTESTMODE" = "0" ]; then
		echo starlnkcmd dish_stow "$STRLTMP"
	else
		echo testmode
	fi

}

unstowdish() {
	if [ "$INTESTMODE" = "0" ]; then
		echo grpcurl -plaintext -d {\"dish_stow\":{\"unstow\":true}} 192.168.100.1:9200 SpaceX.API.Device.Device/Handle
	else
		echo testmode
	fi
}




monitorall() {
      while true
      do
         showstats
	 dialog --title "Starlink Dish Link Throughput" --no-collapse --infobox "$dynamicstats" 4 90
         if read -r -t 5; then
            clear
            menu
         fi
#	clear
       done
}

showslstate() {

      showstats
      uptimestate
      dialog --title "Starlink Status" --no-collapse --cr-wrap --msgbox "Starlink state is $(starlnkstate 0)\\n \
Uptime: $csecs\\n \
Dish Link Throughput: $dynamicstats\\n" 10 120
}

slobstruct() {
	
	starlnkcmd get_history "$SLHISTORY"
	nodown=$(grep NO_DOWNLINK $SLHISTORY | wc -l)
	noping=$(grep NO_PINGS $SLHISTORY | wc -l)
	obstruct=$(grep OBSTRUCTED $SLHISTORY | wc -l)
}

slmaxmin() {

	starlnkcmd get_history "$SLHISTORY"

	sed -n '/downlink/,/]/p' "$SLHISTORY" > /tmp/spd.tmp

	maxdown=`human_print_bps $(sort -g /tmp/spd.tmp | tail -1) 1`
	mindown=`human_print_bps $(sed -n '3p' /tmp/spd.tmp) 1`

	sed -n '/uplink/,/]/p' "$SLHISTORY" > /tmp/spd.tmp

	maxup=`human_print_bps $(sort -g /tmp/spd.tmp | tail -1) 1`
	minup=`human_print_bps $(sed -n '3p' /tmp/spd.tmp) 1`

	if [ "$1" = "p" ]; then
		printf "Downlink Max: %sbps   Min: %sbps\\n" $maxdown $mindown
		printf "Uplink   Max: %sbps   Min: %sbps\\n" $maxup $minup
	fi

}


slgpsinfo() {

	starlnkstatus
	gpsvalid=$(grep -m 1 gpsValid $STRLTMP | awk '{print $2}')

	if [ "$gpsvalid" = "true" ]; then
		numsats=$(grep -m 1  gpsSats $STRLTMP | awk '{print $2}')
		azimuth=$(grep -m 1 boresightAzimuthDeg $STRLTMP | awk '{print $2}')
		elevation=$(grep -m 1  boresightElevationDeg $STRLTMP | awk '{print $2}')
		tilt=$(grep -m 1 tiltAngleDeg $STRLTMP | awk '{print $2}')

		starlnkcmd get_location "$STRLTMP"

		latitude=`getarg lat`
		longitude=`getarg lon`
		altitude=`getarg alt`

		printf "\\nGPS is aquired, data valid\\n" > $STRLTMP
		printf "Number of GPS sats acquired: %s\\n" $numsats >> $STRLTMP
		printf "\\nDish Location and Position (in degrees)\\n" >> $STRLTMP
		printf "    Latitude: %3.2f   Longitude: %3.2f  Altitude: %3.2f meters\\n" $latitude $longitude $altitude >> $STRLTMP
		printf "    Azimuth:  %3.2f   Elevation: %3.2f  Tilt Angle: %3.2f\\n" $azimuth $elevation $tilt >> $STRLTMP
	else
		printf "\\nGPS is not acquired, no valid data\\n" > $STRLTMP
	fi

}


slfilestate() {
	showstats
	uptimestate
	printf "\\nStarlink is $(starlnkstate)\\n" > $SLSTATETMP
	echo "Uptime: $csecs" >> $SLSTATETMP
	slgpsinfo
	cat $STRLTMP >> $SLSTATETMP
	printf "\\nSatalite Link Rates and Latency:\\n      %s\\n" "$dynamicstats" >> $SLSTATETMP
	slmaxmin s
	printf "History Logged Throughput\\n" >> $SLSTATETMP
	printf "     Downlink Max: %sbps   Min: %sbps\\n     Uplink   Max: %sbps   Min: %sbps\\n" $maxdown $mindown $maxup $minup >> $SLSTATETMP
	slobstruct
	printf "Link Issues:\\n" >> $SLSTATETMP
	printf "      Lost Downlink: %s   Failed Ping: %s   Obstructed: %s\\n" $nodown $noping $obstruct >> $SLSTATETMP
	printf "\\nRouter Information:\\n" >> $SLSTATETMP
	showdevinfo
	cat $STRLTMP >> $SLSTATETMP
}

convertsecs() {
    d=$(expr $1 / 86400)
    if [ $d -gt 0 ]; then
        daysec=$(expr $d \* 86400)
        secs=$(expr $1 - $daysec)
    else
        secs=$1
    fi
    h=$(expr $secs / 3600)
    m=$(expr $secs % 3600 / 60)
    s=$(expr $secs % 60)
    if [ $2 = "0" ]; then
        printf "\\n%3d days %2d:%02d:%02d" $d $h $m $s
    else
        csecs=$(printf "%3d days %2d:%02d:%02d" $d $h $m $s)
    fi
}

human_print_bps(){
	echo "$(printf "%f" $1 | numfmt --to=iec --format '%.1f')"
}


human_set_bps(){
	spdis="$(printf "%f" $1 | numfmt --to=iec --format '%.1f')"
}


gospeed() {
	starlnkstatus
	downlink=$(pullarg "$STRLTMP" "downlink")
	human_set_bps $downlink 1
	downspeed="$spdis"
	uplink=$(pullarg "$STRLTMP" "uplink")
	human_set_bps $uplink 1
	upspeed="$spdis"
	latency=$(pullarg "$STRLTMP" Latency)
	printf "Down: %s  Up: %s\\n" $downlink $uplink >> /jffs/scripts/starlink/updown
	if [ $1 = "0" ]; then
		printf  "\\nDownlink: %sbps     Uplink: %sbps     Latency: %.1f mSec" $downspeed $upspeed $latency
	else
		dynamicstats=$(printf "Downlink: %sbps    Uplink: %sbps    Latency: %.1f mSec" $downspeed $upspeed $latency)
	fi
}

gospeedlog() {
	on=$(date +"%m-%d %H:%M")
	downlink=$(pullarg "$STRLTMP" "downlink")
	downspeed=$(human_print_bps $downlink 1)
	uplink=$(pullarg "$STRLTMP" "uplink")
	upspeed=$(human_print_bps $uplink 1)
	latency=$(pullarg "$STRLTMP" Latency)
	printf "$downspeed/$upspeed  $latency $on\\n" >> $SPDLOG
	printf "$on,$downlink,$uplink,$latency\\n" >> $SPDLOG.csv
}

goall() {

	seconds=$(pullarg "$STRLTMP" "uptime")
	convertsecs $seconds 0
	gospeed
}

uptimestate() {
	seconds=$(pullarg "$STRLTMP" "uptime")
	convertsecs $seconds 1
}

starlnkstate() {
	
	starlnkuptime

	if [ -z "$2" ] || [ $2 = "0" ]; then
		pprint=0
	else
		pprint=1

	fi

	if [ $uptime -gt 0 ]; then
		if [ $pprint = "0" ]; then
			echo "Up"
		else
			echo "${GREEN}Up"
		fi
	else
		if [ $pprint = "0" ]; then
			echo "Down"
		else
			echo "${RED}Down"
		fi
	fi
}

installgrpcurl() {

	/usr/sbin/curl -fL --retry 3 "$GRPCURLAPP" -o "$GRPZIP"
	if [ ! -z "$GRPZIP" ]; then
		/bin/tar xzf "$GRPZIP" -C "$SCRIPTDIR"
		cp "$SCRIPTDIR/grpcurl" /opt/sbin
		rm "$SCRIPTDIR/grpcurl" "$GRPZIP"
	else
		echo "Error downloading grpcurl..."
	fi
	
}

starlnkinstall() {

	if [ -x "$SCRIPTLOC" ] && [ -f "$CONFIG" ]; then
		printf "\\nIt looks like starlnk has already been installed\\n"
		printf "Install again (Y/N)? "
		read a
		if [ "$a" = "n" ] || [ "$a" = "N" ]; then
			exit
		else
			printf "\\nOk, running install again\\n"
		fi
	fi

	if [ "$(uname -m)" != "aarch64" ]; then
		printf "Sorry, $SCRIPTNAME requires an aarch64 type router...\\n"
		exit 1
	fi

	cat << EOF

	This will install the Starlink addon - starlnk

	This addon requires an additional program called grpcurl which will be downloaded from
	the grpcurl project page on github.
	A request has been made to the Entware team to include grpcurl in the Entware repository.
	starlnk requires grpcurl to retrieve information from the Starlink system.

	If you do not want this installed, (starlnk will be removed as well)
	Press [N]
EOF
	read a

	if [ "$a" = "N" ] || [ "$a" = "n" ]; then
		echo "No problem, hopefully Entware supports it soon!"
		echo "Removing starlnk.sh"
		rm -f ./starlnk.sh
		exit 1
	fi
	
	
	if [ ! -x /opt/bin/opkg ]; then
		printf "\\nstarlnk requires Entware to be installed\\n"
		printf "\\nInstall Entware using amtm and run starlnk.sh install again.\\n\\n"
		exit 1
	fi
	echo "Creating script directory ${SCRIPTDIR}"
	mkdir -p "${SCRIPTDIR}"
	echo "Checking for and installing required apps"
	opkg update
	for app in dialog jq ; do
		if [ ! -x /opt/bin/$app ]; then
			echo "Installing $app to /opt/bin"
			opkg install $app
		fi
		if [ ! -x /opt/bin/numfmt ]; then
			echo "Installing numfmt to /opt/bin"
			opkg install coreutils-numfmt
		fi
	done

	echo "Installing grpcurl to /opt/sbin"
	installgrpcurl
	if [ ! -x /opt/sbin/grpcurl ]; then
		echo "There was a problem installing grpcurl..."
		echo 
		exit 1
	fi
	init_starlnk
	cat <<EOF

	     starlnk.sh     Version $SCRIPTVER
	starlnk.sh has been copied to $SCRIPTDIR and a link set in /opt/bin as starlnk

	You can run it from /jffs/scripts/starlnk.sh or /opt/bin/starlnk. If /opt/bin is in
	your PATH, you can simply run starlnk.

	starlnk.sh can be run via a menu system based on dialog. Just run starlnk.sh without any command
	command line arguements.

	It can also run in a non-menu mode by passing an argument to starlnk.
	i.e. starlnk help
EOF
}

removestarlnk() {
	rm -rf "${SCRIPTDIR}"
	if [ -d /opt/bin ]; then
		rm -f /opt/bin/starlnk
	fi
	if [ -x /opt/sbin/grpcurl ]; then
		rm -f /opt/sbin/grpcurl
	fi
	rm -f /jffs/scripts/starlnk.sh
}

starlnkuninstall() {
	printf "\\n Uninstall starlnk and it's data/directory? [Y=Yes] ";read -r continue
	case "$continue" in
		Y|y) printf "\\n Uninstalling...\\n"
	           removestarlnk
		   printf "\\nstarlnk uninstalled\\n"
		;;
		*) printf "\\nstarlnk NOT uninstalled\\n"
		;;
	esac
}

starlnkupdate() {


	if [ -x "$SCRIPTLOC" ] && [ -f "$CONFIG" ]; then
		printf "\\nDownload and install the latest version of strlnk (Y/N)? "
		read a
		if [ "$a" = "n" ] || [ "$a" = "N" ]; then
			exit
		else
			printf "\\nOk, downloading starlnk again\\n"
			/usr/sbin/curl --retry 3 "https://raw.githubusercontent.com/JGrana01/starlnk/master/starlnk.sh" -o "/jffs/scripts/starlnk.sh" && chmod 0755 "/jffs/scripts/starlnk.sh"
			printf "\\n\\nDone.\\n"
		fi
	else
		printf "\\nNo $SCRIPTLOC or $CONFIG found"
		printf "\\nPlease download and install manually"
	fi
}


menu() {

#set -x
. "$CONFIG"
starlinkon

while true; do
  exec 3>&1
  starlnkuptime
  convertsecs $uptime 1
  selection=$(dialog \
    --backtitle "starlnk - Starlink Utility  $SCRIPTVER" \
    --title "Menu" \
    --clear \
    --colors \
    --cancel-label "Exit" \
    --menu "Please select:" $HEIGHT $WIDTH 4 \
  "1" "Monitor Sat. Link Statistics" \
  "2" "Show Present Status" \
  "3" "Show Router Information" \
  "4" "Show GPS Information" \
  "5" "Show all Starlink information" \
  "R" "Reboot Starlink System" \
  "S" "Stow Starlink Dish" \
  "U" "Uninstall starlnk.sh" \
    2>&1 1>&3)
  exit_status=$?
  exec 3>&-
  case $exit_status in
    $DIALOG_CANCEL)
      clear
      echo "Program terminated."
      exit
      ;;
    $DIALOG_ESC)
      clear
      echo "Program aborted." >&2
      exit 1
      ;;
  esac
  case $selection in
    1 )
      while true
      do
         showstats
	 dialog --title "Starlink Dish Link Throughput" --no-collapse --infobox "$dynamicstats" 4 80
         if read -r -t 3; then
            clear
            menu
         fi
#	clear
       done
      ;;
    2)
      showorking
      slfilestate
      display_file "Starlink Status" $SLSTATETMP
      ;;
    3 )
      showdevinfo
      display_file "Device Info" $STRLTMP
      ;;
    4 )
      slgpsinfo
      display_file "GPS Info" $STRLTMP
      ;;
    5 )
      showall
      display_file "All Starlink Info" $STRLTMP
      ;;
    S )
	dialog --title "Stow Starlink Dish" \
	--backtitle "starlnk" \
	--defaultno \
	--yesno "Are you sure you want to stow the Starlink dish?" 7 60
	response=$?
	case $response in
   	0)
	   display_info "Stowing...(not really)" 4 30 5
	   stowdish
	   display_info "To unstow and put back into service, power cycle the system..." 4 80 5
	   clear
	;;
   	1)
	   display_info "Not Rebooting" 5 20 2
	;;
   	255)
	   display_info "Not Rebooting" 5 20 2
        ;;
	esac
        ;;
    R )
	dialog --title "Reboot Starlink" \
	--backtitle "starlnk" \
	--defaultno \
	--yesno "Are you sure you want to reboot the Starlink System (takes ~3 min.s)?" 7 60
	response=$?
	case $response in
   	0)
	   display_info "Rebooting... (not really)" 4 30 5
	   rebootstarlink
	   display_info "See you in 3+ minutes, exiting" 4 35 2
	   clear
	   exit
	;;
   	1)
	   display_info "Not Rebooting" 5 20 2
	;;
   	255)
	   display_info "Not Rebooting" 5 20 2
        ;;
	esac
        ;;

    Q )
        clear
        exit
      ;;
    U )
	dialog --title "Uninstall starlnk" \
	--defaultno \
	--yesno "Are you sure you want to uninstall starlnk and all it's files ?" 7 60
	response=$?
	case $response in
   	0)
	   display_info "Uninstalling..." 4 20 3
	   removestarlnk
	   display_info "starlnk uninstalled, exiting" 4 35 2
	   clear
	   exit
	;;
   	1)
	   display_info "starlnk not removed" 5 20 2
	;;
   	255)
	   display_info "starlnk not removed" 5 20 2
        ;;
	esac
   esac
done
}

pause() {
   echo
   echo -n "Paused, hit any key to continue..."
   read a
}

convertConfig() {
  cat $CONFIG | tr "," "\n" | tr -d "^ " | sed 's/\"//g' | sed 's/:/|/' | sed 's/{//g' | sed 's/}//g' | column -t -s "|" > $CONFIGC
  jq '.' $CONFIG > $CONFIGP
}

starlnkuptime() {

	starlnkcmd get_status "$STRLTMP"
	uptime=$(pullarg "$STRLTMP" uptime)
}


printhelp() {
	cat <<EOF

starlnk is a utility that is used to monitor and do some management of a Starlink system.

It can display information about the Satellite Dish and router and also can be used to stow or reboot Starlink.

starlnk runs either a menu based system using dialog or non-menu by running without any command line
arguments or in script mode where it will return results of a command or do an
action on the command.
To run in menu mode, just type:

$ starlnk

In scripts mode, enter an argument:

$ starlnk arg

EOF
echo "More.. press Enter to continue"
read a
cat <<EOF

The list of script arguments are:

menu	- Run starlnk in a menu driven mode using Linux dialog. This is the default
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

help - show this help info
	
install - setup the script directory, copy the program, link to /opt/bin (if its
	         there!) and setup a default config file

uninstall - remove starlnk and its data/directories
EOF
}


gomenu() {

	if [ ! -f "${CONFIG}" ]; then
		write_starlnk_config
	fi
	. "${CONFIG}"


	if [ "$NOMENU" = "0" ]; then
		menu
	else
		printf "starlnk menu mode requires Entware.\\n"
		exit
	fi
}

if [ -z "$1" ]; then
	gomenu
	exit 0
fi

if [ $1 = "install" ];then
	starlnkinstall
	exit 0
fi


if [ ! -f "${CONFIG}" ]; then
	printf "\\nSorry, no $CONFIG\\n"
	printf "Try to run the install program again:\\n"
	printf "   starlnk.sh install\\n"
	exit 1
fi

. "${CONFIG}"

case "$1" in
	rates)
		starlinkon
		echo
      		while true
      			do
         		showstats
	 		printf "\\r%s " "$dynamicstats"
         	if read -r -t 2; then
            		echo
			exit 0
         	fi
       		done
		;;
	status)
		starlinkon
		gospeed 0
		sleep 5
		exit 0
		;;
	linkstate)
		starlinkon
		slfilestate
		cat $SLSTATETMP
		exit 0
		;;
	router)
		starlinkon
		showdevinfo
		exit 0
		;;
	gps)
		starlinkon
		slgpsinfo
		cat $STRLTMP
		exit 0
		;;

	maxmin)
		starlinkon
		printf "History Throughput\\n"
		slmaxmin p
		exit 0
		;;
	stow) 
		starlinkon
		stowdish
		logger -t "starlnk.sh" "Stowed Dish"
         	exit 0
		;;
	unstow) 
		starlinkon
		unstowdish
		logger -t "starlnk.sh" "Stowed Dish"
         	exit 0
		;;
	all)
		starlinkon
		logger -t "starlnk.sh" "Getting all starlnk Gateway status"
		showall
		cat $STRLTMP
        	exit 0
		;;
	reboot)
		starlinkon
		reboot
		logger -t "starlnk.sh" "Rebooted starlnk"
		if [ $LOGREBOOTS = 1 ]; then
			awk -F, '{$2=$2+1}1' OFS=, $REBOOTLOGFILE > /tmp/rbc && mv /tmp/rbc $REBOOTLOGFILE
			logger -t "starlnk.sh" "Logged Reboot Count"
		fi
		exit 0
		;;
	install)
		starlnkinstall
		exit 0
		;;
	menu)
		gomenu
		exit 0
		;;
	help)
		printhelp
		exit 0
		;;
	uninstall)
		starlnkuninstall
		exit 0
		;;
	update)
		starlnkupdate
		exit 0
		;;
	*)
		echo "Unknown command"
		exit 1
		;;
esac

