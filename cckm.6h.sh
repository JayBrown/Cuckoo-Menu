#!/bin/zsh
# shellcheck shell=bash

# <bitbar.title>Cuckoo Menu</bitbar.title>
# <bitbar.version>v1.0-beta10-b8</bitbar.version>
# <bitbar.author>Joss Brown (pseud.)</bitbar.author>
# <bitbar.author.github>JayBrown</bitbar.author.github>
# <bitbar.desc>Manage the Cuckoo Agent (cck) from the menu bar</bitbar.desc>
# <bitbar.image>https://raw.githubusercontent.com/JayBrown/Cuckoo-Menu/master/img/CuckooMenu_screengrab.png</bitbar.image>
# <bitbar.dependencies>CoreLocationCLI,sunshine</bitbar.dependencies>
# <bitbar.abouturl>https://github.com/JayBrown/bitbar-Cuckoo-Menu</bitbar.abouturl>
# <bitbar.droptypes>filenames</bitbar.droptypes>

# Cuckoo Menu
# BitBar plugin
# Version: 1.0.0 beta 10 build 8
# Note: beta number conforms to BitBar's beta number
# Category: Time
#
# BitBar: https://github.com/matryer/bitbar & https://getbitbar.com
# BitBar v2.0.0 beta10 (requisite): https://github.com/matryer/bitbar/releases/tag/v2.0.0-beta10
#
# CoreLocationCLI: https://github.com/fulldecent/corelocationcli
# CoreLocationCLI v3.1.0 (dependency): https://github.com/fulldecent/corelocationcli/releases/tag/3.1.0
#
# sunshine: https://github.com/crescentrose/sunshine
# sunshine v0.3.0 (dependency): https://github.com/crescentrose/sunshine/releases
#
# Original Cuckoo PreferencePane (probably abandonware): http://toastycode.com/cuckoo/

export LANG=en_US.UTF-8
export PATH=/usr/bin:/usr/sbin:/bin:/sbin:/usr/local/bin:/opt/local/bin:/opt/sw/bin:/sw/bin

# BitBar & dependency stuff
monofont="font=Menlo-Regular size=10"
version="1.0.0" # only for display
cversion="1.00" # for version comparisons
betaversion="10"
build="8"
if [[ $betaversion ]] ; then
	vmisc=" beta $betaversion"
else
	vmisc=""
fi
process="cckm"
uiprocess="Cuckoo Menu"
bbminv="2.0.0-beta10"
bbdlurl="https://github.com/matryer/bitbar/releases/tag/v2.0.0-beta10"
bbloc=$(ps aux | grep "BitBar.app" | grep -v "grep" | awk '{print substr($0, index($0,$11))}' | awk -F"/Contents/" '{print $1}')
if [[ $bbloc ]] ; then
	bbprefs="$bbloc/Contents/Info.plist"
	bbversion=$(/usr/libexec/PlistBuddy -c "Print:CFBundleVersion" "$bbprefs" 2>/dev/null)
	[[ $bbversion != "$bbminv" ]] && correctbb=false || correctbb=true
else
	correctbb=true
fi
minsshversion="0.30"

# user stuff
accountname=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }')
HOMEDIR=$(eval echo "~$accountname")
usersoundsdir="$HOMEDIR/Library/Sounds"
systemsoundsdir="/System/Library/Sounds"
coresoundsdir="/System/Library/Components/CoreAudio.component/Contents/SharedSupport/SystemSounds"
if [[ -d "$HOMEDIR/.local/bin" ]] ; then
	export PATH=$PATH:"$HOMEDIR/.local/bin"
else
	if [[ -d "$HOMEDIR/local/bin" ]] ; then
		export PATH=$PATH:"$HOMEDIR/local/bin"
	else
		if [[ -d "$HOMEDIR/bin" ]] ; then
			export PATH=$PATH:"$HOMEDIR/bin"
		fi
	fi
fi

# cck stuff
mypath="$0"
myname=$(basename "$mypath")
prefs="local.lcars.cck"
agent_loc="$HOMEDIR/Library/LaunchAgents/$prefs.plist"
disabledir="$HOMEDIR/Library/LaunchAgents (Disabled)"
disable_loc="$disabledir/$prefs.plist"
prefsloc="$HOMEDIR/Library/Preferences/$prefs.plist"
configdir="$HOMEDIR/Library/Application Support/$prefs"
bindir="$configdir/bin"
cck_loc="$bindir/cck"
icon_loc="$configdir/Cuckoo.png"
blacklist_loc="$configdir/blacklist.txt"
soundsdir="$configdir/sounds"
defaultsound="Cuckoo Clock.mp3"
stdout_loc="/tmp/local.lcars.cck.stdout"
stderr_loc="/tmp/local.lcars.cck.stderr"
defselectfolder="$HOMEDIR/Music"
defdownloadfolder="$HOMEDIR/Downloads"
cckmurl="https://github.com/JayBrown/Cuckoo-Menu"
cckmdlurl="$cckmurl/releases"
cckmlatestdlurl="$cckmdlurl/latest"
sundata_loc="$configdir/solar_data"
easterdates_loc="$configdir/triduum"
cckmrelurl="https://raw.githubusercontent.com/JayBrown/Cuckoo-Menu/master/VERSION"

# dependencies
ssh_loc="$bindir/sunshine"
locsshversion=$(sunshine -V 2>/dev/null | awk '{print $2}' | sed 's/\(.*\)\./\1/' 2>/dev/null)
if ! [[ $locsshversion ]] ; then
	sshinstalled=false
else
	if [[ $locsshversion == "$minsshversion" ]] ; then
		sshinstalled=true
	else
		sshinstalled=false
	fi
fi
clc_loc="$bindir/CoreLocationCLI"
crcclc="ef2e09ff"
locclc=$(command -v CoreLocationCLI 2>/dev/null)
if ! [[ $locclc ]] ; then
	clcinstalled=false
else
	crclocclc=$(crc32 "$locclc" 2>/dev/null)
	if ! [[ $crclocclc ]] ; then
		clcinstalled=false
	else
		if [[ $crclocclc == "$crcclc" ]] ; then
			clcinstalled=true
		else
			clcinstalled=false
		fi
	fi
fi

# system beep
_beep () {
	osascript -e 'beep' &>/dev/null
}

# install / uninstall / reinstall / reset preferences
if [[ $1 =~ ^(cckinstall|cckuninstall|cckreinstall|resetprefs|resetblacklist)$ ]] ; then
	rm -f "/usr/local/bin/cck" 2>/dev/null
	rm -rf "$HOMEDIR/.config/cck" 2>/dev/null
	if [[ $1 == "resetblacklist" ]] ; then
		resetblchoice=$(osascript 2>/dev/null <<EOR
beep
tell application "System Events"
	activate
	set theUserChoice to button returned of (display alert "Are you sure that you want to reset your Cuckoo Menu applications blacklist?" message "You will keep your primary settings." as critical buttons {"Cancel", "Reset"} default button 1 cancel button "Cancel" giving up after 180)
end tell
EOR
		)
		if [[ $resetblchoice ]] ; then
			currentdate=$(date)
			if echo -n "" > "$blacklist_loc" &>/dev/null ; then
				echo "$process [$currentdate] blacklist reset" >> "$stdout_loc"
				afplay -q 1 -r 1.00 -v 0.10 "$soundsdir/$defaultsound" 2>/dev/null
			else
				echo "$process [$currentdate] error resetting blacklist" >> "$stderr_loc"
			fi
		fi
		exit
	elif [[ $1 == "resetprefs" ]] ; then
		resetchoice=$(osascript 2>/dev/null <<EOR
beep
tell application "System Events"
	activate
	set theUserChoice to button returned of (display alert "Are you sure that you want to reset your Cuckoo Menu preferences?" message "You will keep your current applications blacklist, but lose all of your primary settings." as critical buttons {"Cancel", "Reset"} default button 1 cancel button "Cancel" giving up after 180)
end tell
EOR
		)
		if [[ $resetchoice ]] ; then
			"$cck_loc" --init 2>/dev/null
			afplay -q 1 -r 1.00 -v 0.10 "$soundsdir/$defaultsound" 2>/dev/null
		fi
		exit
	elif [[ $1 == "cckuninstall" ]] ; then
		uninstallchoice=$(osascript 2>/dev/null <<EOC
beep
tell application "System Events"
	activate
	set theUserChoice to button returned of (display alert "Are you sure that you want to uninstall Cuckoo Menu?" message "The cckm BitBar script will be moved to the trash, all other files will be removed, and you will lose all of your settings and blacklist entries." as critical buttons {"Cancel", "Uninstall"} default button 1 cancel button "Cancel" giving up after 180)
end tell
EOC
		)
		! [[ $uninstallchoice ]] && exit
	else
		downloadfolder=$(/usr/libexec/PlistBuddy -c "Print:DownloadsFolder" "$prefsloc" 2>/dev/null)
		! [[ $downloadfolder ]] && downloadfolder="$defdownloadfolder"
		! [[ -d "$downloadfolder" ]] && downloadfolder="$defdownloadfolder"
		payloaddir=$(osascript 2>/dev/null << EOD
tell application "System Events"
	activate
	set theDownloadDir to "$downloadfolder" as string
	set theInstallFolder to choose folder with prompt "Select the Cuckoo Menu 'payload' folder…" default location theDownloadDir
	set theInstallFolder to (POSIX path of theInstallFolder)
	theInstallFolder as text
end tell
EOD
		)
		! [[ $payloaddir ]] && exit
		cck_iloc="$payloaddir/cck"
		agent_iloc="$payloaddir/$prefs.plist"
		ssh_iloc="$payloaddir/sunshine"
		clc_iloc="$payloaddir/CoreLocationCLI"
		dsnd_iloc="$payloaddir/sounds/$defaultsound"
		! [[ -f "$cck_iloc" ]] && exit
		! [[ -f "$agent_iloc" ]] && exit
		! [[ -f "$ssh_iloc" ]] && exit
		! [[ -f "$clc_iloc" ]] && exit
		! [[ -f "$dsnd_iloc" ]] && exit
	fi
	launchctl stop "$prefs" 2>/dev/null
	launchctl unload "$agent_loc" 2>/dev/null
	killall sunshine 2>/dev/null
	killall CoreLocationCLI 2>/dev/null
	if [[ $1 != "cckreinstall" ]] ; then
		rm -f "$ssh_loc" "$clc_loc" "$agent_loc" "$disable_loc" "$cck_loc" "$prefsloc" "$stdout_loc" "$stderr_loc" 2>/dev/null
	fi
	if [[ $1 == "cckuninstall" ]] ; then
		afplay -q 1 -r 1.00 -v 0.10 "$soundsdir/$defaultsound" 2>/dev/null
		rm -rf "$configdir" 2>/dev/null
		mv "$0" "$HOMEDIR/.Trash/$myname" 2>/dev/null
		osascript 2>/dev/null <<EOR
