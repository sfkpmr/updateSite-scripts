json=json/software.json
tempJson=json/temp.json
releaseCsv=csv/checkReleases.csv
tagCsv=csv/checkTags.csv

read -p "Software name: " name
read -p "Repo path: " repo
read -p "Releases or tags - r/t: " type
read -p "Software install URL: " guideURL
read -p "Software description: " description
read -p "Download site: " downloadURL

if [ "$type" != 'r' ] && [ "$type" != 't' ]
then
	echo "Only r and t are valid types!"
	exit 0
fi

randValue=$(shuf -i 1-3 -n 1)

if [ "$randValue" == 1 ]; then
	boxColour=blue-box
elif [ "$randValue" == 2 ]; then
	boxColour=green-box
else
	boxColour=red-box
fi

jq --arg name "$name" --arg guideURL "$guideURL" --arg description "$description" --arg colour "$boxColour" --arg downloadURL "$downloadURL" '. += [{"name": $name, "releaseVersion": "-", "releaseDate": "-", "releaseURL": "-", "guideURL": $guideURL, "description": $description, "box": $colour, "downloadURL": $downloadURL}]' $json > $tempJson && mv $tempJson $json

if [ "$type" == 'r' ]; then
	echo "$repo,$name" >> $releaseCsv
elif [ "$type" == 't' ]; then
	echo "$repo,$name" >> $tagCsv
else
	echo "Invalid type!"
fi
