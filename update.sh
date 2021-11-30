#!/bin/bash

user=sfkpmr
token=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
publicPath=/srv/public
jsonfile=/srv/json/software.json
tempfile=/srv/json/tempjson.json
logfile=/srv/log.log

checkTags () {

repo=$(curl -u ${user}:${token} -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/${1}/tags?per_page=100)

if (grep -o -i -q ${1} <<<$repo)
then
	echo "API OK";
	#Discarding releases with alpha or rc in the name
	echo "Repo: $repo"
	releaseName=$(echo "$repo" | grep -o -P '(?<=name": ").*(?=",)' | grep -E '[0-9]{1,3}'\\.'[0-9]{1,3}'\\.'[0-9]{1,3}' | grep -i -v -E 'alpha|rc|dev|candidate|beta' | sed -n '1p')
	echo "releaseName: $releaseName"

	counter=$(echo "$releaseName" | grep -o '\.' | wc -l)
	if [ "$counter" == 2 ]
	then
		version=$(echo "$releaseName" | grep -Eo '[0-9]{1,4}'\\.'[0-9]{1,3}'\\.'[[:alnum:]]{1,6}')
	else
		version=$(echo "$releaseName" | grep -Eo '[0-9]{1,4}'\\.'[0-9]{1,3}'\\.'[0-9]{1,3}'\\.'[[:alnum:]]{1,6}')
	fi

	tag=$(curl -u ${user}:${token} -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/${1}/releases/tags/${releaseName})
	releaseURL=https://github.com/${1}/releases/tag/${releaseName}

	#Check if has publishing date
	if (grep -o -i -q "published_at" <<<$repo)
	then
		#-P flag?
		releaseDate=$(echo "$tag" | grep -o -P '(?<=published_at": ").*(?=",)' | grep -Eo '[0-9]{1,2}'-'[0-9]{1,2}'-'[0-9]{1,2}')
	else
		releaseDate="-"
	fi

		validateVersion ${version} "${2}" ${releaseDate} ${releaseURL}

else
	echo "$repo" >> $logfile
fi

}

checkReleases () {

repo=$(curl -u ${user}:${token} -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/${1}/releases/latest)

if (grep -o -i -q ${1} <<<$repo)
then
	echo "API OK"
	releaseName=$(echo "$repo" | grep -o -P '(?<=tag_name": ").*(?=",)' | grep -i -v -E 'alpha|rc|dev|candidate|beta')
	counter=$(echo "$releaseName" | grep -o '\.' | wc -l)

	echo "Antal punkter: $counter i $releaseName"

	if [ "$counter" == 1 ]; then
		#version=$(echo "$releaseName" | grep -Eo '[0-9]{1,4}'\\.'[0-9]{1,3}'\\.'[0-9]{1,3}')
		version=$(echo "$releaseName" | grep -Eo '[0-9]{1,4}'\\.'[[:alnum:]]{1,3}')
		echo "Version $version"
	elif [ "$counter" == 2 ]; then
		#version=$(echo "$releaseName" | grep -Eo '[0-9]{1,4}'\\.'[0-9]{1,3}'\\.'[0-9]{1,3}')
                version=$(echo "$releaseName" | grep -Eo '[0-9]{1,4}'\\.'[0-9]{1,3}'\\.'[[:alnum:]]{1,3}')
	elif [ "$counter" == 3 ]; then
                #version=$(echo "$releaseName" | grep -Eo '[0-9]{1,4}'\\.'[0-9]{1,3}'\\.'[0-9]{1,3}'\\.'[0-9]{1,3}')
                version=$(echo "$releaseName" | grep -Eo '[0-9]{1,4}'\\.'[0-9]{1,3}'\\.'[0-9]{1,3}'\\.'[[:alnum:]]{1,6}')
	else
		echo "No dots in ${2} releaseName, likely faulty release, or latest release excluded - setting version to 0." >> $logfile
		version=0
	fi

	#Check if has publishing date
        if (grep -o -i -q "published_at" <<<$repo)
        then
                releaseDate=$(echo "$repo" | grep -o -P '(?<=published_at": ").*(?=",)' | grep -Eo '[0-9]{1,2}'-'[0-9]{1,2}'-'[0-9]{1,2}')
        else
                releaseDate="-"
        fi

	releaseURL=https://github.com/${1}/releases/tag/${releaseName}

	echo "Version " ${version} "namn " "${2}" ${releaseDate} ${releaseURL}
	validateVersion ${version} "${2}" ${releaseDate} ${releaseURL}
else
	echo "$repo" >> $logfile
fi

}