tell application "BitBar" to quit
delay 1
tell application "BitBar" to activate
EOR
		exit
	else
		[[ $1 != "cckreinstall" ]] && rm -rf "$configdir" 2>/dev/null
	fi
	if [[ $1 == "cckreinstall" ]] ; then
		defaults write "$prefs" DownloadsFolder "$payloaddir" 2>/dev/null
		defaults write "$prefs" available "" 2>/dev/null
		! [[ -d "$bindir" ]] && mkdir -p "$bindir" 2>/dev/null
		! [[ -d "$soundsdir" ]] && mkdir -p "$soundsdir" 2>/dev/null
		! [[ -f "$soundsdir/$defaultsound" ]] && cp "$dsnd_iloc" "$soundsdir/$defaultsound" 2>/dev/null
		currentdate=$(date)
		if cp "$cck_iloc" "$cck_loc" &>/dev/null ; then
			if chmod +x "$cck_loc" &>/dev/null ; then
				echo "$process [$currentdate] cck reinstalled" >> "$stdout_loc"
			else
				echo "$process [$currentdate] reinstall error (cck:chmod)" >> "$stderr_loc"
			fi
		else
			echo "$process [$currentdate] reinstall error (cck:cp)" >> "$stderr_loc"
		fi
		sleep 1
		currentdate=$(date)
		if cp "$ssh_iloc" "$ssh_loc" &>/dev/null ; then
			if chmod +x "$ssh_loc" &>/dev/null ; then
				echo "$process [$currentdate] sunshine reinstalled" >> "$stdout_loc"
			else
				echo "$process [$currentdate] reinstall error (sunshine:chmod)" >> "$stderr_loc"
			fi
		else
			echo "$process [$currentdate] reinstall error (sunshine:cp)" >> "$stderr_loc"
		fi
		sleep 1
		currentdate=$(date)
		if cp "$clc_iloc" "$clc_loc" &>/dev/null ; then
			if chmod +x "$clc_loc" &>/dev/null ; then
				echo "$process [$currentdate] CoreLocationCLI reinstalled" >> "$stdout_loc"
			else
				echo "$process [$currentdate] reinstall error (CoreLocationCLI:chmod)" >> "$stderr_loc"
			fi
		else
			echo "$process [$currentdate] reinstall error (CoreLocationCLI:cp)" >> "$stderr_loc"
		fi
		sleep 1
		newagent=$(sed "s-BINDIR-$bindir-" 2>/dev/null < "$agent_iloc")
		currentdate=$(date)
		if echo "$newagent" > "$agent_loc" 2>/dev/null ; then
			echo "$process [$currentdate] cck agent reinstalled" >> "$stdout_loc"
		else
			echo "$process [$currentdate] cck agent reinstall error" >> "$stderr_loc"
		fi
		sleep 1
		currentdate=$(date)
		if launchctl load "$agent_loc" &>/dev/null ; then
			echo "$process [$currentdate] cck agent loaded" >> "$stdout_loc"
		else
			echo "$process [$currentdate] error loading cck agent" >> "$stderr_loc"
		fi
		afplay -v -q 1 -r 1.00 -v 0.10 "$soundsdir/$defaultsound" 2>/dev/null
		exit
	fi
	mkdir -p "$soundsdir" 2>/dev/null
	mkdir "$bindir" 2>/dev/null
	cp -r "$payloaddir/sounds" "$configdir" 2>/dev/null
	sleep .5
	! [[ -d "$soundsdir" ]] && mkdir "$soundsdir" 2>/dev/null
	sleep .5
	! [[ -f "$soundsdir/$defaultsound" ]] && cp "$dsnd_iloc" "$soundsdir/$defaultsound" 2>/dev/null
	cp "$cck_iloc" "$cck_loc" 2>/dev/null
	touch "$blacklist_loc" 2>/dev/null
	chmod +x "$cck_loc" 2>/dev/null
	cp "$ssh_iloc" "$ssh_loc" 2>/dev/null
	cp "$clc_iloc" "$clc_loc" 2>/dev/null
	chmod +x "$ssh_loc" 2>/dev/null
	newagent=$(sed "s-BINDIR-$bindir-" 2>/dev/null < "$agent_iloc")
	chmod +x "$clc_loc" 2>/dev/null
	"$cck_loc" --init 2>/dev/null
	defaults write "$prefs" DownloadsFolder "$payloaddir" 2>/dev/null
	echo "$newagent" > "$agent_loc" 2>/dev/null
	sleep 1
	currentdate=$(date)
	if launchctl load "$agent_loc" &>/dev/null ; then
		echo "$process [$currentdate] cck agent loaded" >> "$stdout_loc"
	else
		echo "$process [$currentdate] error loading cck agent" >> "$stderr_loc"
	fi
	afplay -v -q 1 -r 1.00 -v 0.10 "$soundsdir/$defaultsound" 2>/dev/null
	exit
fi

# general settings
if [[ $1 == "settings" ]] ; then
	if [[ $2 == "interval" ]] ; then
		shift
		shift
		currentinterval="$*"
		intervalinput=$(osascript 2>/dev/null << EOI
tell application "System Events"
	activate
	set theLogoPath to POSIX file "$icon_loc"
	set theNewInterval to text returned of (display dialog "Enter the new chime interval." & return & return & "Available values: 60, 30 (default), 20, 15, 10 and 5 minutes." ¬
		default answer "$currentinterval" ¬
		buttons {"Cancel", "Set"} ¬
		default button 2 ¬
		cancel button "Cancel" ¬
		with title "$uiprocess: Set Chime Interval" ¬
		with icon file theLogoPath ¬
		giving up after 180)
end tell
EOI
		)
		! [[ $intervalinput ]] && exit
		! [[ $intervalinput =~ ^[0-9]+$ ]] && exit
		[[ $intervalinput == "05" ]] && intervalinput=5
		[[ $intervalinput -gt 60 ]] && intervalinput=60
		[[ $intervalinput -lt 5 ]] && intervalinput=5
		! [[ $intervalinput =~ ^(5|10|15|20|30|60|05)$ ]] && exit
		currentdate=$(date)
		if [[ $intervalinput != "$currentinterval" ]] ; then
			if defaults write "$prefs" Interval "$intervalinput" &>/dev/null ; then
				echo "$process [$currentdate] Interval: $currentinterval > $intervalinput" >> "$stdout_loc"
			else
				echo "$process [$currentdate] error setting Interval" >> "$stderr_loc"
			fi
		else
			echo "$process [$currentdate] Interval unchanged" >> "$stderr_loc"
		fi
	elif [[ $2 == "notafter" ]] ; then
		shift
		shift
		currentfinal=$(echo "$*" | awk -F":" '{print $1}')
		finalchimeinput=$(osascript 2>/dev/null << EOC
tell application "System Events"
	activate
	set theLogoPath to POSIX file "$icon_loc"
	set theNewLastChime to text returned of (display dialog "Enter the new full hour for the last chime of the day." & return & return & "Please use the standard international 24-hour clock format without leading zeros and without minutes. Available range: 0–23 (conforms to: 12 AM–11 PM)" ¬
		default answer "$currentfinal" ¬
		buttons {"Cancel", "Set"} ¬
		default button 2 ¬
		cancel button "Cancel" ¬
		with title "$uiprocess: Set Last Chime Hour" ¬
		with icon file theLogoPath ¬
		giving up after 180)
end tell
EOC
		)
		finalchimeinput=$(echo "$finalchimeinput" | awk -F":" '{print $1}')
		! [[ $finalchimeinput ]] && exit
		! [[ $finalchimeinput =~ ^[0-9]+$ ]] && exit
		if [[ $finalchimeinput -gt 23 ]] || [[ $finalchimeinput -lt 0 ]] ; then
			firstchimeinput=23
		fi
		currentdate=$(date)
		if [[ $finalchimeinput != "$currentfinal" ]] ; then
			if defaults write "$prefs" notAfter "$finalchimeinput" &>/dev/null ; then
				echo "$process [$currentdate] notAfter: $currentfinal > $finalchimeinput" >> "$stdout_loc"
			else
				echo "$process [$currentdate] error setting notAfter" >> "$stderr_loc"
			fi
		else
			echo "$process [$currentdate] notAfter unchanged ($finalchimeinput)" >> "$stderr_loc"
		fi
	elif [[ $2 == "notbefore" ]] ; then
		shift
		shift
		currentfirst=$(echo "$*" | awk -F":" '{print $1}')
		firstchimeinput=$(osascript 2>/dev/null << EOC
tell application "System Events"
	activate
	set theLogoPath to POSIX file "$icon_loc"
	set theNewFirstChime to text returned of (display dialog "Enter the new full hour for the first chime of the day." & return & return & "Please use the standard international 24-hour clock format without leading zeros and without minutes. Available range: 0–23 (conforms to: 12 AM–11 PM)" ¬
		default answer "$currentfirst" ¬
		buttons {"Cancel", "Set"} ¬
		default button 2 ¬
		cancel button "Cancel" ¬
		with title "$uiprocess: Set First Chime Hour" ¬
		with icon file theLogoPath ¬
		giving up after 180)
end tell
EOC
		)
		firstchimeinput=$(echo "$firstchimeinput" | awk -F":" '{print $1}')
		! [[ $firstchimeinput ]] && exit
		! [[ $firstchimeinput =~ ^[0-9]+$ ]] && exit
		if [[ $firstchimeinput -gt 23 ]] || [[ $firstchimeinput -lt 0 ]] ; then
			firstchimeinput=7
		fi
		currentdate=$(date)
		if [[ $firstchimeinput != "$currentfirst" ]] ; then
			if defaults write "$prefs" notBefore "$firstchimeinput" &>/dev/null ; then
				echo "$process [$currentdate] notBefore: $currentfirst > $firstchimeinput" >> "$stdout_loc"
			else
				echo "$process [$currentdate] error setting notBefore" >> "$stderr_loc"
			fi
		else
			echo "$process [$currentdate] notBefore unchanged ($firstchimeinput)" >> "$stderr_loc"
		fi
	elif [[ $2 == "calswitch" ]] ; then
		switcherror=false
		if [[ $3 == "eastern" ]] ; then
			if defaults write "$prefs" Western -bool false &>/dev/null ; then
				easter=$(ncal -o)
			else
				switcherror=true
			fi
		elif [[ $3 == "western" ]] ; then
			if defaults write "$prefs" Western -bool true &>/dev/null ; then
				easter=$(ncal -e)
			else
				switcherror=true
			fi
		fi
		currentdate=$(date)
		if $switcherror ; then
			echo "$process [$currentdate] error switching to $3 calendar" >> "$stderr_loc"
			rm -f "$easterdates_loc" 2>/dev/null
		else
			echo "$process [$currentdate] switched to $3 calendar" >> "$stdout_loc"
			thisyear=$(date +%Y)
			eastersun=$(date -jf "%B %e %Y" "$easter" +%j | sed 's/^0*//')
			eastersat=$((eastersun-1))
			goodfri=$((eastersat-1))
			maundythu=$((goodfri-1))
			if ! echo -e "$thisyear\n$maundythu;$goodfri;$eastersat;$eastersun;" > "$easterdates_loc" &>/dev/null ; then
				echo "$process [$currentdate] error saving new Easter dates" >> "$stderr_loc"
				rm -f "$easterdates_loc" 2>/dev/null
			else
				echo "$process [$currentdate] saved new Easter dates" >> "$stdout_loc"
			fi
		fi
	elif [[ $2 == "warnhours" ]] ; then
		shift
		shift
		currentwarnhour="$*"
		warnhourinput=$(osascript 2>/dev/null << EOC
tell application "System Events"
	activate
	set theLogoPath to POSIX file "$icon_loc"
	set theNewWarnHour to text returned of (display dialog "Enter how many hours before sunrise you want to be notified (beep & notification)." ¬
		default answer "$currentwarnhour" ¬
		buttons {"Cancel", "Set"} ¬
		default button 2 ¬
		cancel button "Cancel" ¬
		with title "$uiprocess: Sunrise Warning" ¬
		with icon file theLogoPath ¬
		giving up after 180)
end tell
EOC
		)
		! [[ $warnhourinput ]] && exit
		! [[ $warnhourinput =~ ^[0-9]+$ ]] && exit
		if [[ $warnhourinput -gt 23 ]] || [[ $warnhourinput -lt 1 ]] ; then
			warnhourinput=4
		fi
		currentdate=$(date)
		if [[ $warnhourinput != "$currentwarnhour" ]] ; then
			if defaults write "$prefs" SunriseWarnHours "$warnhourinput" &>/dev/null ; then
				echo "$process [$currentdate] SunriseWarnHours: $currentwarnhour > $warnhourinput" >> "$stdout_loc"
			else
				echo "$process [$currentdate] error setting SunriseWarnHours" >> "$stderr_loc"
			fi
		else
			echo "$process [$currentdate] notBefore unchanged ($warnhourinput)" >> "$stderr_loc"
		fi
	fi
	exit		
fi

