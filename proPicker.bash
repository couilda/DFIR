#!/bin/bash

cd /usr/share/volatility/ ; git pull

#Select the source Memory file to be examined
LOCATION=$(zenity --file-selection --title="Choose your Image" --filename="/mnt/Cases/")
echo "Memory Image set to" "$LOCATION"
echo ""

#Select the destination folder for the case
outputDir=$(zenity --file-selection --directory --title="Choose the Output Directory" --filename="/mnt/Cases/")
echo "Analysis of" "$LOCATION" "will be placed in" "$outputDir"
echo ""

#Move to the output Directory
echo "Scootin' to " "$outputDir"
cd "$outputDir"
echo ""

#Identify the correct profile for the Memory File
echo "Determining Profile - KDBGscan"
volatility -f "$LOCATION" kdbgscan > kdbgscan.txt
echo ""

#Extract the correct Offset for the capture
OFFSET=$(cat kdbgscan.txt | grep "Offset (P)" | awk '{print $4}' | head -1)
echo "Offset will be" "$OFFSET"
echo ""

#Extract all the relevant profiles for the capture
cat kdbgscan.txt | grep Profile | awk '{print $4}' > profileSuggestion.txt
echo "Potential profiles are as follows:"
cat profileSuggestion.txt
echo ""

#Test each profile buy running psscan
echo "Lets rip through a few of these..."
echo ""

while read profile; do
	echo "Checking $profile for Compatibility"
	volatility -f "$LOCATION" --kdbg="$OFFSET" --profile=$profile psscan > psscan.$profile.txt
	wc -l psscan.$profile.txt >> profileSummary.txt
	echo ""
done <profileSuggestion.txt 
echo ""

#Identify the longest files (**assume the longer files completed successfully**)
echo "Final verdict on Profiles:"
echo ""
sort -k1 -n -r profileSummary.txt

PROFILE=$(cat profileSummary.txt | head -1 | awk '{print $2}'  | cut -d'.' -f2-2)
echo ""

#Echo suggestions
echo "Suggested settings are to use $PROFILE as your profile with $OFFSET as your Offset"
echo ""

"Creating volatilityrc file in this directory..."

echo "[DEFAULT]" >> volatilityrc
echo "PROFILE=""$PROFILE" >> volatilityrc
echo "LOCATION=file:///""$LOCATION" >> volatilityrc
echo "KDBG=""$OFFSET"
