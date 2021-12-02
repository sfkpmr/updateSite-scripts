#!/bin/bash

user=sfkpmr
token=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
rootPath=/srv
publicPath=${rootPath}/software
jsonFile=${rootPath}/json/software.json
tempFile=${rootPath}/json/tempjson.json
logFile=${rootPath}/log.log
csvFolder=${rootPath}/csv

checkList () {

if [ ! -f "$jsonFile" ]; then
	echo "[]" > $jsonFile
fi

if grep -o -q "${1}" $jsonFile
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
        jq --arg name "$1" --arg colour "$boxColour" '. += [{"name": $name, "releaseVersion": "-", "releaseDate": "-", "releaseURL": "-", "guideURL": "guideurl", "description": "description", "box": $colour}]' $jsonFile > $tempFile && mv $tempFile $jsonFile
fi

}

updateList () {

echo "Adding ${1} ${2} ${3} ${4}" ${1} ${2} ${3} ${4}

checkList "${1}"

cat $jsonFile |
        jq --arg name "${1}" --arg version ${2} --arg releaseDate ${3} --arg releaseURL ${4} 'map(if .name == $name
                  then . + {"releaseDate": $releaseDate, "releaseVersion": $version, "releaseURL": $releaseURL}
                  else .
                  end
                 )' > $tempFile && mv $tempFile $jsonFile
}

validateVersion () {

echo "ValidateVersion ${1} ${2} ${3} ${4}"

#MIND THE SLASH
fileCheck=${publicPath}/"${2//[[:blank:]]/}".html
echo "File check: $fileCheck"
if [ ! -f "$fileCheck" ]; then
	echo "fil finns inte"
	echo 0 > ${fileCheck}
fi

date=$(TZ=Europe/Stockholm date +'%D %R:%S')
read currentVersion < $fileCheck
echo "Current version $currentVersion"
echo "Checking version ${1}"
echo ${1}

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

echo "ADAMPETER $ver1 $ver2 $ver3 $ver4 $ver5 $ver6 $ver7 $ver8" 

if [ "$currentVersion" = "${1}" ]; then
	echo "$date ${2} is already on version ${1}" >> $logFile
elif [ "$ver5" > "$ver1" ]; then
		updateList "${2}" ${1} ${3} ${4}
                echo "${1}" > "$fileCheck"
                echo "$date ${2} was updated to ${1} from $currentVersion" >> $logFile
elif [ "$counter" == 1 ]; then
        if [[ "$ver5" -ge "$ver1" && "$ver6" -ge "$ver2" ]]; then
                #file names to lowercase
                updateList "${2}" ${1} ${3} ${4}
                echo "${1}" > "$fileCheck"
                echo "$date ${2} was updated to ${1} from $currentVersion" >> $logFile
        fi
elif [ "$counter" == 2 ]; then
	if [[ "$ver5" -ge "$ver1" && "$ver6" -ge "$ver2" && "$ver7" -ge "$ver3" ]]; then
                #file names to lowercase
                updateList "${2}" ${1} ${3} ${4}
                echo "${1}" > "$fileCheck"
                echo "$date ${2} was updated to ${1} from $currentVersion" >> $logFile
	fi
elif [ "$counter" == 3 ]; then
	if [[ "$ver5" -ge "$ver1" && "$ver6" -ge "$ver2" && "$ver7" -ge "$ver3" && "$ver8" -ge "$ver4" ]]; then
                #file names to lowercase
                updateList "${2}" ${1} ${3} ${4}
                echo "${1}" > "$fileCheck"
                echo "$date ${2} was updated to ${1} from $currentVersion" >> $logFile
	fi
else
	echo "$date ${2} was not updated from $currentVersion to ${1}" >> $logFile
fi

}