# agent routines
if [[ $1 == "agent" ]] ; then
	currentdate=$(date)
	if [[ $2 == "disable" ]] ; then
		if [[ $3 != "unloaded" ]] ; then
			if ! launchctl unload "$agent_loc" &>/dev/null ; then
				echo "$process [$currentdate] error unloading agent" >> "$stderr_loc"
				exit
			fi
		else
			echo "$process [$currentdate] agent already unloaded" >> "$stdout_loc"
		fi
		echo "$process [$currentdate] unloaded agent" >> "$stdout_loc"
		if ! [[ -d "$disabledir" ]] ; then
			if ! mkdir "$disabledir" &>/dev/null ; then
				echo "$process [$currentdate] error creating directory" >> "$stderr_loc"
				exit
			else
				echo "$process [$currentdate] created directory" >> "$stdout_loc"
			fi
		fi
		if ! mv "$agent_loc" "$disable_loc" &>/dev/null ; then
			echo "$process [$currentdate] error disabling agent" >> "$stderr_loc"
		else
			echo "$process [$currentdate] disabled agent" >> "$stdout_loc"
		fi
	elif [[ $2 == "enable" ]] ; then
		if ! [[ -f "$disable_loc" ]] ; then
			echo "$process [$currentdate] error finding agent" >> "$stderr_loc"
		else
			echo "$process [$currentdate] agent found" >> "$stdout_loc"
			if ! mv "$disable_loc" "$agent_loc" &>/dev/null ; then
				echo "$process [$currentdate] error enabling agent" >> "$stderr_loc"
			else
				echo "$process [$currentdate] enabled agent" >> "$stdout_loc"
				if ! launchctl load "$agent_loc" &>/dev/null ; then
					echo "$process [$currentdate] error loading agent" >> "$stderr_loc"
				else
					echo "$process [$currentdate] reloaded agent" >> "$stdout_loc"
				fi
			fi
		fi
	fi
	exit
fi

# chimes on/off & quiet mode
if [[ $1 == "chimes" ]] ; then
	currentdate=$(date)
	if [[ $2 == "enable" ]] ; then
		if defaults write "$prefs" enabled -bool true &>/dev/null ; then
			echo "$process [$currentdate] chimes enabled" >> "$stdout_loc"
		else
			echo "$process [$currentdate] error enabling chimes" >> "$stderr_loc"
		fi
	elif [[ $2 == "disable" ]] ; then
		if defaults write "$prefs" enabled -bool false &>/dev/null ; then
			echo "$process [$currentdate] chimes disabled" >> "$stdout_loc"
		else
			echo "$process [$currentdate] error disabling chimes" >> "$stderr_loc"
		fi
	elif [[ $2 == "quietmode" ]] ; then
		if [[ $3 == "on" ]] ; then
			if defaults write "$prefs" Notifications -bool true &>/dev/null ; then
				echo "$process [$currentdate] quiet mode enabled" >> "$stdout_loc"
			else	
				echo "$process [$currentdate] error enabling quiet mode" >> "$stderr_loc"
			fi
		elif [[ $3 == "off" ]] ; then
			if defaults write "$prefs" Notifications -bool false &>/dev/null ; then
				echo "$process [$currentdate] quiet mode disabled" >> "$stdout_loc"
			else
				echo "$process [$currentdate] error disabling quiet mode" >> "$stderr_loc"
			fi
		fi
	fi
	exit
fi

# skip for coreaudiod
if [[ $1 == "skip-audio" ]] ; then
	currentdate=$(date)
	if [[ $2 == "on" ]] ; then
		if defaults write "$prefs" skipAudio -bool true &>/dev/null ; then
			echo "$process [$currentdate] skipAudio enabled" >> "$stdout_loc"
		else
			echo "$process [$currentdate] error enabling skipAudio" >> "$stderr_loc"
		fi
	elif [[ $2 == "off" ]] ; then
		if defaults write "$prefs" skipAudio -bool false &>/dev/null ; then
			echo "$process [$currentdate] skipAudio disabled" >> "$stdout_loc"
		else
			echo "$process [$currentdate] error disabling skipAudio" >> "$stderr_loc"
		fi
	fi
	exit
fi

# change sound
if [[ $1 == "selectsound" ]] ; then
	shift
	newsound="$*"
	currentdate=$(date)
	if /usr/libexec/PlistBuddy -c "Set:Sound '$newsound'" "$prefsloc" 2>/dev/null ; then
		echo "$process [$currentdate] set new chime to '$newsound'" >> "$stdout_loc"
	else
		echo "$process [$currentdate] error setting chime to '$newsound'" >> "$stderr_loc"
	fi
	exit
fi

# change volume
if [[ $1 == "changevolume" ]] ; then
	shift
	currentvol="$*"
	volinput=$(osascript 2>/dev/null << EOV
tell application "System Events"
	activate
	set theLogoPath to POSIX file "$icon_loc"
	set theNewVolume to text returned of (display dialog "Enter the new playback volume." & return & return & "Available range: 0.01 (1%) – 1.00 (100%)" ¬
		default answer "$currentvol" ¬
		buttons {"Cancel", "Set"} ¬
		default button 2 ¬
		cancel button "Cancel" ¬
		with title "$uiprocess: Set Volume" ¬
		with icon file theLogoPath ¬
		giving up after 180)
end tell
EOV
	)
	currentdate=$(date)
	if [[ $volinput ]] ; then
		if [[ $volinput != "$currentvol" ]] ; then
			# volume=$()
			! echo "$volinput > 1.00" | bc -l &>/dev/null && volinput=1.00
			! echo "$volinput < 0.01" | bc -l &>/dev/null && volinput=0.01	
			if [[ $volinput != "$currentvol" ]] ; then
				if /usr/libexec/PlistBuddy -c "Set:Volume '$volinput'" "$prefsloc" &>/dev/null ; then
					echo "$process [$currentdate] volume changed to $volinput" >> "$stdout_loc"
				else
					echo "$process [$currentdate] unable to change volume" >> "$stderr_loc"
				fi
			else
				echo "$process [$currentdate] volume unchanged ($currentvol)" >> "$stderr_loc"
			fi
		else
			echo "$process [$currentdate] volume unchanged ($currentvol)" >> "$stderr_loc"
		fi
	else
		echo "$process [$currentdate] volume unchanged ($currentvol)" >> "$stderr_loc"
	fi
	exit
fi

# change playback rate
if [[ $1 == "changerate" ]] ; then
	shift
	currentrate="$*"
	rateinput=$(osascript 2>/dev/null << EOR
tell application "System Events"
	activate
	set theLogoPath to POSIX file "$icon_loc"
	set theNewRate to text returned of (display dialog "Enter the new audio playback rate." & return & return & "Available range: 0.33 (slower) – 3.00 (faster)" ¬
		default answer "$currentrate" ¬
		buttons {"Cancel", "Set"} ¬
		default button 2 ¬
		cancel button "Cancel" ¬
		with title "$uiprocess: Set Playback Rate" ¬
		with icon file theLogoPath ¬
		giving up after 180)
end tell
EOR
	)
	currentdate=$(date)
	if [[ $rateinput ]] ; then
		if [[ $rateinput != "$currentrate" ]] ; then
			! echo "$rateinput > 3.00" | bc -l &>/dev/null && rateinput=3.00
			! echo "$rateinput < 0.33" | bc -l &>/dev/null && rateinput=0.33	
			if [[ $rateinput != "$currentrate" ]] ; then
				if /usr/libexec/PlistBuddy -c "Set:PlaybackRate '$rateinput'" "$prefsloc" &>/dev/null ; then
					echo "$process [$currentdate] playback rate changed to $rateinput" >> "$stdout_loc"
				else
					echo "$process [$currentdate] unable to change playback rate" >> "$stderr_loc"
				fi
			else
				echo "$process [$currentdate] volume unchanged ($currentrate)" >> "$stderr_loc"
			fi
		else
			echo "$process [$currentdate] playback rate unchanged ($currentrate)" >> "$stderr_loc"
		fi
	else
		echo "$process [$currentdate] playback rate unchanged ($currentrate)" >> "$stderr_loc"
	fi
	exit
fi

# drop sound files
if [[ $1 = "-filenames" ]] ; then
	shift
	for selected_sound in "$@"
	do
		ssbase=$(basename "$selected_sound")
		suffix="${ssbase##*.}"
		currentdate=$(date)
		if [[ $suffix =~ ^(mp3|MP3|wav|WAV|caf|CAF|aif|AIF|aiff|AIFF|m4a|M4A|flac|FLAC|bwf|BWF|aifc|AIFC|ac3|AC3|mp4|MP4|m4r|M4R|aac|AAC|3gp|3GP|3g2|3G2|adts|ADTS|amr|AMR|m4b|M4B|ec3|EC3|mp1|MP1|mp2|MP2|mpeg|MPEG|mpa|MPA|snd|SND|au|AU|sd2|SD2)$ ]] ; then
			if [[ -f "$soundsdir/$ssbase" ]] ; then
				echo "$process [$currentdate] '$ssbase' already exists at destination" >> "$stderr_loc"
				continue
			fi
			if ! afinfo "$selected_sound" &>/dev/null ; then
				echo "$process [$currentdate] unknown format/encoding '$ssbase'" >> "$stderr_loc"
				continue
			fi
			if ! cp "$selected_sound" "$soundsdir/$ssbase" ; then
				echo "$process [$currentdate] error copying '$ssbase'" >> "$stderr_loc"
			else
				echo "$process [$currentdate] imported '$ssbase'" >> "$stdout_loc"
			fi
		else
			echo "$process [$currentdate] wrong format ('$suffix')" >> "$stderr_loc"
		fi
	done
	exit
fi

# add/import sound(s)
if [[ $1 == "addsound" ]] ; then
	selectfolder=$(/usr/libexec/PlistBuddy -c "Print:SearchDir" "$prefsloc" 2>/dev/null)
	! [[ $selectfolder ]] && selectfolder="$defselectfolder"
	soundselection=$(osascript 2>/dev/null << EOS
tell application "System Events"
	activate
	set theSearchDir to "$selectfolder" as string
	set theSoundFiles to choose file with prompt "Select one or more sound files for import…" default location theSearchDir of type {"mp3", "MP3", "wav", "WAV", "caf", "CAF", "aif", "AIF", "aiff", "AIFF", "m4a", "M4A", "flac", "FLAC", "bwf", "BWF", "aifc", "AIFC", "ac3", "AC3", "mp4", "MP4", "m4r", "M4R", "aac", "AAC", "3gp", "3GP", "3g2", "3G2", "adts", "ADTS", "amr", "AMR", "m4b", "M4B", "ec3", "EC3", "mp1", "MP1", "mp2", "MP2", "mpeg", "MPEG", "mpa", "MPA", "snd", "SND", "au", "AU", "sd2", "SD2"} with invisibles, multiple selections allowed and showing package contents
	repeat with aSoundFile in theSoundFiles
		set contents of aSoundFile to POSIX path of (contents of aSoundFile)
	end repeat
	set AppleScript's text item delimiters to linefeed
	theSoundFiles as text
end tell
EOS
	)
	currentdate=$(date)
	if ! [[ $soundselection ]] ; then
		echo "$process [$currentdate] user canceled selection" >> "$stderr_loc"
		exit
	fi
	while read -r selected_sound
	do
		ssbase=$(basename "$selected_sound")
		if [[ -f "$soundsdir/$ssbase" ]] ; then
			echo "$process [$currentdate] '$ssbase' already exists at destination" >> "$stderr_loc"
			continue
		fi
		if ! afinfo "$selected_sound" &>/dev/null ; then
			echo "$process [$currentdate] unknown format/encoding '$ssbase'" >> "$stderr_loc"
			continue
		fi
		if ! cp "$selected_sound" "$soundsdir/$ssbase" ; then
			echo "$process [$currentdate] error copying '$ssbase'" >> "$stderr_loc"
		else
			echo "$process [$currentdate] imported '$ssbase'" >> "$stdout_loc"
		fi
	done < <(echo "$soundselection" | grep -v "^$")
	seltop=$(echo "$soundselection" | head -1)
	seltop_parent=$(dirname "$seltop")
	if [[ $seltop_parent != "$selectfolder" ]] ; then
		/usr/libexec/PlistBuddy -c "Set:SearchDir '$seltop_parent'" "$prefsloc" 2>/dev/null
	fi
	exit
fi

# trash sound
if [[ $1 == "trash" ]] ; then
	shift
	currentdate=$(date)
	if ! mv "$soundsdir/$*" "$HOMEDIR/.Trash/$*" &>/dev/null ; then
		echo "$process [$currentdate] error trashing '$*'" >> "$stderr_loc"
	else
		echo "$process [$currentdate] trashed '$*'" >> "$stdout_loc"
	fi
	exit
fi

