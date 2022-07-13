#!/bin/bash

#Exit immediately if a pipeline returns a non-zero status - https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
set -e

user=sfkpmr
token=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
rootPath=../test
publicPath=${rootPath}/software
SOFTWAREJSON=${rootPath}/json/software.json
tempFile=${rootPath}/json/tempjson.json
logFile=${rootPath}/log.log  #year-month-log file name
#csvFolder=${rootPath}/csv
RELEASESFILE=${rootPath}/csv/releases.csv
TAGSFILE=${rootPath}/csv/tags.csv
TODAY=$(TZ=Europe/Stockholm date +'%y-%m-%d')

#Check if the new version is an update or not
versionCheck() {

        printf -v versions '%s\n%s' "${2}" "${1}"
        if [[ $versions = "$(sort -V <<< "$versions")" ]]; then
                echo -1
        else  
                echo 1
        fi
}

versionFilter() {

        if [[ -z $(echo ${1} | grep -i -E 'alpha|rc|dev|candidate|beta') ]]; then
                echo ${1}
        else
                echo -1
        fi

}

checkReleases() {
        while IFS=, read -r REPO NAME
        do

        #repo=$(curl -u ${user}:${token} -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/${REPO}/releases/latest)
        REPODATA=$(<../test/tempreleases) 
        
       

        #REGEX generator https://regex-generator.olafneumann.org/
        #RELEASEVERSION=$(echo "$REPODATA" | grep -P -i -o '"tag_name": "[^"]*", ' | grep -i -v -E 'alpha|rc|dev|candidate|beta' )

        RELEASEVERSION=$(echo "$REPODATA" | grep -P -i -o '"tag_name": "[^"]*", ' | grep -P -i -o '(\d(\.\d)+)' )
        RELEASEVERSION=$(versionFilter ${RELEASEVERSION})
        RELEASEDATE=$(echo "$REPODATA" | grep -P -i -o '"published_at": "[^"]*", ' | grep -P -i -o '[0-9]{4}-[0-9]{2}-[0-9]{2}')
        RELEASEURL=$(echo "$REPODATA" | grep -P -i -o '"html_url": "[^"]*", ' | head -1 | grep -P -o "http[^ ]*")
        #echo ${RELEASEURL%??} #remove final 2 characters

        updateList ${NAME} ${RELEASEVERSION} ${RELEASEDATE:2} ${RELEASEURL%??} #Trimming two first and last characters

        break
        done < ${RELEASESFILE}
}

checkTags() {
        while IFS=, read -r REPO NAME
        do
        
        #apa=(curl -u ${user}:${token} -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/${REPO}/tags?per_page=100) 
        #echo $apa > ../test/temptags

        #curl -u ${user}:${token} -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/${REPO}/tags?per_page=100 > ../test/temptags
        REPODATA=$(<../test/temptags)

        TAGNAME=$(echo $REPODATA | jq '.[0]' | jq -r '.name' )
        TAGVERSION=$(echo $TAGNAME | grep -o -P '([0-9]+(\.[0-9]+)+)')
        TAGVERSION=$(versionFilter ${TAGVERSION})
        
        updateList $NAME ${TAGVERSION} $TODAY "https://github.com/$REPO/releases/tag/$TAGNAME"

        done < ${TAGSFILE}
}

updateList() {

        echo Adding these ${1} ${2} ${3} ${4}

        #version beta check here instead

        CURRENTVERSION=$(jq -r --arg name "${1}" '.[] | select(.name == $name).releaseVersion' $SOFTWAREJSON)

        if [[ $(versionCheck $CURRENTVERSION ${2}) -eq 1 ]]; then
                cat $SOFTWAREJSON |
                jq --arg name "${1}" --arg version "${2}" --arg releaseDate "${3}" --arg releaseURL ${4} 'map(if .name == $name
                  then . + {"releaseDate": $releaseDate, "releaseVersion": $version, "releaseURL": $releaseURL}
                  else .
                  end
                 )' > $tempFile && mv $tempFile $SOFTWAREJSON
                echo "Updated entry of ${1} - from $CURRENTVERSION to ${2}"
        else
                echo banan
        fi

}


if [ ! -f "$SOFTWAREJSON" ]; then
        echo Software list missing!
        exit 1
fi

checkReleases
checkTags
