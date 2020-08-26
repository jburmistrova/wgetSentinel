# wget Sentinel unarchiving and downloading 

## Overview
Last updated: 08/25/2020

Staring in 2019, Copernicus began archiving tiles into their Long Term Archive (LTA - https://scihub.copernicus.eu/userguide/LongTermArchive). Depending on the product, tiles before a certain date, 1 year for example, would be archived, thereby needing to be requested to be unarchived. Files requested using wget (or cURL) should be unarchived by Copernicus after approximately 24 hours and then remain unarchived for approximately 3 day. 

However, this is not the case. After experimenting with wget and unarchiving, some files took almost 7 days before they were unarchived. 

This code is the product of that experimentation. The first script uses wget to request current archived files to be unarchived. The second script uses wget to download an unarchived file. Both scripts need to be used in tandem in order to work within eachother's time limits. Each tile has a unique identifiying number (UUID) for the day of the platform overpass. The scripts use these UUIDs to request the tiles you want for the dates you want. 

User are required to provide a CSV file with a list of UUIDs you would like to request. Users are also required to provide a txt file with their username and password to their ESA Copernicus account. 

The unarchive_script.R runs twice a day, every 12 hours, and requests 20 files based on Copernicus limits. The download.R script runs once a day, ~24 hours every time. 

## Installation

Make sure you have wget version 1.20.3.
Make sure you have R version  3.6.1 and Tidyverse package version 1.2.1.
Make sure you have a Copernicus account. 
Clone this repository on the computer/server you plan to run the script on. 

## Usage
First, change the copernicus_username_password.txt file to have your username and password. 
Next, in the input_output.txt file, change the input CSV file path to your own CSV, and as a option you can either keep the output paths or change them to where you want to save the Sentinel SAFE files (i.e. /downloaded), and output folder for the wget (.wget_TXT) and script reports (/script_TXT). In addition you can change the number of files the unarchive_request.R script requests (currently set to 20 that are "archived"), and the number of the download.R script attempts to download (currently it is set to request all files successfully requested, "202 Accepted"). You can also change the time in between each run in seconds. 
In your terminal, open two tabs/windows. Move to the directory you cloned in both tab/windows. Then, run the scripts seperately.
Check on the scripts every once in a while, my suggestion is to check daily, to make sure it's still running. 

Example: 
```r
Rscript download.R 
```
```r
Rscript unarchive_request.R
```

## Quirks of these scripts

(1) The unarchive_request.R script request 20 files every 12 hours based on limits set by Copernicus. The download.R script checks to download all the files every 24 hours. Even though Copernicus approximates 24 hours for files to become unarchived, this can take longer based on their request load. 

(2) The scripts run until all the files are archived (unarchived_request.R) and downloaded (download.R). However, this could take days/weeks depending on the number of files you need to request. For example, I tested this on 180 files (July 2020) and it took about 2 weeks. 

(3) If your computer restarts, or your server restarts, you will needed to start running the code again. Luckily, it should just start where it left off. 

(4) It is possible that the script could time out because the Copernicus server is offline for maintence or an error. 

(5) It is possible that Copernicus did not upload a file you are looking for, and in that case the script stops attempting to download a tile after 14 attempts (~2 weeks/14 days)

## Troubleshooting 
This script saves the timestamp of the last unarchive/download attempt in the CSV. In addition the script saves the wget output for each file. 

(1) Check that your path is being read correctly. 

(2) Check that your computer/server didn't restart.

(2) Check that you have the right UUIDs and the CSV is formatted in the correct way. See example CSV. 

(3) Check the .txt files to see if there were any errors with the wget or with the Copernicus server.

(4) Try running the scripts again, or wait a day to try again. 

(5) Consider the possiblity that the Copernicus might not have the file on their server and contact Copernicus directly. 

## Future Updates
Some things that I am working on for the next version:
* Photos will be added to the README.md
* A bash script to possibly run both scripts at the same time.
* The script will automattically add columns if you don't have them, but currently you must change them manually. 
* Having the option to input files as a textfile instead of editing the script. 

## Known Issues 
* Timestamp in the CSV is not working. -- change line 96 in download.R and line 107 in unarchive_request.R to  
            new_timestamp_attempt[u] <- format(Sys.time(), "%Y%m%d_%H%M%S")

* Ingestion dates getting deleted with NAs

* script_txt file is blank

* change sleeping to hours as pause_hours - done and switched to to sleep_hours to make more sense

* 403 Unauthorized not saving - change -- change new status to 
            new_status[u] <- read_lines(outPathTXT,skip = 0, skip_empty_rows = FALSE, n_max = -1L)%>%
            na.omit(str_extract(test, "(?:[:digit:]{3}[:space:])+[[:alpha:]$]+"))[3]
            
* Delete new status <- vector -DONE

* Delete  my_uuid$download_attempt[u] <- my_uuid$download_attempt[u] + 1 from unarchive_request.R file

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.
Please make sure to update tests as appropriate.

## Acknowledgements
Thank you to Christiana Ade, Brittany Lopez Barreto, Jacob Nesslage, and Erin Hestir for the comments on the initial tests of these scripts. 