# application blacklist
if [[ $1 == "blacklist" ]] ; then
	if [[ $2 == "add" ]] ; then
		appfolder=$(/usr/libexec/PlistBuddy -c "Print:AppsDir" "$prefsloc" 2>/dev/null)
		! [[ $appfolder ]] && appfolder="/Applications"
		appselection=$(osascript 2>/dev/null << EOS
tell application "System Events"
	activate
	set theAppsDir to "$appfolder" as string
	set theApps to choose file with prompt "Select one or more applications to blacklist…" default location theAppsDir of type {"app"} with invisibles and multiple selections allowed
	repeat with anApp in theApps
		set contents of anApp to POSIX path of (contents of anApp)
	end repeat
	set AppleScript's text item delimiters to linefeed
	theApps as text
end tell
EOS
		)
		! [[ $appselection ]] && exit
		currentdate=$(date)
		while read -r selectedapp
		do
			appbase=$(basename "$selectedapp")
			bundleid=$(defaults read "$selectedapp"/Contents/Info.plist CFBundleIdentifier 2>/dev/null)
			if ! [[ $bundleid ]] ; then
				echo "$process [$currentdate] error getting BundleID ('$appbase')" >> "$stderr_loc"
				continue
			fi
			bundlename=$(defaults read "$selectedapp"/Contents/Info.plist CFBundleDisplayName 2>/dev/null)
			if ! [[ $bundlename ]] ; then
				bundlename=$(defaults read "$selectedapp"/Contents/Info.plist CFBundleName 2>/dev/null)
				if ! [[ $bundlename ]] ; then
					bundlename="$appbase"
				fi
			fi
			if echo -ne "$bundleid;$bundlename\n" >> "$blacklist_loc" ; then
				echo "$process [$currentdate] blacklisted '$bundleid'" >> "$stdout_loc"
			else
				echo "$process [$currentdate] error blacklisting '$bundleid'" >> "$stderr_loc"
			fi
		done < <(echo "$appselection")
	elif [[ $2 == "remove" ]] ; then
		shift
		shift
		removeid="$*"
		currentblacklist=$(cat "$blacklist_loc" 2>/dev/null)
		newblacklist=$(echo "$currentblacklist" | grep -v "^$removeid;")
		currentdate=$(date)
		if echo "$newblacklist" > "$blacklist_loc" &>/dev/null ; then
			echo "$process [$currentdate] blacklist updated (removed '$removeid')" >> "$stdout_loc"
		else
			echo "$process [$currentdate] error removing '$removeid' from blacklist" >> "$stderr_loc"
		fi
	elif [[ $2 == "disable" ]] ; then
		defaults write "$prefs" skipApps -bool false 2>/dev/null
	elif [[ $2 == "enable" ]] ; then
		defaults write "$prefs" skipApps -bool true 2>/dev/null
	fi
	exit
fi

# check for cck & auxiliary files
[[ -f "$cck_loc" ]] && cckexists=true || cckexists=false
if $cckexists ; then
	cckversion=$("$cck_loc" --version 2>/dev/null)
	if ! [[ $cckversion ]] ; then
		needsreinstall=true
	else
		if ! echo "$cckversion < $version" | bc -l &>/dev/null ; then
			needsreinstall=true
		else
			needsreinstall=false
		fi
	fi
fi
if ! [[ -f "$agent_loc" ]] ; then
	if ! [[ -f "$disable_loc" ]] ; then
		agentexists=false
		agentdisabled=false
		needsreinstall=true
	else
		agentexists=true
		agentdisabled=true
	fi
else
	agentdisabled=false
	if launchctl list 2>/dev/null | grep -q "local.lcars.cck$" &>/dev/null ; then
		agentloaded=true
	else
		agentloaded=false
	fi
fi
[[ -f "$prefsloc" ]] && prefsexist=true || prefsexist=false
[[ -d "$configdir" ]] && configexists=true || configexists=false
[[ -d "$soundsdir" ]] && soundsexist=true || soundsexist=false
[[ -f "$soundsdir/$defaultsound" ]] && defsoundexists=true || defsoundexists=true
if [[ $(/usr/libexec/PlistBuddy -c "Print:enabled" "$prefsloc" 2>/dev/null) != "true" ]] ; then
	cckoff=true
else
	cckoff=false
fi
if [[ $(/usr/libexec/PlistBuddy -c "Print:Notifications" "$prefsloc" 2>/dev/null) != "false" ]] ; then
	cckquiet=true
else
	cckquiet=false
fi

cckinstalled=true
if ! $prefsexist || ! $configexists || ! $soundsexist || ! $defsoundexists ; then
	cckinstalled=false
fi
if ! $cckinstalled || ! $agentloaded || $agentdisabled || $cckoff || $cckquiet ; then
	dormanticon=true
else
	dormanticon=false
fi

menuicon_gray="iVBORw0KGgoAAAANSUhEUgAAACQAAAAkCAQAAABLCVATAAAACXBIWXMAABYlAAAWJQFJUiTwAAAJ6mlUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4gPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iQWRvYmUgWE1QIENvcmUgNi4wLWMwMDIgNzkuMTY0NDYwLCAyMDIwLzA1LzEyLTE2OjA0OjE3ICAgICAgICAiPiA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPiA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIiB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iIHhtbG5zOmRjPSJodHRwOi8vcHVybC5vcmcvZGMvZWxlbWVudHMvMS4xLyIgeG1sbnM6cGhvdG9zaG9wPSJodHRwOi8vbnMuYWRvYmUuY29tL3Bob3Rvc2hvcC8xLjAvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RFdnQ9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZUV2ZW50IyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIDIxLjIgKE1hY2ludG9zaCkiIHhtcDpDcmVhdGVEYXRlPSIyMDIwLTA3LTIzVDAwOjMyOjQ1KzAyOjAwIiB4bXA6TW9kaWZ5RGF0ZT0iMjAyMC0wNy0yM1QwMTowODoyOCswMjowMCIgeG1wOk1ldGFkYXRhRGF0ZT0iMjAyMC0wNy0yM1QwMTowODoyOCswMjowMCIgZGM6Zm9ybWF0PSJpbWFnZS9wbmciIHBob3Rvc2hvcDpDb2xvck1vZGU9IjEiIHBob3Rvc2hvcDpJQ0NQcm9maWxlPSJEb3QgR2FpbiAyMCUiIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6MzQ1NTBmNGQtMTRjNi00YjA4LTkyMzQtNjJmZjE4YTFhMzRkIiB4bXBNTTpEb2N1bWVudElEPSJhZG9iZTpkb2NpZDpwaG90b3Nob3A6ZjA1YTZhNTQtMGRmYy1lMTQ1LTgxMzItZTAzOTZiZDM5MTU4IiB4bXBNTTpPcmlnaW5hbERvY3VtZW50SUQ9InhtcC5kaWQ6ZWRjNzllZDYtNzkyNC00ZmE5LTk5NzMtZTA4ODhhZDJkMGViIj4gPHhtcE1NOkhpc3Rvcnk+IDxyZGY6U2VxPiA8cmRmOmxpIHN0RXZ0OmFjdGlvbj0iY3JlYXRlZCIgc3RFdnQ6aW5zdGFuY2VJRD0ieG1wLmlpZDplZGM3OWVkNi03OTI0LTRmYTktOTk3My1lMDg4OGFkMmQwZWIiIHN0RXZ0OndoZW49IjIwMjAtMDctMjNUMDA6MzI6NDUrMDI6MDAiIHN0RXZ0OnNvZnR3YXJlQWdlbnQ9IkFkb2JlIFBob3Rvc2hvcCAyMS4yIChNYWNpbnRvc2gpIi8+IDxyZGY6bGkgc3RFdnQ6YWN0aW9uPSJjb252ZXJ0ZWQiIHN0RXZ0OnBhcmFtZXRlcnM9ImZyb20gaW1hZ2UvcG5nIHRvIGFwcGxpY2F0aW9uL3ZuZC5hZG9iZS5waG90b3Nob3AiLz4gPHJkZjpsaSBzdEV2dDphY3Rpb249InNhdmVkIiBzdEV2dDppbnN0YW5jZUlEPSJ4bXAuaWlkOmVmNDZjNzlhLTcxMjItNDRjYi04YWM2LTAwYWRmZjA2NmZmOCIgc3RFdnQ6d2hlbj0iMjAyMC0wNy0yM1QwMDo1OTo1NiswMjowMCIgc3RFdnQ6c29mdHdhcmVBZ2VudD0iQWRvYmUgUGhvdG9zaG9wIDIxLjIgKE1hY2ludG9zaCkiIHN0RXZ0OmNoYW5nZWQ9Ii8iLz4gPHJkZjpsaSBzdEV2dDphY3Rpb249InNhdmVkIiBzdEV2dDppbnN0YW5jZUlEPSJ4bXAuaWlkOjZkYWY4ZGEzLWU5MmYtNGQxZC04ZGRlLTQzMDA3ZGZkNjY5MyIgc3RFdnQ6d2hlbj0iMjAyMC0wNy0yM1QwMTowODoyOCswMjowMCIgc3RFdnQ6c29mdHdhcmVBZ2VudD0iQWRvYmUgUGhvdG9zaG9wIDIxLjIgKE1hY2ludG9zaCkiIHN0RXZ0OmNoYW5nZWQ9Ii8iLz4gPHJkZjpsaSBzdEV2dDphY3Rpb249ImNvbnZlcnRlZCIgc3RFdnQ6cGFyYW1ldGVycz0iZnJvbSBhcHBsaWNhdGlvbi92bmQuYWRvYmUucGhvdG9zaG9wIHRvIGltYWdlL3BuZyIvPiA8cmRmOmxpIHN0RXZ0OmFjdGlvbj0iZGVyaXZlZCIgc3RFdnQ6cGFyYW1ldGVycz0iY29udmVydGVkIGZyb20gYXBwbGljYXRpb24vdm5kLmFkb2JlLnBob3Rvc2hvcCB0byBpbWFnZS9wbmciLz4gPHJkZjpsaSBzdEV2dDphY3Rpb249InNhdmVkIiBzdEV2dDppbnN0YW5jZUlEPSJ4bXAuaWlkOjM0NTUwZjRkLTE0YzYtNGIwOC05MjM0LTYyZmYxOGExYTM0ZCIgc3RFdnQ6d2hlbj0iMjAyMC0wNy0yM1QwMTowODoyOCswMjowMCIgc3RFdnQ6c29mdHdhcmVBZ2VudD0iQWRvYmUgUGhvdG9zaG9wIDIxLjIgKE1hY2ludG9zaCkiIHN0RXZ0OmNoYW5nZWQ9Ii8iLz4gPC9yZGY6U2VxPiA8L3htcE1NOkhpc3Rvcnk+IDx4bXBNTTpEZXJpdmVkRnJvbSBzdFJlZjppbnN0YW5jZUlEPSJ4bXAuaWlkOjZkYWY4ZGEzLWU5MmYtNGQxZC04ZGRlLTQzMDA3ZGZkNjY5MyIgc3RSZWY6ZG9jdW1lbnRJRD0ieG1wLmRpZDplZGM3OWVkNi03OTI0LTRmYTktOTk3My1lMDg4OGFkMmQwZWIiIHN0UmVmOm9yaWdpbmFsRG9jdW1lbnRJRD0ieG1wLmRpZDplZGM3OWVkNi03OTI0LTRmYTktOTk3My1lMDg4OGFkMmQwZWIiLz4gPC9yZGY6RGVzY3JpcHRpb24+IDwvcmRmOlJERj4gPC94OnhtcG1ldGE+IDw/eHBhY2tldCBlbmQ9InIiPz7uadyPAAAA4ElEQVRIib2WSxKEIAxEwfLguTkulMF8uoNTaG9mlOTZJIDWVtZozwKqnL9NkjjmqEO6GAyCBqSJvZoGxWkc5kBJOBxVIOwkd/YDZdPJYKb9CGKd6QYoRz4JgeO+BSBSUDjiQL4m2geqWSlbZFMnNhkVwWsbgPzzM5QBobDTFYuEU3sqd4w0idaPj7J3gKOoHlHdKOiePv7Hd4fgCVmv8uok5AdMDU2CLQB6Zt+3KfZyjedHrdbkgvxf9C3yRMscEVAVu2lZwd/ba1j8pf1917KPifdrNPs50/V91zJnyxwddBpxuHWzTBsAAAAASUVORK5CYII="

# wrong BitBar version
if ! $correctbb ; then
	echo "| templateImage=$menuicon_gray dropdown=false"
	echo "---"
	echo "$uiprocess ($process)"
	echo "v$version$vmisc build $build | alternate=true"
	echo "---"
	echo "🛑 Update to BitBar v2.0.0 beta 10… | color=red refresh=false href=\"$bbdlurl\""
	echo "---"
	echo "Refresh… | refresh=true terminal=false bash=$0"
	exit
