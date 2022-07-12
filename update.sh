#!/bin/bash

#Exit immediately if a pipeline returns a non-zero status - https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
set -e

user=sfkpmr
token=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
rootPath=../test
publicPath=${rootPath}/software
jsonFile=${rootPath}/json/software.json
tempFile=${rootPath}/json/tempjson.json
logFile=${rootPath}/log.log
csvFolder=${rootPath}/csv
RELEASESFILE=${rootPath}/csv/releases.csv

checkReleases() {
        echo ""
}

checkTags(){
        echo ""
}

updateList() {

        echo Adding these ${1} ${2} ${3} ${4}

        cat $jsonFile |
                jq --arg name "${1}" --arg version "${2}" --arg releaseDate "${3}" --arg releaseURL ${4} 'map(if .name == $name
                  then . + {"releaseDate": $releaseDate, "releaseVersion": $version, "releaseURL": $releaseURL}
                  else .
                  end
                 )' > $tempFile && mv $tempFile $jsonFile
        echo "Updated software list."

}


if [ ! -f "$jsonFile" ]; then
        echo Software list missing!
        exit 1
fi

while IFS=, read -r REPO NAME
do
        #echo $REPO $NAME
        
        #repo=$(curl -u ${user}:${token} -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/${REPO}/releases/latest)
        REPODATA=$(<../test/tempreleases) 
        #echo $repo >> ../test/tempfile
        #echo $REPODATA
        #echo $NAME
        
        break
done < ${RELEASESFILE}

#REGEX generator https://regex-generator.olafneumann.org/
#RELEASEVERSION=$(echo "$REPODATA" | grep -P -i -o '"tag_name": "[^"]*", ' | grep -i -v -E 'alpha|rc|dev|candidate|beta' )

RELEASEVERSION=$(echo "$REPODATA" | grep -P -i -o '"tag_name": "[^"]*", ' | grep -P -i -o '(\d(\.\d)+)' )
RELEASEDATE=$(echo "$REPODATA" | grep -P -i -o '"published_at": "[^"]*", ' | grep -P -i -o '[0-9]{4}-[0-9]{2}-[0-9]{2}')
RELEASEURL=$(echo "$REPODATA" | grep -P -i -o '"html_url": "[^"]*", ' | head -1 | grep -P -o "http[^ ]*")
#echo ${RELEASEURL%??} #remove final 2 characters

updateList "Redis" ${RELEASEVERSION} $RELEASEDATE ${RELEASEURL%??}

