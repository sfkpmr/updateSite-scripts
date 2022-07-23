#!/bin/bash

set -e

JSON=json/software.json
TEMPJSON=json/temp.json
RELEASECSV=csv/releases.csv
TAGCSV=csv/tags.csv

read -p "Software name: " NAME
read -p "Repo path: " REPO

while true
do
	read -p "Releases or tags - r/t: " RELEASETYPE

	if [ "$RELEASETYPE" == 'r' ]; then
		echo "$REPO,$NAME" >> $RELEASECSV
		break
	elif [ "$RELEASETYPE" == 't' ]; then
		echo "$REPO,$NAME" >> $TAGCSV
		break
	else
		echo "Invalid type!"
	fi
done

read -p "Software install URL: " GUIDEURL
read -p "Software description: " DESCRIPTION
read -p "Download site: " DOWNLOADURL

RANDOMVALUE=$(shuf -i 1-3 -n 1)

if [ "$RANDOMVALUE" == 1 ]; then
	BOXCOLOUR=blue-box
elif [ "$RANDOMVALUE" == 2 ]; then
	BOXCOLOUR=green-box
else
	BOXCOLOUR=red-box
fi

#Add new entry if name does not already exist.
if ! $(cat $JSON | jq --arg NAME "${NAME}" 'any(.[].name; contains($NAME))') ; then
	jq --arg NAME "$NAME" --arg GUIDEURL "$GUIDEURL" --arg DESCRIPTION "$DESCRIPTION" --arg COLOUR "$BOXCOLOUR" --arg DOWNLOADURL "$DOWNLOADURL" \
	'. += [{"name": $NAME, "release_version": "0", "release_date": "0", "release_url": "0", "guide_url": $GUIDEURL, "description": $DESCRIPTION, "box": $COLOUR, "download_url": $DOWNLOADURL}]' $JSON > $TEMPJSON \
	&& mv $TEMPJSON $JSON
fi