fi

# initial run: install cck and all files
if ! $cckinstalled ; then
	echo "| templateImage=$menuicon_gray dropdown=false"
	echo "---"
	echo "$uiprocess ($process)"
	echo "v$version$vmisc build $build | alternate=true"
	echo "---"
	echo "⚠️ Install Cuckoo Menu… | color=red refresh=true terminal=false bash=$0 param1=cckinstall"
	echo "⚠️ Re-download… | alternate=true color=red refresh=false href=\"$cckmdlurl\""
	echo "---"
	echo "Refresh… | refresh=true terminal=false bash=$0"
	exit
fi

# reinstall cck CLI
if $needsreinstall ; then
	echo "| templateImage=$menuicon_gray dropdown=false"
	echo "---"
	echo "$uiprocess ($process)"
	echo "v$version$vmisc build $build | alternate=true"
	echo "---"
	echo "⚠️ Install New Agent… | color=orange refresh=true terminal=false bash=$0 param1=cckreinstall"
	echo "⚠️ Re-download… | alternate=true color=orange refresh=false href=\"$cckmdlurl\""
	echo "---"
	echo "Refresh… | refresh=true terminal=false bash=$0"
	exit
fi
menuicon="iVBORw0KGgoAAAANSUhEUgAAACQAAAAkCAQAAABLCVATAAAACXBIWXMAABYlAAAWJQFJUiTwAAAJ6mlUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4gPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iQWRvYmUgWE1QIENvcmUgNi4wLWMwMDIgNzkuMTY0NDYwLCAyMDIwLzA1LzEyLTE2OjA0OjE3ICAgICAgICAiPiA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPiA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIiB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iIHhtbG5zOmRjPSJodHRwOi8vcHVybC5vcmcvZGMvZWxlbWVudHMvMS4xLyIgeG1sbnM6cGhvdG9zaG9wPSJodHRwOi8vbnMuYWRvYmUuY29tL3Bob3Rvc2hvcC8xLjAvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RFdnQ9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZUV2ZW50IyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIDIxLjIgKE1hY2ludG9zaCkiIHhtcDpDcmVhdGVEYXRlPSIyMDIwLTA3LTIzVDAwOjMyOjQ1KzAyOjAwIiB4bXA6TW9kaWZ5RGF0ZT0iMjAyMC0wNy0yM1QwMTowNzoyMiswMjowMCIgeG1wOk1ldGFkYXRhRGF0ZT0iMjAyMC0wNy0yM1QwMTowNzoyMiswMjowMCIgZGM6Zm9ybWF0PSJpbWFnZS9wbmciIHBob3Rvc2hvcDpDb2xvck1vZGU9IjEiIHBob3Rvc2hvcDpJQ0NQcm9maWxlPSJEb3QgR2FpbiAyMCUiIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6NWE2ZTAxZDItNGJjYS00N2QxLTk0NTQtOTI4OTAyNWE4M2Q4IiB4bXBNTTpEb2N1bWVudElEPSJhZG9iZTpkb2NpZDpwaG90b3Nob3A6OWY5Yjc1MTctMDZmMC1iZjQyLWExOWEtYzRkZDBkYTQ0YjdiIiB4bXBNTTpPcmlnaW5hbERvY3VtZW50SUQ9InhtcC5kaWQ6ZWRjNzllZDYtNzkyNC00ZmE5LTk5NzMtZTA4ODhhZDJkMGViIj4gPHhtcE1NOkhpc3Rvcnk+IDxyZGY6U2VxPiA8cmRmOmxpIHN0RXZ0OmFjdGlvbj0iY3JlYXRlZCIgc3RFdnQ6aW5zdGFuY2VJRD0ieG1wLmlpZDplZGM3OWVkNi03OTI0LTRmYTktOTk3My1lMDg4OGFkMmQwZWIiIHN0RXZ0OndoZW49IjIwMjAtMDctMjNUMDA6MzI6NDUrMDI6MDAiIHN0RXZ0OnNvZnR3YXJlQWdlbnQ9IkFkb2JlIFBob3Rvc2hvcCAyMS4yIChNYWNpbnRvc2gpIi8+IDxyZGY6bGkgc3RFdnQ6YWN0aW9uPSJjb252ZXJ0ZWQiIHN0RXZ0OnBhcmFtZXRlcnM9ImZyb20gaW1hZ2UvcG5nIHRvIGFwcGxpY2F0aW9uL3ZuZC5hZG9iZS5waG90b3Nob3AiLz4gPHJkZjpsaSBzdEV2dDphY3Rpb249InNhdmVkIiBzdEV2dDppbnN0YW5jZUlEPSJ4bXAuaWlkOmVmNDZjNzlhLTcxMjItNDRjYi04YWM2LTAwYWRmZjA2NmZmOCIgc3RFdnQ6d2hlbj0iMjAyMC0wNy0yM1QwMDo1OTo1NiswMjowMCIgc3RFdnQ6c29mdHdhcmVBZ2VudD0iQWRvYmUgUGhvdG9zaG9wIDIxLjIgKE1hY2ludG9zaCkiIHN0RXZ0OmNoYW5nZWQ9Ii8iLz4gPHJkZjpsaSBzdEV2dDphY3Rpb249InNhdmVkIiBzdEV2dDppbnN0YW5jZUlEPSJ4bXAuaWlkOjljMjg5ZGFiLTM0MTQtNGUzNy04OTM1LTA5YmViMTA1ZDk3MSIgc3RFdnQ6d2hlbj0iMjAyMC0wNy0yM1QwMTowNzoyMiswMjowMCIgc3RFdnQ6c29mdHdhcmVBZ2VudD0iQWRvYmUgUGhvdG9zaG9wIDIxLjIgKE1hY2ludG9zaCkiIHN0RXZ0OmNoYW5nZWQ9Ii8iLz4gPHJkZjpsaSBzdEV2dDphY3Rpb249ImNvbnZlcnRlZCIgc3RFdnQ6cGFyYW1ldGVycz0iZnJvbSBhcHBsaWNhdGlvbi92bmQuYWRvYmUucGhvdG9zaG9wIHRvIGltYWdlL3BuZyIvPiA8cmRmOmxpIHN0RXZ0OmFjdGlvbj0iZGVyaXZlZCIgc3RFdnQ6cGFyYW1ldGVycz0iY29udmVydGVkIGZyb20gYXBwbGljYXRpb24vdm5kLmFkb2JlLnBob3Rvc2hvcCB0byBpbWFnZS9wbmciLz4gPHJkZjpsaSBzdEV2dDphY3Rpb249InNhdmVkIiBzdEV2dDppbnN0YW5jZUlEPSJ4bXAuaWlkOjVhNmUwMWQyLTRiY2EtNDdkMS05NDU0LTkyODkwMjVhODNkOCIgc3RFdnQ6d2hlbj0iMjAyMC0wNy0yM1QwMTowNzoyMiswMjowMCIgc3RFdnQ6c29mdHdhcmVBZ2VudD0iQWRvYmUgUGhvdG9zaG9wIDIxLjIgKE1hY2ludG9zaCkiIHN0RXZ0OmNoYW5nZWQ9Ii8iLz4gPC9yZGY6U2VxPiA8L3htcE1NOkhpc3Rvcnk+IDx4bXBNTTpEZXJpdmVkRnJvbSBzdFJlZjppbnN0YW5jZUlEPSJ4bXAuaWlkOjljMjg5ZGFiLTM0MTQtNGUzNy04OTM1LTA5YmViMTA1ZDk3MSIgc3RSZWY6ZG9jdW1lbnRJRD0ieG1wLmRpZDplZGM3OWVkNi03OTI0LTRmYTktOTk3My1lMDg4OGFkMmQwZWIiIHN0UmVmOm9yaWdpbmFsRG9jdW1lbnRJRD0ieG1wLmRpZDplZGM3OWVkNi03OTI0LTRmYTktOTk3My1lMDg4OGFkMmQwZWIiLz4gPC9yZGY6RGVzY3JpcHRpb24+IDwvcmRmOlJERj4gPC94OnhtcG1ldGE+IDw/eHBhY2tldCBlbmQ9InIiPz5GBQhDAAAA20lEQVRIib2WQRbDIAhEpa/3vzJdpK0RZgbaZ8IqEfyOoCTmY489qwB7r+TWi2s5FYyCpsMtvrVBeJqGJVA3PHoXEFdSK/uOVtupYKH8DBKVrQVA0WEYgXHdAKiT0AwLoJyTVQfL2RgPJHOd6DYzws82AeX1K1QAsbBDlYqkW/vVUhtxQ+cnR8URogjlA+VNgs7T5zMenUY7pPkRvk7ifRBujW1CHQDZs8/XVPZk5WeO5oH83yrFbdumSIDM46VV8q+7a9z0R/v+qlU/E9fnqPs787H7q1Yp26boBWXDbj8VA962AAAAAElFTkSuQmCC"

stdoutlog=$(tail -r -20 "$stdout_loc" 2>/dev/null)
stderrlog=$(tail -r -20 "$stderr_loc" 2>/dev/null)

