# Title: download.R
# Author: jburmistrova
# Modified:  08-25-2020
# Purpose: Download Archived S2 data
#
# **Requires** 
# 1) A previously created csv document that includes UUIDs
# 2) A username and password with Copernicus, sign-up found here: https://scihub.copernicus.eu/dhus/#/self-registration

#####################################################################################

## require packages
suppressWarnings(
require(tidyverse)
)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
####             INPUT VARIABLES       #### 
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# The following variables should be defined by the user each time.
#### INPUT FILES ####
# 1) input excel file
inFile <- "/example_query.csv"

#### OUTPUT FILES ####
# 2)
outPathWgetTXT <- "/wget_txt_output"
outPathScriptTXT <- "/script_txt_output"
outPathSAFE <- "/downloaded" 

#### USER DEFINED USERNAME AND PASSWORD AS A TXT FILE ####
# 3) 
username_password <- "/copernicus_username_password.txt"

#### SCRIPT SLEEP TIME IN SECONDS, RECOMMENDED 24 HOURS ####
sleep_hours <- 24
sleep_seconds <- sleep_hours * 60 * 60 

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
####             INPUT VARIABLES        ####
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
####             START SCRIPT                      ####
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#read in txt file that has username and password
un_pw <- read.delim(username_password, header = T, sep = " ")
username <- un_pw[1,2]
password <- un_pw[2,2]

#read in txt file that has input CSV/output paths
in_out <- read.delim(input_output, header = T, sep = " ")
inFile <- in_out[1,2]
outPathWgetTXT <- in_out[2,2]
outPathScriptTXT <- in_out[3,2]
outPathSAFE <- in_out[4,2]

my_csv <- read.csv(inFile)
my_requested <- length(which(my_csv$status == "202 Accepted"))

my_counter <- 1

if (my_requested < 1) {
  paste0("No files to request. Either you are finished or you need to run the archived request script.")
  break()
}

while (my_requested != 0) {
  
  if (my_counter > 1) { 
    print(paste0("Sleeping for ", sleep_hours," hours, or ", sleep_seconds," seconds."))
    Sys.sleep(sleep_seconds)
  }
  
  #select uuid's to download that are currenlty PENDING 
  my_uuid <- read_csv(inFile)%>%
    filter(status %in% c("202 Accepted")) %>%
    mutate(uuid = as.character(uuid))

  #this gives the user a sanity check, makes sure the code is wget'ing in a UUID
  paste0("You are attempting to download the following UUIDs:")
  print(my_uuid$uuid)
  
  #sets the script to run all the UUIDs set to "202 Accepted" to try to download
  max_files <- length(my_uuid$uuid)

  #start by requesting the tiles/uuids, and repeat for the max_files 
  for (u in 1:max_files){
    
    #if u is past the first run, sleep for 1 day 
  
    filenameScript <- paste0(outPathScriptTXT,"/download_output_",my_uuid$title[u],".txt")
    filenameWget <- paste0(outPathWgetTXT,"/download_output_",my_uuid$title[u],".txt")
    
    system(paste0("wget --content-disposition --continue --user=",username," --password=",password," -o ",filenameWget," -N -P ",outPathSAFE," \"https://scihub.copernicus.eu/apihub/odata/v1/Products(\'",my_uuid$uuid[u],"\')/\\$value\""))
    
    new_status <- read_lines(outPathWgetTXT,skip = 0, skip_empty_rows = FALSE, n_max = -1L)
    new_status <- na.omit(str_extract(new_status, pattern = "(?:[:digit:]{3}[:space:])+[[:alpha:]$]+"))[3]
    
    ?readnew_timestamp_attempt <- format(Sys.time(), "%Y%m%d_%H%M%S")
    my_uuid$download_attempt[u] <- my_uuid$download_attempt[u] + 1
    
    #update the uuid's status to new_status
    my_uuid$status[u] <- new_status
    my_uuid$timestamp_attempt[u] <- new_timestamp_attempt
    
    #add the requested tiles, with new_status to entire CSV file
    my_csv <- read.csv(inFile)%>%
      slice(-c(my_uuid$X)) #remove all the rows that are now pending
    my_csv <- rbind(my_csv, my_uuid)%>%
      arrange(X)
    
    #save the csv with updated status
    #note it OVERWRITES the old CSV
    write_csv(my_csv, inFile)
    
  }
  sink(paste0(outPathScriptTXT,"/download_wget_script_output_",format(Sys.time(), "%Y%m%d_%H%M"),".txt"))
  #create a summary of the CSV for the user
  my_archived <- length(which(my_csv$status %in% c("archived", "403 Forbidden", "NA")))
  my_requested <- length(which(my_csv$status == "202 Accepted"))
  my_notfound <- length(which(my_csv$status == "500 Not Found"))
  my_downloaded <- length(which(my_csv$status == "200 OK"))

  #save the csv with updated status
  #note it OVERWRITES the old CSV
  paste0("Summary of CSV")
  paste0("UUIDs requested: ", my_requested)
  paste0("UUIDs  downloaded: ", my_downloaded)
  paste0("UUIDs still archived: ", my_archived) 
  paste0("UUIDs not found: ", my_notfound)
  paste0("You have finished attempting to download the Sentinel tiles.") 

  #tells the user if there are more files to be downloaded
  if (my_requested > 0) {
    paste0("Run this script again tomorrow, you still have ", my_requested, " to download")
  } else {
    paste0("You finished downloading all your files since your requested/'202 Accepted' UUIDs is ", my_requested,".")
  }
  
  my_counter <- my_counter + 1
  paste0("This script has run ", my_counter, " times.")
  
  sink()
  
}
