#!/bin/bash

# Define our logging filename.
LOGFILE="$PWD"/update.log

cd ~/crump/ || exit

# Install Crump's required Python modules.
pip install -r requirements.txt

# Run Crump, generating non-Elasticsearch files.
echo "Now moving to running Crump"
./crump -d
if [ $? -ne 0 ]; then
    echo "$(date) [ERROR] Crump generated errors" >> "$LOGFILE"
    exit
fi
echo "$(date) Crump generated data" >> "$LOGFILE"

# Figure out what the date was 8 days ago, to only geocode recent records.
date_since=$(date --date='-8 days' +%Y-%m-%d)

# Geocode the data.
./geocode -i output/2_corporate.csv -c 9-13 --since "$date_since"
if [ $? -ne 0 ]; then
    echo "$(date) [ERROR] Could not save geocode 2_corporate.csv" >> "$LOGFILE"
fi
echo "$(date) Geocoded 2_corporate.csv" >> "$LOGFILE"

./geocode -i output/3_lp.csv -c 10-14 --since "$date_since"
if [ $? -ne 0 ]; then
    echo "$(date) [ERROR] Could not save geocode 3_lp.csv" >> "$LOGFILE"
fi
echo "$(date) Geocoded 3_lp.csv" >> "$LOGFILE"

./geocode -i output/9_llc.csv -c 9-13 --since "$date_since"
if [ $? -ne 0 ]; then
    echo "$(date) [ERROR] Could not save geocode 9_llc.csv" >> "$LOGFILE"
fi
echo "$(date) Geocoded 9_llc.csv" >> "$LOGFILE"

############################################################
### MOVE (NOT COPY) output/*.json output/*.csv OUT OF DOCKER
### docker cp <containerId>:/file/path/within/container /host/path/target
############################################################

# Run Crump again, translating data, creating Elasticsearch files, and emitting 
# Elasticsearch indexing maps.
./crump -tem
if [ $? -ne 0 ]; then
        echo "$(date) [ERROR] Crump failed to generated Elasticsearch data" >> "$LOGFILE"
	exit
fi
echo "$(date) Crump generated Elasticsearch data" >> "$LOGFILE"

############################################################
### MOVE output/*.json OUT OF DOCKER
### docker cp <containerId>:/file/path/within/container /host/path/target
############################################################

# Generate the complete-database SQLite file.
files=( "1_tables.csv" "2_corporate.csv" "3_lp.csv" "4_amendments.csv" "5_officers.csv" "6_name.csv" "7_merger.csv" "8_registered_names.csv" "9_llc.csv" )
for i in "${files[@]}"
do
	csvsql --db sqlite:///all_records.sqlite --no-inference --insert "$i"
	if [ $? -ne 0 ]; then
                echo "$(date) [ERROR] $i could not be inserted into all_records.sqlite" >> "$LOGFILE"
        else
                echo "$(date) $i inserted into all_records.sqlite" >> "$LOGFILE"
	fi
done
zip all_records.sqlite.zip all_records.sqlite
echo "$(date) SQLite database exported to a ZIP file" >> "$LOGFILE"

