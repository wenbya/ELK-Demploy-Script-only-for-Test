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
while getopts n: optname; do
    log "Option $optname set with value ${OPTARG}"
  case $optname in
    n)  #set the encoded configuration string
	  log "Setting the VM Name"
      VMNAME=${OPTARG}
      ;;
    \?) #unrecognized option - show help
      echo -e \\n"Option -${BOLD}$OPTARG${NORM} not allowed."
      help
      exit 2
      ;;
  esac
done

#install java8
log "begin install java8"
sudo add-apt-repository -y ppa:webupd8team/java
sudo apt-get -y update  > /dev/null
echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections
sudo apt-get -y install oracle-java8-installer > /dev/null
log "java8 has been installed"
#
mkdir /opt/elk
cd /opt/elk
#install elasticsearch
log "begin install elasticsearch"
wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -

echo "deb http://packages.elastic.co/elasticsearch/2.x/debian stable main" | sudo tee -a /etc/apt/sources.list.d/elasticsearch-2.x.list

sudo apt-get update

sudo apt-get -y install elasticsearch

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

sudo service elasticsearch restart
sudo update-rc.d elasticsearch defaults 95 10

log "elasticsearch has been installed"

#install elasticsearch plugin

cd /usr/share/elasticsearch/
sudo bin/plugin install lmenezes/elasticsearch-kopf
sudo bin/plugin install mobz/elasticsearch-head
sudo bin/plugin install license
sudo bin/plugin install watcher
#install marvel part0
sudo bin/plugin install marvel-agent
cd 
#install kibana
log "begin to install kibana"
echo "deb http://packages.elastic.co/kibana/4.4/debian stable main" | sudo tee -a /etc/apt/sources.list.d/kibana-4.4.x.list

sudo apt-get update

sudo apt-get -y install kibana

#configure kibana
# take care of the server.host name  
sudo echo "server.host: '$VMNAME'" >> /opt/kibana/config/kibana.yml
sudo echo "elasticsearch.url: 'http://$VMNAME:9200'" >> /opt/kibana/config/kibana.yml
sudo update-rc.d kibana defaults 96 9
sudo service kibana start
#install marvel part1 . marvel need to be installed after kibana was done.
sudo bin/kibana plugin --install elasticsearch/marvel/2.1.0
log "kibana has been installed"
