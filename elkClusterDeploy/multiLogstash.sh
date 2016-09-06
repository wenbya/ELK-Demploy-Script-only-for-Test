#
# This shell help you install logstash 
# also with the configuration with encode64 
# 
# Author Wenbo Yang 
# you can copy and modify yourself for the better use of your own 

### go as root
if [ "${UID}" -ne 0 ];
then
    echo "You must be root to run this program." >&2
    exit 3
fi
########################## Auxiliary functions ##########################
## give a log in system so as to view the installation process but also check the error installation point
log()
{
	echo "$1"
	logger "$1"
}

## option parameter. this the parameter is only configuration encode64 string
help()
{
	echo "Parameters:"
	echo "e - The encoded configuration string."
	echo ""
}
while getopts e: optname; do
    log "Option $optname set with value ${OPTARG}"
  case $optname in
    e)  #set the encoded configuration string
	  log "Setting the encoded configuration string"
      CONF_FILE_ENCODED_STRING=${OPTARG}
      ;;
    \?) #unrecognized option - show help
      echo -e \\n"Option -${BOLD}$OPTARG${NORM} not allowed."
      help
      exit 2
      ;;
  esac
done

########################## Install functions  ###########################
##  install java
install_java()
{
	sudo add-apt-repository -y ppa:webupd8team/java
	sudo apt-get -y update  > /dev/null
	echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
	echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections
	sudo apt-get -y install oracle-java8-installer > /dev/null	
	log "java8 has been installed"
}

## install logstash
install_logstash()
{
	# Install Logstash
	# The Logstash package is available from the same repository as Elasticsearch . Install the public  key.
	# Create the logstash source list
	wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
	echo 'deb http://packages.elastic.co/logstash/2.2/debian stable main' | sudo tee /etc/apt/sources.list.d/logstash-2.2.x.list
	sudo apt-get update
	sudo apt-get install logstash
	log "logstash has been installed"
}

## configure logstash 
configure_logstash()
{
	# Install User Configuration from encoded string 
	# The configuration file is in /etc/logstash/logstash.conf
	log "Decoding configuration string"
	log "$CONF_FILE_ENCODED_STRING"
	echo $CONF_FILE_ENCODED_STRING > logstash.conf.encoded
	DECODED_STRING=$(base64 -d logstash.conf.encoded)
	log "$DECODED_STRING"
	echo $DECODED_STRING > ~/logstash.conf
	log "Installing user configuration named logstash.conf"
	sudo \cp -f ~/logstash.conf /etc/logstash/conf.d/
	log "configuration has been done"
}

## start / boot  logstash
start_logstash()
{
	log "Configure start up service"
	sudo update-rc.d logstash defaults 96 9
	sudo service logstash start
}

################################# Run the functions #############################

log "begin to install java8"
install_java

log "begin to install logstash"
install_logstash

log "begin to  configure logstash"
configure_logstash

log "start logstash and set auto-start"
start_logstash

################################# Done ################################### 
# you can also install logstash plugin in this script