posixdate=$(date +%s)
if $prefsexist ; then
	lastcheck=$(/usr/libexec/PlistBuddy -c "Print:lastUpdateCheck" "$prefsloc" 2>/dev/null)
	if ! [[ $lastcheck ]] ; then
		defaults write "$prefs" lastUpdateCheck "$posixdate" 2>/dev/null
		lastcheck="$posixdate"
	fi
	available=$(/usr/libexec/PlistBuddy -c "Print:available" "$prefsloc" 2>/dev/null)
	if echo "$available" | grep -q "[0-9]$" &>/dev/null ; then
		savedupdate=true
	else
		savedupdate=false
	fi
	allsounds=$(find "$soundsdir" -maxdepth 1 -mindepth 1 -type f -exec basename {} \; 2>/dev/null)
	ccksound_raw=$(/usr/libexec/PlistBuddy -c "Print:Sound" "$prefsloc" 2>/dev/null)
	soundsource="cck"
	if ! [[ $ccksound_raw ]] ; then
		ccksound="$defaultsound"
		ccksound_raw="$defaultsound"
	else
		ccksound=$(echo "$ccksound_raw" | awk -F":" '{print substr($0, index($0,$2))}')
		if [[ $ccksound_raw == "user:"* ]] ; then
			if ! [[ -f "$usersoundsdir/$ccksound" ]] ; then
				ccksound="$defaultsound"
				ccksound_raw="$defaultsound"
			else
				soundsource="user"
			fi
		elif [[ $ccksound_raw == "system:"* ]] ; then
			if ! [[ -f "$systemsoundsdir/$ccksound" ]] ; then
				ccksound="$defaultsound"
				ccksound_raw="$defaultsound"
			else
				soundsource="system"
			fi
		elif [[ $ccksound_raw == "core:"* ]] ; then
			ccksoundsubpath=$(echo "$ccksound_raw" | awk -F":" '{print substr($0, index($0,$2))}')
			ccksoundfullpath="$coresoundsdir/$ccksoundsubpath"
			if ! [[ -f "$ccksoundfullpath" ]] ; then
				ccksound="$defaultsound"
				ccksound_raw="$defaultsound"
			else
				ccksound=$(basename "$ccksoundfullpath")
				ccksoundparent_raw=$(dirname "$ccksoundfullpath")
				ccksoundparent=$(basename "$ccksoundparent_raw")
				soundsource="core"
			fi
		else
			! [[ -f "$soundsdir/$ccksound" ]] && ccksound="$defaultsound"
		fi
	fi
	volume=$(/usr/libexec/PlistBuddy -c "Print:Volume" "$prefsloc" 2>/dev/null)
	! [[ $volume ]] && volume="0.10"
	! echo "$volume > 1.00" | bc -l &>/dev/null && volume=1.00
	! echo "$volume < 0.01" | bc -l &>/dev/null && volume=0.01
	audiorate=$(/usr/libexec/PlistBuddy -c "Print:PlaybackRate" "$prefsloc" 2>/dev/null)
	! [[ $audiorate ]] && audiorate="1.00"
	if ! echo "$audiorate > 3.00" | bc -l &>/dev/null ; then
		audiorate="3.00"
	else
		if ! echo "$audiorate < 0.33" | bc -l &>/dev/null ; then
			audiorate="0.33"
		fi
	fi
	[[ $(/usr/libexec/PlistBuddy -c "Print:skipApps" "$prefsloc" 2>/dev/null) == "true" ]] && blacklistenabled=true || blacklistenabled=false
	[[ $(/usr/libexec/PlistBuddy -c "Print:skipAudio" "$prefsloc" 2>/dev/null) == "true" ]] && skipaudio=true || skipaudio=false
	[[ $(/usr/libexec/PlistBuddy -c "Print:skipScreensaver" "$prefsloc" 2>/dev/null) == "true" ]] && skipsaver=true || skipsaver=false
	[[ $(/usr/libexec/PlistBuddy -c "Print:skipScreenSleep" "$prefsloc" 2>/dev/null) == "true" ]] && skipsleep=true || skipsleep=false
	[[ $(/usr/libexec/PlistBuddy -c "Print:tollHour" "$prefsloc" 2>/dev/null) == "true" ]] && tollhour=true || tollhour=false
	[[ $(/usr/libexec/PlistBuddy -c "Print:tollQuarterHour" "$prefsloc" 2>/dev/null) == "true" ]] && tollquarter=true || tollquarter=false
	[[ $(/usr/libexec/PlistBuddy -c "Print:fourStrikes" "$prefsloc" 2>/dev/null) == "true" ]] && fourstrikes=true || fourstrikes=false
	finalhour=$(/usr/libexec/PlistBuddy -c "Print:notAfter" "$prefsloc" 2>/dev/null)
	if ! [[ $finalhour ]] || [[ $finalhour -gt 23 ]] || [[ $finalhour -lt 0 ]] ; then
		defaults write "$prefs" notAfter "23" 2>/dev/null
		finalhour=23
	fi
	finalhourstr="$finalhour:00"
	firsthour=$(/usr/libexec/PlistBuddy -c "Print:notBefore" "$prefsloc" 2>/dev/null)
	if ! [[ $firsthour ]] || [[ $firsthour -lt 0 ]] || [[ $firsthour -gt 23 ]] ; then
		defaults write "$prefs" notBefore "7" 2>/dev/null
		firsthour="7"
	fi
	firsthourstr="$firsthour:00"
	if $tollhour && $tollquarter ; then
		cckinterval=15
	else
		cckinterval=$(/usr/libexec/PlistBuddy -c "Print:Interval" "$prefsloc" 2>/dev/null)
		if ! [[ $cckinterval ]] ; then
			defaults write "$prefs" Interval "30" 2>/dev/null
			cckinterval="30"
		fi
	fi
	if [[ $(/usr/libexec/PlistBuddy -c "Print:AfterHours" "$prefsloc" 2>/dev/null) == "true" ]] ; then
		afterhours=true
	else
		afterhours=false
	fi
	if [[ $(/usr/libexec/PlistBuddy -c "Print:NightMode" "$prefsloc" 2>/dev/null) == "true" ]] ; then
		nightmode=true
	else
		nightmode=false
	fi
	[[ $(/usr/libexec/PlistBuddy -c "Print:Western" "$prefsloc" 2>/dev/null) == "true" ]] && western=true || western=false
	[[ $(/usr/libexec/PlistBuddy -c "Print:warnBeforeSunrise" "$prefsloc" 2>/dev/null) == "true" ]] && warnsunrise=true || warnsunrise=false
	sunrisewarnhours=$(/usr/libexec/PlistBuddy -c "Print:SunriseWarnHours" "$prefsloc" 2>/dev/null)
	if ! [[ $sunrisewarnhours ]] || [[ $sunrisewarnhours -gt 23 ]] || [[ $sunrisewarnhours -lt 1 ]] ; then
		sunrisewarnhours=4
	fi
	depsmissing=false
	if ! $sshinstalled && ! [[ -f "$ssh_loc" ]] ; then
		depsmissing=true
	fi
	if ! $clcinstalled && ! [[ -f "$clc_loc" ]] ; then
		depsmissing=true
	fi
	if $depsmissing ; then
		currentdate=$(date)
		echo "$process [$currentdate] missing dependency: sunshine" >> "$stderr_loc"
		reqerror=true
		geolocerror=true
		triduum=false
		istriduum=false
		nightmode=false
		permanent=false
		warnsunrise=false
	else
		suncalc=false
		permanent=false
		reqerror=false
		geolocerror=false
		yearday=$(date +%j | sed 's/^0*//')
		thisyear=$(date +%Y)
		if $afterhours && $nightmode ; then
			suncalc=true
		fi
		$warnsunrise && suncalc=true
		if [[ $(/usr/libexec/PlistBuddy -c "Print:silentTriduum" "$prefsloc" 2>/dev/null) == "true" ]] ; then
			triduum=true
			if ! [[ -f "$easterdates_loc" ]] ; then
				eastercalc=true
			else
				if [[ $(head -1 < "$easterdates_loc") == "$thisyear" ]] ; then
					eastercalc=false
				else
					eastercalc=true
				fi
			fi
			if $eastercalc ; then
				if $western ; then
					easter=$(ncal -e)
				else
					easter=$(ncal -o)
				fi
				eastersun=$(date -jf "%B %e %Y" "$easter" +%j | sed 's/^0*//')
				eastersat=$((eastersun-1))
				goodfri=$((eastersat-1))
				maundythu=$((goodfri-1))
				echo -e "$thisyear\n$maundythu;$goodfri;$eastersat;$eastersun;" > "$easterdates_loc" 2>/dev/null
			fi
			if grep -q "$yearday;" < "$easterdates_loc" &>/dev/null ; then
				istriduum=true
				suncalc=true
			else
				istriduum=false
			fi
		else
			triduum=false
			istriduum=false
		fi
		if $suncalc ; then
			if [[ -f $sundata_loc ]] ; then
				sundata=$(cat "$sundata_loc" 2>/dev/null)
				if [[ $sundata ]] ; then
					sundataday=$(echo "$sundata" | head -1 2>/dev/null)
					if [[ $sundataday == "$yearday" ]] ; then
						sunraw=$(echo "$sundata" | grep ":" 2>/dev/null)
						if [[ $sunraw ]] ; then
							suncalc=false
							if [[ $sunraw == "permanent:Night" ]] ; then
								permanent=true
								permstr="Night"
							elif [[ $sunraw == "permanent:Day" ]] ; then
								permanent=true
								permstr="Day"
							else
								sunrise=$(echo "$sunraw" | awk -F":" '{print $1":"$2}')
								sunset=$(echo "$sunraw" | awk -F":" '{print $3":"$4}')
							fi
						fi
					fi
				fi
			fi
		fi
		if $suncalc ; then
			if $sshinstalled ; then
				sunraw=$(sunshine ! --format %H:%M 2>&1)
			else
				sunraw=$("$ssh_loc" ! --format %H:%M 2>&1)
			fi
			if echo "$sunraw" | grep -q "^sunrise:" &>/dev/null ; then
				sunrise=$(echo "$sunraw" | awk -F": " '/^sunrise/{print $2}' | sed 's/^0//' 2>/dev/null)
				sunset=$(echo "$sunraw" | awk -F": " '/^sunset/{print $2}' | sed 's/^0//' 2>/dev/null)
				echo -e "$yearday\n$sunrise:$sunset" > "$sundata_loc" 2>/dev/null
			else
				if echo "$sunraw" | grep -q "invalid or out-of-range datetime" &>/dev/null ; then
					if $clcinstalled ; then
						geoloc=$(CoreLocationCLI 2>/dev/null)
					else
						geoloc=$("$clc_loc" 2>/dev/null)
					fi
					if ! [[ $geoloc ]] ; then
						currentdate=$(date)
						echo "$process [$currentdate] error calculating geolocation" >> "$stderr_loc"
						istriduum=false
						triduum=false
						nightmode=false
						geolocerror=true
						echo -n "" > "$sundata_loc" 2>/dev/null
					else
						equinox1=80
						equinox2=265
						if echo "$geoloc" | grep -q "^-[0-9]" &>/dev/null ; then # southern
							permanent=true
							if [[ $yearday -gt "$equinox1" ]] && [[ $yearday -lt "$equinox2" ]] ; then # e.g. Jul
								permstr="Night" # night in Jul etc.
							else # e.g. Dec
								permstr="Day" # day in Dec etc.
							fi
						elif echo "$geoloc" | grep -q "^[0-9]" &>/dev/null ; then # northern
							permanent=true
							if [[ $yearday -gt "$equinox1" ]] && [[ $yearday -lt "$equinox2" ]] ; then # e.g. Jul
								permstr="Day" # day in Jul etc.
							else # e.g. Dec
								permstr="Night" # night in Dec etc.
							fi
						else
							currentdate=$(date)
							echo "$process [$currentdate] error calculating geolocation" >> "$stderr_loc"
							istriduum=false
							triduum=false
							nightmode=false
							geolocerror=true
						fi
						if $permanent ; then
							echo -n "permanent:$permstr" > "$sundata_loc" 2>/dev/null
						else
							echo -n "" > "$sundata_loc" 2>/dev/null
						fi
					fi
				else
					currentdate=$(date)
					echo "$process [$currentdate] error calculating sunrise & sunset" >> "$stderr_loc"
					istriduum=false
					triduum=false
					nightmode=false
					geolocerror=true
					echo -n "" > "$sundata_loc" 2>/dev/null
				fi
			fi
		else
			sundata=$(cat "$sundata_loc" 2>/dev/null)
			if [[ $sundata ]] ; then
				sundataday=$(echo "$sundata" | head -1 2>/dev/null)
				if [[ $sundataday == "$yearday" ]] ; then
					sunraw=$(echo "$sundata" | grep ":" 2>/dev/null)
					if [[ $sunraw ]] ; then
						suncalc=false
						if [[ $sunraw == "permanent:Night" ]] ; then
							permanent=true
							permstr="Night"
						elif [[ $sunraw == "permanent:Day" ]] ; then
							permanent=true
							permstr="Day"
						fi
					fi
				fi
			fi
		fi
		if $triduum & $istriduum ; then
			if ! $permanent ; then
				finalhourstr="Before Sunset (Maundy Thursday)"
				firsthourstr="After Sunrise (Easter Sunday)"
			else
				finalhourstr="18:00 (Maundy Thursday)"
				firsthourstr="6:00 (Easter Sunday)"
			fi
		else
			if $nightmode ; then
				if ! $permanent ; then
					finalhourstr="Before Sunset ($sunset)"
					firsthourstr="After Sunrise ($sunrise)"
				else
					finalhourstr="Permanent $permstr"
					firsthourstr="Permanent $permstr"
				fi
			fi
		fi
	fi
else
	ccksound="$defaultsound"
	ccksound_raw="$defaultsound"
	soundsource="cck"
	volume="0.10"
	audiorate="1.00"
	blacklistenabled=true
	skipaudio=true
	skipsaver=true
	skipsleep=true
	tollhour=false
	tollquarter=false
	fourstrikes=false
	finalhour="23"
	finalhourstr="23:00"
	firsthour="7"
	firsthourstr="7:00"
	cckinterval="30"
	western=true
	triduum=false
	afterhours=true
	nightmode=false
	currentdate=$(date)
	lastcheck="$posixdate"
	available=""
	savedupdate=false
	sunrisewarnhours="4"
	warnsunrise=false
	echo "$process [$currentdate] error: no Preferences file" >> "$stderr_loc"
fi

