#!/bin/bash

#Exit immediately if a pipeline returns a non-zero status - https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
set -e

USER=sfkpmr
TOKEN=$(<../test/github_token) #gör ny TOKEN 
rootPath=../test
SOFTWAREJSON=${rootPath}/json/software.json
tempFile=${rootPath}/json/tempjson.json
RELEASESLIST=${rootPath}/csv/releases.csv
TAGSLIST=${rootPath}/csv/tags.csv
TODAY=$(TZ=Europe/Stockholm date +'%y-%m-%d')
LOGNAME=$(TZ=Europe/Stockholm date +'%Y-%m').log
LOGDIRECTORY=logs/ #slash needed?

writeLog() {

        date=$(TZ=Europe/Stockholm date +'%y/%m/%d %T')
        echo "$date | ${1} | New release: ${2} Old: ${3} | ${4}" >> $LOGDIRECTORY/$LOGNAME
}

versionCheck() {

        #https://stackoverflow.com/questions/48491662/comparing-two-version-numbers-in-a-shell-script
        printf -v versions '%s\n%s' "${2}" "${1}"
        if [[ $versions = "$(sort -V <<< "$versions")" ]]; then
                echo -1
        else  
                echo 1
        fi
}

versionFilter() {

        #Filter out unstable releases
        #-z returns true if the string is null
        if [[ -z $(echo ${1} | grep -i -E 'alpha|rc|dev|candidate|beta') ]]; then
                #VERSIONNUMBER=$(echo ${1} | grep -P -i -o '([0-9]+(\.[0-9]+)+)')
                #echo $VERSIONNUMBER
                echo $(echo ${1} | grep -P -i -o '([0-9]+(\.[0-9]+)+)')
        else
                echo -1
        fi
}

checkReleases() {
        while IFS=, read -r REPO NAME
        do
                REPODATA=$(curl -u ${USER}:${TOKEN} -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/${REPO}/releases/latest)
                #REGEX generator https://regex-generator.olafneumann.org/
                RELEASEVERSION=$(echo "$REPODATA" | jq -r .tag_name ) # | grep -P -i -o '([0-9]+(\.[0-9]+)+)'
                RELEASEDATE=$(echo "$REPODATA" | jq -r .published_at | grep -P -i -o '[0-9]{4}-[0-9]{2}-[0-9]{2}')
                RELEASEURL=$(echo $REPODATA | jq -r .html_url)

                updateList ${NAME} ${RELEASEVERSION} ${RELEASEDATE:2} ${RELEASEURL} #Trimming two first characters
        break
        done < ${RELEASESLIST}
}

checkTags() {
        while IFS=, read -r REPO NAME
        do
                REPODATA=$(curl -u ${USER}:${TOKEN} -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/${REPO}/tags?per_page=100) 
                TAGNAME=$(echo $REPODATA | jq -r '.[0].name' )
                updateList $NAME ${TAGNAME} $TODAY "https://github.com/$REPO/releases/tag/$TAGNAME"
        done < ${TAGSLIST}
}

updateList() {

        VERSION=$(versionFilter ${2})
       
        if [[ "$VERSION" != -1 ]] ; then

                CURRENTVERSION=$(jq -r --arg name "${1}" '.[] | select(.name == $name).release_version' $SOFTWAREJSON)

                if [[ $(versionCheck $CURRENTVERSION $VERSION) -eq 1 ]]; then
                        cat $SOFTWAREJSON |
                        jq --arg name "${1}" --arg version $VERSION --arg releaseDate "${3}" --arg releaseURL ${4} 'map(if .name == $name
                        then . + {"release_date": $releaseDate, "release_version": $version, "release_url": $releaseURL}
                        else .
                        end
                        )' > $tempFile && mv $tempFile $SOFTWAREJSON && writeLog ${1} $VERSION $CURRENTVERSION "Updated!" 
                else
                        writeLog ${1} ${2} $CURRENTVERSION "Not an update!" 
                fi
        else
                writeLog ${1} ${2} $CURRENTVERSION "Unstable release!" 
        fi
}


if [ ! -f "$SOFTWAREJSON" ]; then
        writeLog ERROR ERROR ERROR "Software list missing!" 
        exit 1
fi

if [[ ! -d "$LOGDIRECTORY" ]]; then
        mkdir $LOGDIRECTORY
fi

touch logs/$LOGNAME

checkReleases
checkTags

( "/mnt/storage/updateSite-scripts/writeInfoSite.sh" )