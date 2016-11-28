## ELK 5.0 install in ARM
if [ "${UID}" -ne 0 ];
then
    echo "You must be root to run this program." >&2
    exit 3
fi
log()
{
	echo "$1"
	logger "$1"
}
# Set the VM name for the elasticsearch network.host 
# Set the host name instead of internal ip
while getopts n:e: optname; do
    log "Option $optname set with value ${OPTARG}"
  case $optname in
    n)  #set the encoded configuration string
	  log "Setting the VM Name"
      VMNAME=${OPTARG}
      ;;
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

#install java8
install_java()
{
log "begin install java8"
sudo add-apt-repository -y ppa:webupd8team/java
sudo apt-get -y update  > /dev/null
echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections
sudo apt-get -y install oracle-java8-installer > /dev/null
log "java8 has been installed"
}
#
install_elasticsearch()
{
#install elasticsearch
log "begin install elasticsearch"
#Download and install the public signing key:
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
#You may need to install the apt-transport-https package on Debian before proceeding:
sudo apt-get install apt-transport-https
#Save the repository definition to /etc/apt/sources.list.d/elastic-5.x.list:
echo "deb https://artifacts.elastic.co/packages/5.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-5.x.list

sudo apt-get update && sudo apt-get install elasticsearch
log "elasticsearch has been installed"
}

###
configureBoot_elasticsearch()
{
mkdir /opt/elk
cd /opt/elk
# configure the elasticsearch
sudo echo "bootstrap.mlockall: true" >> /etc/elasticsearch/elasticsearch.yml
sudo echo "network.host: $VMNAME" >> /etc/elasticsearch/elasticsearch.yml
sudo echo "http.port: 9200" >> /etc/elasticsearch/elasticsearch.yml
# configure elasticsearch heap
log "elasticsearch.yml has been configured . The elasticsearch heap begin to configure"
es_heap_size=$(free -m |grep Mem | awk '{if ($2/2 >31744)  print 31744;else print $2/2;}')
sudo printf "\nES_HEAP_SIZE=%sm\n" $es_heap_size >> /etc/default/elasticsearch
sudo printf "MAX_LOCKED_MEMORY=unlimited\n" >> /etc/default/elasticsearch
sudo echo "elasticsearch - nofile 65536" >> /etc/security/limits.conf
sudo echo "elasticsearch - memlock unlimited" >> /etc/security/limits.conf
log "es heap has been set"
#boot elasticsearch
sudo -i service elasticsearch restart
sudo update-rc.d elasticsearch defaults 95 10
log "elasticsearch has been started"
}

installConfig_kibana()
{
#install kibana
log "begin to install kibana"
echo "deb https://artifacts.elastic.co/packages/5.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-5.x.list
sudo apt-get update && sudo apt-get install kibana

#configure kibana
# take care of the server.host name
sudo echo "server.host: '$VMNAME'" >> /opt/kibana/config/kibana.yml
sudo echo "elasticsearch.url: 'http://$VMNAME:9200'" >> /opt/kibana/config/kibana.yml

sudo update-rc.d kibana defaults 96 9
sudo -i service kibana start
}

installConfig_logstash()
{
##install logstash
echo "deb https://artifacts.elastic.co/packages/5.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-5.x.list
sudo apt-get update && sudo apt-get install logstash

## config

log "Decoding configuration string"
log "$CONF_FILE_ENCODED_STRING"
echo $CONF_FILE_ENCODED_STRING > logstash.conf.encoded
DECODED_STRING=$(base64 -d logstash.conf.encoded)
log "$DECODED_STRING"
echo $DECODED_STRING > ~/logstash.conf

#log "Installing user configuration file"
log "Installing user configuration named logstash.conf"
sudo \cp -f ~/logstash.conf /etc/logstash/conf.d/

log "Configure start up service"
sudo update-rc.d logstash defaults 96 9
sudo -i service logstash start
}

## process to call the functions

install_java
install_elasticsearch
configureBoot_elasticsearch
installConfig_kibana
installConfig_logstash
