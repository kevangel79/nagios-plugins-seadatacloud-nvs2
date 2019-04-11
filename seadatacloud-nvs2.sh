#!/bin/bash

TIMEOUT=10 # default connection timeout 10 seconds
#URI="http://vocab.nerc.ac.uk/collection"
#DUMMY_STRING="Oregon State Coastal Management Program"

#################################################################
# function for help message
usage () {
cat <<EOF
Usage: $me [options]
Script to check endpoint HTTP Status, Validity of XML code and String existance
 
Options:
  -u, --uri <URI>			Define endpoint URI to check.
  -d, --dummy <STRING>			Define string to search for.
  -t, --connect-timeout	<seconds> 	Maximum time allowed for connection (default: 10s)
  -h, --help				Print this help text.
EOF
}

##################################################################
# function for parsing arguments
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -u|--uri)
    URI="$2"
    shift # past argument
    shift # past value
    ;;
    -d|--dummy)
    DUMMY="$2"
    if [ -z "$DUMMY" ] || [[ "$DUMMY" =~ ^-.* ]]
      then
        echo "CRITICAL - No DUMMY STRING is defined | CRITICAL - No DUMMY STRING is defined"
	shift
        exit 3
    fi
    shift # past argument
    shift # past value
    ;;
    -t|--connect-timeout)
    TIMEOUT="$2"
    if [ -z "$TIMEOUT" ] || [[ "$TIMEOUT" =~ ^-.* ]]
     then
  	TIMEOUT=10 	# if TIMEOUT is not set, but '-t' option is used, fall to default 10 seconds
        shift
    else
    shift # past argument
    shift # past value
    fi
    ;;
     -h|--help)
     usage; exit 3 ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

################################################################
# Check if required options are passed(empty or dash(-))
if [ -z "$URI" ] || [[ "$URI" =~ ^-.* ]]
  then
	echo "UNKNOWN - No URI is defined | UNKNOWN - No URI is defined"
       	exit 3
fi

if [ -z "$DUMMY" ] || [[ "$DUMMY" =~ ^-.* ]]
 then
	echo "UNKNOWN - No DUMMY STRING is defined | UNKNOWN - No DUMMY STRING is defined"
	exit 3
fi

if [ -z "$TIMEOUT" ] || [[ "$TIMEOUT" =~ ^-.* ]]
 then
        echo "UNKNOWN - No CONNECTION TIMEOUT is defined | UNKNOWN - No CONNECTION TIMEOUT is defined"
        exit 3
fi

################################################################
# Capture HTTP STATUS CODE in variable
STATUS=$(curl -IL  -w '%{http_code}\n' -s -o /dev/null ${URI} --connect-timeout ${TIMEOUT})

#CHECK if HTTP STATUS CODE is 200 or 000
if [ ${STATUS} -eq 200 ];then
#	echo "OK - HTTP STATUS CODE is ${STATUS} | http_status_code=${STATUS},"

	# Check if the XML CODE is valid and capture it in a variable
	VALID="$(xmlstarlet val -w ${URI} | grep -w valid)"
	# Capture the RETURN CODE of the above command in a variable
	VALID_GREPED=$(echo $?)
	# Check if the RETURN CODE is '0'
	if [ ${VALID_GREPED} -eq 0 ];then
#        	echo "OK - The XML code is VALID | xml_valid_code=0, "

		# Check if the DUMMY exists in the returned XML CODE
		DUMMY_EXIST=$(curl -L ${URI} -s --connect-timeout ${TIMEOUT} | fgrep "$DUMMY")
		DUMMY_GREPED=$(echo $?)

		if [ ${DUMMY_GREPED} -eq 0 ];then
		        echo "OK - HTTP STATUS CODE is ${STATUS} - The XML code is VALID - The DUMMY string exists | http_status_code=${STATUS}, xml_valid_code=0, dummy_str_exist=0 "
		        exit 0
		else
		        echo "CRITICAL - The DUMMY string does NOT exist | http_status_code=${STATUS}, xml_valid_code=0, dummy_string_existance=1"
		        exit 2
		fi


	else
        	echo "CRITICAL - The XML code is NOT valid | http_status_code=${STATUS}, xml_valid_code=1, "
        	exit 2
	fi

elif [ ${STATUS} -eq 000 ]; then
        echo "UNKNOWN - Connection Timeout | http_status_code=${STATUS},"
        exit 3
else
        echo "CRITICAL - HTTP STATUS CODE is ${STATUS} | http_status_code=${STATUS}, "
        exit 2
fi