# update check
secsdiff=$((posixdate-lastcheck))
if [[ $secsdiff -gt 86400 ]] ; then
	relversion_all=$(curl -kL --connect-timeout 3 "$cckmrelurl" 2>/dev/null)
	currentdate=$(date)
	updateerror=false
	newupdate=false
	updstr=""
	if [[ $relversion_all ]] ; then
		defaults write "$prefs" lastUpdateCheck "$posixdate" 2>/dev/null
		relversion=$(echo "$relversion_all" | head -1)
		if [[ $relversion ]] ; then
			if (( $(echo "$relversion > $cversion" | bc -l) )) ; then
				newupdate=true
				updstr="Version $relversion"
			else
				relbeta=$(echo "$relversion_all" | awk '/^beta/{print $2}' 2>/dev/null)
				if ! [[ $relbeta ]] || [[ $relbeta == "0" ]] ; then
					if ! [[ $relbeta ]] ; then
						echo "$process [$currentdate] update check: failed to fetch beta info" >> "$stderr_loc"
						updateerror=true
					else
						relbuild=$(echo "$relversion_all" | awk '/^build/{print $2}' 2>/dev/null)
						if [[ $relbuild ]] ; then
							if (( $(echo "$relbuild > $build" | bc -l) )) ; then
								newupdate=true
								updstr="Build $relbuild"
							else
								newupdate=false
							fi
						else
							echo "$process [$currentdate] update check: failed to fetch build info" >> "$stderr_loc"
							updateerror=true
						fi
					fi
				else
					if (( $(echo "$relbeta > $betaversion" | bc -l) )) ; then
						newupdate=true
						updstr="Beta $relbeta"
					else
						relbuild=$(echo "$relversion_all" | awk '/^build/{print $2}' 2>/dev/null)
						if [[ $relbuild ]] ; then
							if (( $(echo "$relbuild > $build" | bc -l) )) ; then
								newupdate=true
								updstr="Build $relbuild"
							else
								newupdate=false
							fi
						else
							echo "$process [$currentdate] update check: failed to fetch build info" >> "$stderr_loc"
							updateerror=true
						fi
					fi						
				fi
			fi
		else
			echo "$process [$currentdate] update check: failed to fetch version info" >> "$stderr_loc"
			updateerror=true
		fi
	else
		echo "$process [$currentdate] update check: failed to fetch release info" >> "$stderr_loc"
		updateerror=true
	fi
	if $updateerror ; then
		newupdate=false
	else
		if $newupdate ; then
			defaults write "$prefs" available "$updstr" 2>/dev/null
			echo "$process [$currentdate] update check: new $updstr available" >> "$stdout_loc"
		else
			echo "$process [$currentdate] update check: latest version installed" >> "$stderr_loc"
		fi
	fi
else
	updstr=""
	updateerror=false
	newupdate=false
fi
if $savedupdate ; then
	newupdate=true
	updstr="$available"
fi

if ! [[ -f "$icon_loc" ]] ; then
	read -d '' cckicon <<"EOI"
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
EOI
	echo -n "$cckicon" | base64 -d - -o "$icon_loc" &>/dev/null
fi

$istriduum && dormanticon=true
if $permanent && [[ $permstr == "Night" ]] && $nightmode ; then
	permnm=true
	dormanticon=true
else
	permnm=false
fi

if ! $dormanticon ; then
	if ! $newupdate ; then
		echo "| templateImage=$menuicon dropdown=false"
	else
		echo "🔻 | templateImage=$menuicon dropdown=false"
	fi
else
	echo "| templateImage=$menuicon_gray dropdown=false"
fi

echo "---"

echo "$uiprocess ($process)"
echo "v$version$vmisc build $build | alternate=true terminal=false refresh=false bash=/usr/bin/afplay param1=-v param2=0.1 param3=\"$soundsdir/$defaultsound\""
if $agentdisabled ; then
	echo "⚠️ Status: Agent Disabled"
else
	if ! $agentloaded ; then
		echo "⚠️ Status: Agent Unloaded"
	else
		if $cckoff ; then
			echo "⚠️ Status: Chimes Disabled"
		else
			if $cckquiet ; then
				echo "⚠️ Status: Quiet Mode"
			fi
		fi
		if $newupdate ; then
			echo "⚠️ $updstr Available… | color=red refresh=false href=\"$cckmlatestdlurl\""
		fi
	fi
fi
if $istriduum ; then 
	if $western ; then
		echo "✝️ Triduum Sacrum"
	else
		echo "☦️️ Triduum Sacrum"
	fi
else
	if $permnm ; then
		echo "🌜 Permanent Night Mode"
	fi
fi

echo "---"

_open-sounds () {
	echo "-----"
	if grep Finder &>/dev/null ; then
		echo "--Open Sounds Directory | refresh=false terminal=false bash=/usr/bin/open param1=\"$soundsdir\""
	else
		filemanager=$(defaults read -g NSFileViewer 2>/dev/null)
		if ! [[ $filemanager ]] ; then
			echo "--Open Sounds Directory | refresh=false terminal=false bash=/usr/bin/open param1=\"$soundsdir\""
		else
			echo "--Open Sounds Directory | refresh=false terminal=false bash=/usr/bin/open param1=-b param2=\"$filemanager\" param3=\"$soundsdir\""
		fi
	fi
}

# sounds
echo "Sounds"
if ! $istriduum ; then
	if $soundsexist ; then
		echo "--Import Sounds… | refresh=true terminal=false bash=$0 param1=addsound"
		echo "-----"
		while read -r sound
		do
			if [[ $sound == "$ccksound" ]] && [[ $soundsource == "cck" ]] ; then
				echo "--$sound | checked=true terminal=false refresh=false bash=/usr/bin/afplay param1=-r param2=\"$audiorate\" param3=-v param4=\"$volume\" param5=\"$soundsdir/$sound\""
				echo "--⚠️ Can't delete active sound! | checked=true alternate=true terminal=false refresh=false bash=/usr/bin/afplay param1=-r param2=\"$audiorate\" param3=-v param4=\"$volume\" param5=\"$soundsdir/$sound\""
			else
				echo "--$sound | terminal=false refresh=true bash=$0 param1=selectsound param2=\"$sound\""
				if [[ $sound != "$defaultsound" ]] ; then
					echo "--Delete $sound… | alternate=true terminal=false refresh=true bash=$0 param1=trash param2=\"$sound\""
				else
					echo "--⚠️ Can't delete default sound! | alternate=true"
				fi
			fi
		done < <(echo "$allsounds" | grep -v "^$" | sort -bf)
		_open-sounds
	else
		echo "--Import Sounds… | refresh=true terminal=false bash=$0 param1=addsound"
		echo "-----"
		echo "--Empty"
		_open-sounds
	fi
	echo "-----"
	usersounds=$(find "$usersoundsdir" -mindepth 1 -maxdepth 1 -type f -exec basename {} \;)
	if [[ $soundsource == "user" ]] ; then
		echo "--User Sounds | checked=true"
	else
		echo "--User Sounds"
	fi
	if [[ $usersounds ]] ; then
		prefix="user"
		while read -r sound
		do
			if [[ $sound == "$ccksound" ]] && [[ $soundsource == "user" ]] ; then
				echo "----$sound | checked=true refresh=false terminal=false bash=/usr/bin/afplay param1=-r param2=\"$audiorate\" param3=-v param4=\"$volume\" param5=\"$usersoundsdir/$sound\""
			else
				echo "----$sound | terminal=false refresh=true bash=$0 param1=selectsound param2=\"$prefix:$sound\""
				echo "----Preview $sound… | alternate=true refresh=false terminal=false bash=/usr/bin/afplay param1=-r param2=\"$audiorate\" param3=-v param4=\"$volume\" param5=\"$usersoundsdir/$sound\""
			fi
		done < <(echo "$usersounds" | sort -bf)
	fi
	systemsounds=$(find "$systemsoundsdir" -mindepth 1 -maxdepth 1 -type f -exec basename {} \;)
	if [[ $soundsource == "system" ]] ; then
		echo "--System Sounds | checked=true"
	else
		echo "--System Sounds"
	fi
	if [[ $systemsounds ]] ; then
		prefix="system"
		while read -r sound
		do
			if [[ $sound == "$ccksound" ]] && [[ $soundsource == "system" ]] ; then
				echo "----$sound | checked=true refresh=false terminal=false bash=/usr/bin/afplay param1=-r param2=\"$audiorate\" param3=-v param4=\"$volume\" param5=\"$systemsoundsdir/$sound\""
			else
				echo "----$sound | terminal=false refresh=true bash=$0 param1=selectsound param2=\"$prefix:$sound\""
				echo "----Preview $sound… | alternate=true refresh=false terminal=false bash=/usr/bin/afplay param1=-r param2=\"$audiorate\" param3=-v param4=\"$volume\" param5=\"$systemsoundsdir/$sound\""
			fi
		done < <(echo "$systemsounds" | sort -bf)
	fi
	coresoundssubdirs=$(find "$coresoundsdir" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; 2>/dev/null)
	if [[ $soundsource == "core" ]] ; then
		echo "--Core Sounds | checked=true"
	else
		echo "--Core Sounds"
	fi
	if [[ $coresoundssubdirs ]] ; then
		prefix="core"
		while read -r coresoundssubdir
		do
			coresounds=$(find "$coresoundsdir/$coresoundssubdir" -mindepth 1 -maxdepth 1 -type f -exec basename {} \; 2>/dev/null)
			if [[ $coresounds ]] ; then
				if [[ $coresoundssubdir == "$ccksoundparent" ]] ; then
					echo "----${(C)coresoundssubdir} | checked=true"
				else
					echo "----${(C)coresoundssubdir:u}"
				fi
				while read -r sound
				do
					if [[ $sound == "$ccksound" ]] && [[ $soundsource == "core" ]] ; then
						echo "------$sound | checked=true refresh=false terminal=false bash=/usr/bin/afplay param1=-r param2=\"$audiorate\" param3=-v param4=\"$volume\" param5=\"$coresoundsdir/$coresoundssubdir/$sound\""
					else
						echo "------$sound | terminal=false refresh=true bash=$0 param1=selectsound param2=\"$prefix:$coresoundssubdir/$sound\""
						echo "------Preview $sound… | alternate=true refresh=false terminal=false bash=/usr/bin/afplay param1=-r param2=\"$audiorate\" param3=-v param4=\"$volume\" param5=\"$coresoundsdir/$coresoundssubdir/$sound\""
					fi
				done < <(echo "$coresounds" | sort -bf)
			fi
		done < <(echo "$coresoundssubdirs" | sort -bf)
	fi
fi

# sound settings
echo "Playback Settings"
if ! $istriduum ; then
	if $skipaudio ; then
		echo "--Skip During Audio Playback | checked=true terminal=false bash=$0 param1=skip-audio param2=off"
	else
		echo "--Skip During Audio Playback | terminal=false bash=$0 param1=skip-audio param2=on"
	fi
	echo "-----"
	echo "--Volume: $volume"
	echo "--Change Volume… | refresh=true terminal=false bash=$0 param1=changevolume param2=\"$volume\""
	echo "-----"
	echo "--Playback Rate: $audiorate"
	echo "--Change Playback Rate… | terminal=false refresh=true bash=$0 param1=changerate param2=\"$audiorate\""
fi

# blacklist
echo "---"
echo "Blacklist"
if ! $istriduum ; then
	if $blacklistenabled ; then
		echo "--Enabled | checked=true refresh=true terminal=false bash=$0 param1=blacklist param2=disable"
	else
		echo "--Enable… | refresh=true terminal=false bash=$0 param1=blacklist param2=enable"
	fi
	blacklist=$(cat "$blacklist_loc" 2>/dev/null)
	echo "-----"
	if ! [[ $blacklist ]] ; then
		echo "--Empty"
		echo "-----"
		echo "--Add Application… | refresh=true terminal=false bash=$0 param1=blacklist param2=add"
	else
		echo "--Applications | size=11"
		echo "--Bundle IDs | size=11 alternate=true"
		while read -r blacklisted
		do
			! [[ $blacklisted ]] && continue
			appid=$(echo "$blacklisted" | awk -F";" '{print $1}')
			appname=$(echo "$blacklisted" | awk -F";" '{print $NF}')
			echo "--$appname | refresh=true terminal=false bash=$0 param1=blacklist param2=remove param3=\"$appid\""
			echo "--$appid | alternate=true refresh=true terminal=false bash=$0 param1=blacklist param2=remove param3=\"$appid\""
		done < <(echo "$blacklist")
		echo "-----"
		echo "--Add Application… | refresh=true terminal=false bash=$0 param1=blacklist param2=add"
		echo "-----"
		echo "--Reset… | refresh=true terminal=false bash=$0 param1=resetblacklist"
	fi
fi

# main settings
echo "---"
echo "Settings"

if $geolocerror ; then
	echo "--❌ Geolocation Error!"
	echo "-----"
elif $reqerror ; then
	echo "--⚠️ Reinstall: Missing Dependency!"
	echo "-----"
fi

if $istriduum ; then
	echo "--Interval: $cckinterval minutes"
else
	if ! $tollquarter ; then
		echo "--Interval: $cckinterval minutes | refresh=true terminal=false bash=$0 param1=settings param2=interval param3=\"$cckinterval\""
	else
		echo "--Interval: 🔒 $cckinterval minutes"
	fi
fi