checkList () {

if [ ! -f "$jsonfile" ]; then
	echo "[]" > $jsonfile
fi

if grep -o -q "${1}" $jsonfile
then
        echo "${1} FINNS"
else
        echo "${1} FINNS INTE"

	randValue=$(shuf -i 1-3 -n 1)

	if [ "$randValue" == 1 ]; then
		boxColour=blue-box
        elif [ "$randValue" == 2 ]; then
		boxColour=green-box
        else
            	boxColour=red-box
        fi

	#Add new item to JSON
        jq --arg name "$1" --arg colour "$boxColour" '. += [{"name": $name, "releaseVersion": "-", "releaseDate": "-", "releaseURL": "-", "guideURL": "guideurl", "description": "description", "box": $colour}]' $jsonfile > $tempfile && mv $tempfile $jsonfile
fi

}

updateList () {

echo "Adding ${1} ${2} ${3} ${4}" ${1} ${2} ${3} ${4}

checkList "${1}"

cat $jsonfile |
        jq --arg name "${1}" --arg version ${2} --arg releaseDate ${3} --arg releaseURL ${4} 'map(if .name == $name
                  then . + {"releaseDate": $releaseDate, "releaseVersion": $version, "releaseURL": $releaseURL}
                  else .
                  end
                 )' > $tempfile && mv $tempfile $jsonfile
}