FILE=${csvFolder}/checkTags.csv
while IFS=, read -r REPO NAME
        do
            echo "I got:$REPO|$NAME"

            NAME=$(echo "$NAME" | tr -d '"')

            echo "I got a second time:$REPO|$NAME"

        repo=$(curl -u ${user}:${token} -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/${REPO}/tags?per_page=100)

        if (grep -o -i -q "${REPO}" <<<$repo)
        then
                echo "API OK";
                #Discarding releases with alpha or rc in the name
                #echo "Repo: $repo"
                releaseName=$(echo "$repo" | grep -o -P '(?<=name": ").*(?=",)' | grep -E '[0-9]{1,3}'\\.'[0-9]{1,3}'\\.'[0-9]{1,3}' | grep -i -v -E 'alpha|rc|dev|candidate|beta' | sed -n '1p')
                echo "releaseName: $releaseName"

                counter=$(echo "$releaseName" | grep -o '\.' | wc -l)
                if [ "$counter" == 2 ]
                then
                        version=$(echo "$releaseName" | grep -Eo '[0-9]{1,4}'\\.'[0-9]{1,3}'\\.'[[:alnum:]]{1,6}')
                else
                        version=$(echo "$releaseName" | grep -Eo '[0-9]{1,4}'\\.'[0-9]{1,3}'\\.'[0-9]{1,3}'\\.'[[:alnum:]]{1,6}')
                fi

                tag=$(curl -u ${user}:${token} -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/${REPO}/releases/tags/${releaseName})
                releaseURL="https://github.com/${REPO}/releases/tag/${releaseName}"

                #Check if has publishing date
                if (grep -o -i -q "published_at" <<<$repo)
                then
                        #-P flag?
                        releaseDate=$(echo "$tag" | grep -o -P '(?<=published_at": ").*(?=",)' | grep -Eo '[0-9]{1,2}'-'[0-9]{1,2}'-'[0-9]{1,2}')
                else
                        releaseDate="-"
                fi

                        validateVersion ${version} "${NAME}" ${releaseDate} ${releaseURL}

        else
                echo "$repo" >> $logFile
        fi

done < ${FILE}

FILE=${csvFolder}/checkReleases.csv
while IFS=, read -r REPO NAME
        do
            echo "I got:$REPO|$NAME"
            NAME=$(echo "$NAME" | tr -d '"')
            echo "I got a second time:$REPO|$NAME"

        echo $REPO $NAME

        repo=$(curl -u ${user}:${token} -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/${REPO}/releases/latest)

        if (grep -o -i -q "${REPO}" <<<$repo)
        then
                echo "API OK"
                releaseName=$(echo "$repo" | grep -o -P '(?<=tag_name": ").*(?=",)' | grep -i -v -E 'alpha|rc|dev|candidate|beta')
                counter=$(echo "$releaseName" | grep -o '\.' | wc -l)

                echo "Antal punkter: $counter i $releaseName"

                if [ "$counter" == 1 ]; then
                        version=$(echo "$releaseName" | grep -Eo '[0-9]{1,4}'\\.'[[:alnum:]]{1,3}')
                elif [ "$counter" == 2 ]; then
                        version=$(echo "$releaseName" | grep -Eo '[0-9]{1,4}'\\.'[0-9]{1,3}'\\.'[[:alnum:]]{1,3}')
                elif [ "$counter" == 3 ]; then
                        version=$(echo "$releaseName" | grep -Eo '[0-9]{1,4}'\\.'[0-9]{1,3}'\\.'[0-9]{1,3}'\\.'[[:alnum:]]{1,6}')
                else
                        echo "No dots in ${NAME} releaseName, likely faulty release, or latest release excluded - setting version to 0." >> $logFile
                        version=0
                fi

                #Check if has publishing date
                if (grep -o -i -q "published_at" <<<$repo)
                then
                        releaseDate=$(echo "$repo" | grep -o -P '(?<=published_at": ").*(?=",)' | grep -Eo '[0-9]{1,2}'-'[0-9]{1,2}'-'[0-9]{1,2}')
                else
                        releaseDate="-"
                fi

                releaseURL="https://github.com/${REPO}/releases/tag/${releaseName}"


                echo "BANAN"
                echo "${version} ${NAME} ${releaseDate} ${releaseURL}"
                validateVersion ${version} "${NAME}" ${releaseDate} ${releaseURL}
        else
                echo $repo >> $logFile
        fi

done < ${FILE}

/bin/bash writeInfoSite.sh

date=$(TZ=Europe/Stockholm date +'%y/%m/%d %T')

echo "Update run ended at $date" >> $logFile