echo "-----"
if $afterhours ; then
	if $istriduum ; then
		echo "--After-hours"
	else
		echo "--After-hours | checked=true refresh=true terminal=false bash=/usr/bin/defaults param1=write param2=\"$prefs\" param3=AfterHours param4=-bool param5=false param6=2>/dev/null"
	fi
	if $nightmode ; then
		if $istriduum ; then
			echo "--Silent Nights"
		else
			if $permanent && [[ $permstr == "Day" ]] ; then
				echo "--Silent Nights"
			else
				echo "--Silent Nights | checked=true refresh=true terminal=false bash=/usr/bin/defaults param1=write param2=\"$prefs\" param3=NightMode param4=-bool param5=false param6=2>/dev/null"
			fi
		fi
		echo "--Last Chime: $finalhourstr"
		echo "--First Chime: $firsthourstr"
	else
		if $istriduum ; then
			echo "--Silent Nights"
			echo "--Last Chime: $finalhourstr"
			echo "--First Chime: $firsthourstr"
		else
			if $reqerror ; then
				echo "--⚠️ Silent Nights"
				echo "--Last Chime: $finalhourstr"
				echo "--First Chime: $firsthourstr"
			elif $geolocerror ; then
				echo "--❌ Silent Nights"
				echo "--Last Chime: $finalhourstr"
				echo "--First Chime: $firsthourstr"
			else
				if $permanent && [[ $permstr == "Day" ]] ; then
					echo "--Silent Nights"
					echo "--Last Chime: $finalhourstr | refresh=true terminal=false bash=$0 param1=settings param2=notafter param3=\"$finalhourstr\""
					echo "--First Chime: $firsthourstr | refresh=true terminal=false bash=$0 param1=settings param2=notbefore param3=\"$firsthourstr\""
				else
					echo "--Silent Nights | refresh=true terminal=false bash=/usr/bin/defaults param1=write param2=\"$prefs\" param3=NightMode param4=-bool param5=true param6=2>/dev/null"
					echo "--Last Chime: $finalhourstr | refresh=true terminal=false bash=$0 param1=settings param2=notafter param3=\"$finalhourstr\""
					echo "--First Chime: $firsthourstr | refresh=true terminal=false bash=$0 param1=settings param2=notbefore param3=\"$firsthourstr\""
				fi
			fi
		fi
	fi
else
	if $istriduum ; then
		echo "--After-hours"
		echo "--Silent nights"
	else
		echo "--After-hours | refresh=true terminal=false bash=/usr/bin/defaults param1=write param2=\"$prefs\" param3=AfterHours param4=-bool param5=true param6=2>/dev/null"
		echo "--Silent Nights"
	fi
	echo "--Last Chime: $finalhourstr"
	echo "--First Chime: $firsthourstr"
fi

echo "-----"
if $permanent || $istriduum ; then
	echo "--Warn Before Sunrise"
	echo "--Warning Time: $sunrisewarnhours Hours"
else
	if $warnsunrise ; then
		echo "--Warn Before Sunrise | checked=true refresh=true terminal=false bash=/usr/bin/defaults param1=write param2=\"$prefs\" param3=warnBeforeSunrise param4=-bool param5=false param6=2>/dev/null"
		echo "--Warning Time: $sunrisewarnhours Hours | refresh=true terminal=false bash=$0 param1=settings param2=warnhours param3=\"$sunrisewarnhours\""
	else
		echo "--Warn Before Sunrise | refresh=true terminal=false bash=/usr/bin/defaults param1=write param2=\"$prefs\" param3=warnBeforeSunrise param4=-bool param5=true param6=2>/dev/null"
		echo "--Warning Time: $sunrisewarnhours Hours"
	fi
fi

echo "-----"
if $istriduum ; then
	echo "--Skip During Screensaver"
	echo "--Skip During Screen Sleep"
else
	if $skipsaver ; then
		echo "--Skip During Screensaver | checked=true refresh=true terminal=false bash=/usr/bin/defaults param1=write param2=\"$prefs\" param3=skipScreensaver param4=-bool param5=false param6=2>/dev/null"
	else
		echo "--Skip During Screensaver | refresh=true terminal=false bash=/usr/bin/defaults param1=write param2=\"$prefs\" param3=skipScreensaver param4=-bool param5=true param6=2>/dev/null"
	fi

	if $skipsleep ; then
		echo "--Skip During Screen Sleep | checked=true refresh=true terminal=false bash=/usr/bin/defaults param1=write param2=\"$prefs\" param3=skipScreenSleep param4=-bool param5=false param6=2>/dev/null"
	else
		echo "--Skip During Screen Sleep | refresh=true terminal=false bash=/usr/bin/defaults param1=write param2=\"$prefs\" param3=skipScreenSleep param4=-bool param5=true param6=2>/dev/null"
	fi
fi

echo "-----"
if $istriduum ; then
	echo "--Toll Hour"
	echo "--Toll Hour With 4 Strikes"
	echo "--Toll Quarter Hour"
else
	if $tollhour ; then
		echo "--Toll Hour | checked=true refresh=true terminal=false bash=/usr/bin/defaults param1=write param2=\"$prefs\" param3=tollHour param4=-bool param5=false param6=2>/dev/null"
	else
		echo "--Toll Hour | refresh=true terminal=false bash=/usr/bin/defaults param1=write param2=\"$prefs\" param3=tollHour param4=-bool param5=true param6=2>/dev/null"
	fi
	if $tollhour ; then
		if $tollquarter ; then
			echo "--Toll Hour With 4 Strikes"
			echo "--Toll Quarter Hour | checked=true refresh=true terminal=false bash=/usr/bin/defaults param1=write param2=\"$prefs\" param3=tollQuarterHour param4=-bool param5=false param6=2>/dev/null"
		else
			if $fourstrikes ; then
				echo "--Toll Hour With 4 Strikes | checked=true refresh=true terminal=false bash=/usr/bin/defaults param1=write param2=\"$prefs\" param3=fourStrikes param4=-bool param5=false param6=2>/dev/null"
				echo "--Toll Quarter Hour | refresh=true terminal=false bash=/usr/bin/defaults param1=write param2=\"$prefs\" param3=tollQuarterHour param4=-bool param5=true param6=2>/dev/null"
			else
				echo "--Toll Hour With 4 Strikes | refresh=true terminal=false bash=/usr/bin/defaults param1=write param2=\"$prefs\" param3=fourStrikes param4=-bool param5=true param6=2>/dev/null"
				echo "--Toll Quarter Hour | refresh=true terminal=false bash=/usr/bin/defaults param1=write param2=\"$prefs\" param3=tollQuarterHour param4=-bool param5=true param6=2>/dev/null"
			fi
		fi
	else
		if $fourstrikes ; then
			echo "--Toll Hour With 4 Strikes | checked=true"
		else
			echo "--Toll Hour With 4 Strikes"
		fi
		echo "--Toll Quarter Hour"
	fi
fi

echo "-----"
if $triduum ; then
	echo "--Silent Triduum Sacrum | checked=true refresh=true terminal=false bash=/usr/bin/defaults param1=write param2=\"$prefs\" param3=silentTriduum param4=-bool param5=false param6=2>/dev/null"
else
	if $reqerror ; then
		echo "--⚠️ Silent Triduum Sacrum"
	elif $geolocerror ; then
		echo "--❌ Silent Triduum Sacrum"
	else
		echo "--Silent Triduum Sacrum | refresh=true terminal=false bash=/usr/bin/defaults param1=write param2=\"$prefs\" param3=silentTriduum param4=-bool param5=true param6=2>/dev/null"
	fi
fi

if $western ; then
	echo "--Western Calendar | checked=true refresh=true terminal=false bash=$0 param1=settings param2=calswitch param3=eastern"
else
	echo "--Eastern Calendar | checked=true refresh=true terminal=false bash=$0 param1=settings param2=calswitch param3=western"
fi

# management
echo "Manage..."
if $istriduum ; then
	echo "--Quiet Mode"
	echo "--Chimes"
else
	if ! $cckoff ; then
		if $cckquiet ; then
			echo "--Quiet Mode | checked=true refresh=true terminal=false bash=$0 param1=chimes param2=quietmode param3=off"
			echo "--Chimes"
		else
			echo "--Quiet Mode | refresh=true terminal=false bash=$0 param1=chimes param2=quietmode param3=on"
			echo "--Chimes | checked=true refresh=true terminal=false bash=$0 param1=chimes param2=disable"
		fi
	else
		echo "--Quiet Mode"
		echo "--Chimes | refresh=true terminal=false bash=$0 param1=chimes param2=enable"
	fi
fi
echo "-----"
echo "--LaunchAgent | size=11"
if $agentexists ; then
	if $agentdisabled ; then
		echo "--Reenable… | refresh=true terminal=false bash=$0 param1=agent param2=enable"
	else
		if $agentloaded ; then
			echo "--Unload Until Reboot | refresh=true terminal=false bash=/bin/launchctl param1=unload param2=\"$agent_loc\""
			echo "--Disable Permanently | refresh=true terminal=false bash=$0 param1=agent param2=disable"
		else
			echo "--Load… | refresh=true terminal=false bash=/bin/launchctl param1=load param2=\"$agent_loc\""
			echo "--Disable Permanently | refresh=true terminal=false bash=$0 param1=agent param2=disable param=unloaded"
		fi
	fi
else
	echo "--Agent Not Found"
fi
echo "-----"
echo "--Reset Preferences… | refresh=true terminal=false bash=$0 param1=resetprefs"
echo "--Reinstall Auxiliaries… | refresh=true terminal=false bash=$0 param1=cckreinstall"
echo "-----"
echo "--Open in Editor… | size=11"
if $cckexists || $prefsexist || $agentexists || [[ $blacklist ]] ; then
	if [[ $blacklist ]] ; then
		echo "--Applications Blacklist | refresh=false terminal=false bash=/usr/bin/open param1=\"$blacklist_loc\""
	fi
	if $cckexists ; then
		echo "--cck UNIX Shell Script | refresh=false terminal=false bash=/usr/bin/open param1=\"$cck_loc\""
	fi
	echo "--cckm UNIX Shell Script | terminal=false bash=/usr/bin/open param1=\"$mypath\""
	if $agentexists ; then
		echo "--LaunchAgent File | refresh=false terminal=false bash=/usr/bin/open param1=\"$agent_loc\""
	fi
	if $prefsexist ; then
		echo "--Preferences File | refresh=false terminal=false bash=/usr/bin/open param1=\"$prefsloc\""
	fi
else
	echo "--cckm UNIX Shell Script | terminal=false bash=/usr/bin/open param1=\"$mypath\""
fi
echo "-----"
echo "--Cuckoo Menu on GitHub… | refresh=false href=\"$cckmurl\""
echo "-----"
echo "--Uninstall Cuckoo Menu… | refresh=true terminal=false bash=$0 param1=cckuninstall"

# logs
if [[ $stdoutlog ]] || [[ $stderrlog ]] ; then
	echo "Logs"
	echo "--*** local.lcars.cck.stdout *** | $monofont"
	if [[ $stdoutlog ]] ; then
		while read -r stdouts
		do
			echo "--$stdouts | $monofont"
		done < <(echo "$stdoutlog")
		echo "-----"
		echo "--Open stdout in Console… | terminal=false bash=/usr/bin/open param1=-b param2=com.apple.Console param3=\"$stdout_loc\""
		echo "--Clear stdout Log… | alternate=true refresh=true terminal=false bash=/bin/rm param1=-f param2=\"$stdout_loc\""
		echo "-----"
	else
		echo "--Log empty | $monofont"
	fi
	echo "-----"
	echo "--*** local.lcars.cck.stderr *** | $monofont"
	if [[ $stderrlog ]] ; then
		while read -r stderrs
		do
			echo "--$stderrs | $monofont"
		done < <(echo "$stderrlog")
		echo "-----"
		echo "--Open stderr in Console… | terminal=false bash=/usr/bin/open param1=-b param2=com.apple.Console param3=\"$stderr_loc\""
		echo "--Clear stderr Log… | alternate=true refresh=true terminal=false bash=/bin/rm param1=-f param2=\"$stderr_loc\""
		echo "-----"
	else
		echo "--Log empty | $monofont"
	fi
else
	echo "Logs"
	echo "--Logs empty | $monofont"
fi

echo "---"

echo "Refresh… | refresh=true"

exit
