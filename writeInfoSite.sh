#!/bin/bash

json=json/software.json

jq -c '.[]' $json | while read i; do
	# do stuff with $i
	name=$(jq -r '.name' <<< "$i")
	releaseVersion=$(jq -r '.releaseVersion' <<< "$i")
	releaseURL=$(jq -r '.releaseURL' <<< "$i")
	guideURL=$(jq -r '.guideURL' <<< "$i")
	downloadURL=$(jq -r '.downloadURL' <<< "$i")

touch about/"${name//[[:blank:]]/}".html

if [ $downloadURL != "-" ]; then

cat > about/"${name//[[:blank:]]/}".html << EOF

<!DOCTYPE html>
<html lang="en">

<head>
    <title>About $name</title>
    <link rel="stylesheet" type="text/css" href="../static/mobile.css" />
    <link rel="icon" href="../static/favicon.ico">
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>

<body>
    <h1>$name</h1>
    <br>
    <h5>$releaseVersion</h5>

    <div class="periodic-about">
        <div class="periodic-element blue-box">
	    <a href="$downloadURL">
            <div class="periodic-element-about">
                <div class="title">
                    Download
                </div>
            </div>
	    </a>
        </div>
        <div class="periodic-element blue-box">
	    <a href="$releaseURL">
            <div class="periodic-element-about">
                <div class="title">
                    Release information
                </div>
            </div>
            </a>
        </div>
        <div class="periodic-element blue-box">
            <a href="$guideURL">
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

cat > about/"${name//[[:blank:]]/}".html << EOF

<!DOCTYPE html>
<html lang="en">

<head>
    <title>About $name</title>
    <link rel="stylesheet" type="text/css" href="../static/mobile.css" />
    <link rel="icon" href="../static/favicon.ico">
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>

<body>
    <h1>$name</h1>
    <br>
    <h5>$releaseVersion</h5>

    <div class="periodic-about">
        <div class="periodic-element blue-box">
	    <a href="$releaseURL">
            <div class="periodic-element-about">
                <div class="title">
                    Release information
                </div>
            </div>
            </a>
        </div>
        <div class="periodic-element blue-box">
            <a href="$guideURL">
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
