#!/bin/bash

## Enter 'YES_I_AM' below to confirm you are ready for data to be deleted from the specified directory ##
ARE_YOU_SURE="NO_I_AM_NOT"                      
## Enter 'YES_I_AM' above to confirm you are ready for data to be deleted from the specified directory ##

## User-defined variables:
DELETION_SOURCE=$1                              # Directory path from where data will be deleted from
PERCENTAGE_DELETE=$2                            # Specify a figure between 1-100 to define the 
DELETION_TYPE="random"                          # Enter 'sequential' or 'random' to define the method of deleting files

#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
#                                                                               SCRIPT BLOCK                                                                                #
#                                           YOU SHOULD NOT NEED TO CHANGE ANYTHING FROM HERE-ON IN (UNLESS YOU PARTICULARLY WANT TO)                                        #
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------#

#### Function to capture errors:
error_captures() {
## Checking that 2 arguments have been passed to the script:
if [[ $# != "2" ]]
then 
    echo -e "\nERROR:\tIncorrect number of arguments provided.\vPlease execute the script with a directory path to the files and a (whole) percentage number of those files to be deleted (in that order):"
    echo -e "\n$ /path/to/script.sh /path/to/deletion/source 60\v"
    exit 1
fi

## Checking the target directory path from the first argument exists/is accessible:
if [[ ! -d $1 ]]
then
    echo -e "\nERROR:\tDeletion source directory does not exist - exiting...\v"
    exit 1
fi

## Checking to see whether the input included a percentage symbol:
PCT_SYMBOL=$(echo ${PERCENTAGE_DELETE: -1})
## If so, let's remove the symbol and just leave the integer:
if [[ ${PERCENTAGE_DELETE} == '%' ]]
then 
	PERCENTAGE_DELETE=$(echo ${PERCENTAGE_DELETE:0:-1})
fi

## Checking the input number is an integer:
if ! (($2)) 2> /dev/null 
then
    echo -e "\nERROR:\tThe value set in the variable \$\{PERCENTAGE_DELETE\} is not an integer - exiting...\v"
    exit 1
fi

## Checking the packages required for this script to call certain commands exist on the local machine:
REQUIRED_COMMANDS=( find echo shuf rm )
## Looping through the array above to check that the commands can be called:
if 
for CHECK_COMMAND in ${REQUIRED_COMMANDS[*]}
do
    if [[ -x $(command -v ${CHECK_COMMAND}) ]]
    then
        echo -e "\nERROR:\tThe command \'${CHECK_COMMAND}\' is either not installed or within \$PATH - exiting...\v"
        TERMINATE="true"
    fi
done
}

# Function to collect the information needed for the script to, well, function:
collect_information() {
ARRAY_ALL_FILES=( $(find ${DELETION_SOURCE} -type f) )
NUMBER_FILES=$(echo ${ARRAY_ALL_FILES[*]} | wc -w)
DELETABLE_NUMBER=$(( (${NUMBER_FILES} * ${PERCENTAGE_DELETE}) / 100 ))
}

# A function to initiate deletes using a random deletion method:
random_deletion() {
if [[ ${ARE_YOU_SURE} != "YES_I_AM" ]]
then
    echo -e "\vERROR:\tDeletion state is not confirmed (this needs to be set in the script) - exiting..."
    exit 1
fi

## Creating the variable array to keep track of the randomly generated nunbers, and the counter from which we will... 
## ...count down from (the number of files that are to be deleted):
declare -a DELETE_LOG
DELETABLE_TRACKER=${DELETABLE_NUMBER}
LAST_ELEMENT=$(( ${NUMBER_FILES} - 1 ))

## Looping back from top of the downward-counter:
until [[ ${DELETABLE_TRACKER} == "0" ]]
do
    ## Generate a random number between the first and last element in the array: 
    DELETE_STATE=$(shuf -i 0-${LAST_ELEMENT} -n 1)
    ## If this number hasn't already been generated: 
    if ! $(echo ${DELETE_LOG[*]} | grep ${DELETE_STATE} > /dev/null)
    then
        ## Trigger a deletion of the file at that element position as a background process:
            ## (Add a check to verify the deletion was successful?)
        rm ${ARRAY_ALL_FILES[${DELETE_STATE}]} &
        ## Add the element number to the delete log:
        DELETE_LOG[${#DELETE_LOG[@]}]="${DELETE_STATE}"
        ## Reduce the tracker by one:
        ((DELETABLE_TRACKER--))
    fi
done
}

sequential_deletion() {
## Making sure users are certain they are ready to proceed with the deletion script:
if [[ ${ARE_YOU_SURE} != "YES_I_AM" ]]
then
    echo -e "\vERROR:\tDeletion state is not confirmed (this needs to be set in the script) - exiting..."
    exit 1
fi

## Simply running through the eligible number of files to be deleted in sequence, starting from 0.
    ## (Add support for starting position through the file array?)
for SEQ_DEL_FILE in $(seq 0 ${DELETABLE_NUMBER})
do
    ## Trigger the deletion as a background process:
    rm ${ARRAY_ALL_FILES[$SEQ_DEL_FILE]} &
    ## Holding briefly, given the number of processes that could be created in quick succession:
    sleep 0.2
done
}

## Calling the funxctions:
error_captures
collect_information
${DELETION_TYPE}_deletion

## Prevent the script from terminating unfinished background processes:
wait

echo -e "\vDeletion job complete.\v"