checkMariaDb () {

mariaAPI=$(curl https://downloads.mariadb.org/rest-api/mariadb/10.5/)

if [ -z "$mariaAPI" ]
then
	echo "Empty Maria API return." >> $logfile
else
	releaseVersion=$(echo "$mariaAPI" | jq '.releases | .[] | .release_id' | sed -n '1p' | grep -E -o '[0-9]{1,3}'\\.'[0-9]{1,3}'\\.'[0-9]{1,3}')
	releaseDate=$(echo "$mariaAPI" | jq '.releases | .[] | .date_of_release' | sed -n '1p' | grep -E -o '[0-9]{1,2}'-'[0-9]{1,2}'-'[0-9]{1,2}')

	#tr to keep output on one line
	tempVersionName=$(echo "$releaseVersion" | grep -o [0-9] | tr -d '\n')
	releaseURL=https://mariadb.com/kb/en/mariadb-$tempVersionName-release-notes/

	validateVersion ${releaseVersion} MariaDB ${releaseDate} ${releaseURL}
fi

}

validateVersion () {

#MIND THE SLASH
file=${publicPath}/"${2//[[:blank:]]/}".html
if [ ! -f "$file" ]; then
	echo "fil finns inte"
	echo 0 > ${file}
fi

date=$(TZ=Europe/Stockholm date +'%D %R:%S')
read currentVersion < $file
echo "Current version $currentVersion"
echo "Checking version ${1}"

IFS="." read ver1 ver2 ver3 ver4 <<< "$currentVersion"
IFS="." read ver5 ver6 ver7 ver8 <<< "${1}"

ver1=$(echo "${ver1#"${ver1%%[!0]*}"}")
ver2=$(echo "${ver2#"${ver2%%[!0]*}"}")
ver3=$(echo "${ver3#"${ver3%%[!0]*}"}")
ver4=$(echo "${ver4#"${ver4%%[!0]*}"}")
ver5=$(echo "${ver5#"${ver5%%[!0]*}"}")
ver6=$(echo "${ver6#"${ver6%%[!0]*}"}")
ver7=$(echo "${ver7#"${ver7%%[!0]*}"}")
ver8=$(echo "${ver8#"${ver8%%[!0]*}"}")

counter=$(echo ${1} | grep -o '\.' | wc -l)

#echo "ADAMPETER $ver1 $ver2 $ver3 $ver4 $ver5 $ver6" 

if [ "$currentVersion" = "${1}" ]; then
	echo "$date ${2} is already on version ${1}" >> $logfile
elif [ "$ver5" > "$ver1" ]; then
		updateList "${2}" ${1} ${3} ${4}
                echo "${1}" > "$file"
                echo "$date ${2} was updated to ${1} from $currentVersion" >> $logfile
elif [ "$counter" == 1 ]; then
        if [[ "$ver5" -ge "$ver1" && "$ver6" -ge "$ver2" ]]; then
                #file names to lowercase
                updateList "${2}" ${1} ${3} ${4}
                echo "${1}" > "$file"
                echo "$date ${2} was updated to ${1} from $currentVersion" >> $logfile
        fi
elif [ "$counter" == 2 ]; then
	if [[ "$ver5" -ge "$ver1" && "$ver6" -ge "$ver2" && "$ver7" -ge "$ver3" ]]; then
                #file names to lowercase
                updateList "${2}" ${1} ${3} ${4}
                echo "${1}" > "$file"
                echo "$date ${2} was updated to ${1} from $currentVersion" >> $logfile
	fi
elif [ "$counter" == 3 ]; then
	if [[ "$ver5" -ge "$ver1" && "$ver6" -ge "$ver2" && "$ver7" -ge "$ver3" && "$ver8" -ge "$ver4" ]]; then
                #file names to lowercase
                updateList "${2}" ${1} ${3} ${4}
                echo "${1}" > "$file"
                echo "$date ${2} was updated to ${1} from $currentVersion" >> $logfile
	fi
else
	echo "$date ${2} was not updated from $currentVersion to ${1}" >> $logfile
fi

}

#https://github.com/awesome-selfhosted/awesome-selfhosted
#https://github.com/n1trux/awesome-sysadmin

checkReleases pi-hole/pi-hole Pi-hole
checkReleases jellyfin/jellyfin Jellyfin
checkTags nginx/nginx nginx
checkTags qbittorrent/qbittorrent qBittorrent
checkReleases portainer/portainer Portainer
checkReleases traefik/traefik Traefik
checkTags apache/httpd "Apache HTTP"
checkReleases caddyserver/caddy Caddy
checkReleases nodejs/node Node.js
checkTags openvpn/openvpn OpenVPN
checkReleases rust-lang/rust Rust
checkReleases moby/moby Moby
checkReleases julialang/julia Julia
checkReleases nextcloud/server Nextcloud
checkReleases homebrew/brew Homebrew
checkReleases bastienwirtz/homer Homer
checkReleases tryghost/ghost Ghost
checkReleases tensorflow/tensorflow TensorFlow
checkTags perl/perl5 Perl
checkReleases scala/scala Scala
checkTags git/git Git
checkReleases thelounge/thelounge "The Lounge"
checkReleases twbs/bootstrap Bootstrap
checkReleases angular/angular Angular
checkReleases atom/atom Atom
checkTags django/django Django
checkReleases expressjs/express Express
checkReleases redis/redis Redis
checkMariaDb
checkReleases docker/compose "Docker Compose"
checkTags pfsense/pfsense pfSense
checkTags opnsense/core OPNsense
checkReleases belphemur/soundswitch SoundSwitch
checkTags wireshark/wireshark Wireshark
checkReleases home-assistant/core "Home Assistant"
checkTags apache/guacamole-server Guacamole
checkTags deluge-torrent/deluge Deluge
checkReleases kovidgoyal/calibre Calibre
checkReleases audacity/audacity Audacity
checkReleases airsonic/airsonic Airsonic
checkReleases dani-garcia/vaultwarden Vaultwarden
checkReleases gorhill/uBlock "uBlock Origin"
checkTags vim/vim Vim
checkTags rails/rails Rails
checkReleases dbeaver/dbeaver DBeaver
checkReleases photonstorm/phaser Phaser
checkReleases grafana/grafana Grafana
checkTags apache/tomcat "Apache Tomcat"
checkReleases joomla/joomla-cms Joomla!
checkReleases jekyll/jekyll Jekyll
checkTags kiwiirc/kiwiirc "Kiwi IRC"
checkReleases mumble-voip/mumble Mumble

#Need fix
#checkTags golang/go go
#checkTags owncloud/core owncloud
#checkTags mongodb/mongo mongodb
#checkTags splitbrain/dokuwiki dokuwiki
#ffmpeg/ffmpeg
#VeraCrypt

date=$(TZ=Europe/Stockholm date +'%D %R:%S')

echo "Update run ended at $date" >> $logfile
