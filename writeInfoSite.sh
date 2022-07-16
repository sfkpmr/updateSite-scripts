#!/bin/bash

JSON=json/software.json

if [[ ! -d about/ ]]; then
    mkdir about
fi

jq -c '.[]' $JSON | while read i; do
	# do stuff with $i
	NAME=$(jq -r '.name' <<< "$i")
	RELEASEVERSION=$(jq -r '.release_version' <<< "$i")
	RELEASEURL=$(jq -r '.release_url' <<< "$i")
	GUIDEURL=$(jq -r '.guide_url' <<< "$i")
	DOWNLOADURL=$(jq -r '.download_url' <<< "$i")

touch about/"${NAME//[[:blank:]]/}".html

if [ $DOWNLOADURL != "-" ]; then

cat > about/"${NAME//[[:blank:]]/}".html << EOF

<!DOCTYPE html>
<html lang="en">

<head>
    <title>About $NAME</title>
    <link rel="stylesheet" type="text/css" href="../static/mobile.css" />
    <link rel="icon" href="../static/favicon.ico">
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>

<body>
    <h1>$NAME</h1>
    <br>
    <h5>$RELEASEVERSION</h5>

    <div class="periodic-about">
        <div class="periodic-element blue-box">
	    <a href="$DOWNLOADURL">
            <div class="periodic-element-about">
                <div class="title">
                    Download
                </div>
            </div>
	    </a>
        </div>
        <div class="periodic-element blue-box">
	    <a href="$RELEASEURL">
            <div class="periodic-element-about">
                <div class="title">
                    Release information
                </div>
            </div>
            </a>
        </div>
        <div class="periodic-element blue-box">
            <a href="$GUIDEURL">
            <div class="periodic-element-about">
                <div class="title">
                    Installation guide
                </div>
            </div>
            </a>
        </div>
    </div>
</body>

</html>

EOF

else

cat > about/"${NAME//[[:blank:]]/}".html << EOF

<!DOCTYPE html>
<html lang="en">

<head>
    <title>About $NAME</title>
    <link rel="stylesheet" type="text/css" href="../static/mobile.css" />
    <link rel="icon" href="../static/favicon.ico">
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>

<body>
    <h1>$NAME</h1>
    <br>
    <h5>$RELEASEVERSION</h5>

    <div class="periodic-about">
        <div class="periodic-element blue-box">
	    <a href="$RELEASEURL">
            <div class="periodic-element-about">
                <div class="title">
                    Release information
                </div>
            </div>
            </a>
        </div>
        <div class="periodic-element blue-box">
            <a href="$GUIDEURL">
            <div class="periodic-element-about">
                <div class="title">
                    Installation guide
                </div>
            </div>
            </a>
        </div>
    </div>
</body>

</html>

EOF

fi

done
