#
# This shell  helps you install mulity node elastcisearch cluster
#
#
# Modified from "https://github.com/Azure/azure-diagnostics-tools/blob/master/ES-MultiNode/es-ubuntu-install.sh"
# make it simple for my scenario
# Author Wenbo Yang 
# you can copy and modify yourself for the better use of your own

## error out if uninitialized variable is used
#set -u  
## go as root 
if [ "${UID}" -ne 0 ];
then
    echo "You must be root to run this program." >&2
    exit 3
fi
################################################# Auxiliary functions########################################
## give option parameters (need to be test)
while getopts n:d:c: optname; do    
  case $optname in
    n) 
      cluster_name=${OPTARG}
      ;;
    d) 
      starting_discovery_endpoint=${OPTARG}
      ;;
    c)
      cluster_node_count=${OPTARG}
      ;;
  esac
done
## give the mulity node  IP 
get_discovery_endpoints()
{
    declare start_address=$1
    declare address_prefix=${start_address%.*}     # Everything up to last dot (not including)
    declare -i address_suffix_start=${start_address##*.}  # Last part of the address, interpreted as a number
    declare retval='['
    declare -i i
    declare -i suffix
    
    for (( i=0; i<$2; ++i )); do
        suffix=$(( address_suffix_start + i ))
        retval+="\"${address_prefix}.${suffix}\", "
    done
    
    retval=${retval:0:-2}               # Remove last comma and space
    retval+=']'
    
    echo $retval
}
## give a log . easy to view installation process
log()
{
	echo "$1"
	logger "$1"
}
################################################ install java ######################################################  
install_java()
{
	sudo add-apt-repository -y ppa:webupd8team/java
	sudo apt-get -y update  > /dev/null
	echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
	echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections
	sudo apt-get -y install oracle-java8-installer > /dev/null
	log "java8 has been installed"
}
############################################  Elasticsearch  Functions   ############################################
####### install Elaticsearch
install_elasticsearch()
{
	wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
	echo "deb http://packages.elastic.co/elasticsearch/2.x/debian stable main" | sudo tee -a /etc/apt/sources.list.d/elasticsearch-2.x.list
	sudo apt-get update
	sudo apt-get -y install elasticsearch
	log "elasticsearch has been installed"
}
####### configure elasticsearch. set /etc/elasticsearch/elasticsearch.yml
configure_elasticsearch()
{
	## prepare for elasticsearch
	#cluster_name="elasticsearch"
	#starting_discovery_endpoint="10.0.0.4"
	#declare -i cluster_node_count=2
	mkdir /opt/elk
	cd /opt/elk
	echo "#################### Configuring ES service ####################"
	echo "cluster.name: $cluster_name" >> /etc/elasticsearch/elasticsearch.yml
	echo "node.name: ${HOSTNAME}" >> /etc/elasticsearch/elasticsearch.yml
	echo "gateway.expected_nodes: ${cluster_node_count}" >> /etc/elasticsearch/elasticsearch.yml
	echo 'discovery.zen.ping.multicast.enabled: false' >> /etc/elasticsearch/elasticsearch.yml
	discovery_endpoints=$(get_discovery_endpoints $starting_discovery_endpoint $cluster_node_count)
	echo "Setting ES discovery endpoints to $discovery_endpoints"
	echo "discovery.zen.ping.unicast.hosts: $discovery_endpoints" >> /etc/elasticsearch/elasticsearch.yml
	echo "path.data: $datapath_config" >> /etc/elasticsearch/elasticsearch.yml
	declare -i minimum_master_nodes=$(((cluster_node_count / 2) + 1))
	echo "discovery.zen.minimum_master_nodes: $minimum_master_nodes" >> /etc/elasticsearch/elasticsearch.yml
	echo "gateway.recover_after_time: 1m" >> /etc/elasticsearch/elasticsearch.yml
	echo "bootstrap.mlockall: true" >> /etc/elasticsearch/elasticsearch.yml
	echo "node.master: true" >> /etc/elasticsearch/elasticsearch.yml
	echo "node.data: true" >> /etc/elasticsearch/elasticsearch.yml
	log "elastcisearch.yml has been modified"
}
####### set elasticsearch heap Memory/2
optimizing_elasticsearchHeap()
{	
	es_heap_size=$(free -m |grep Mem | awk '{if ($2/2 >31744)  print 31744;else print $2/2;}')
	printf "\nES_HEAP_SIZE=%sm\n" $es_heap_size >> /etc/default/elasticseach
	printf "MAX_LOCKED_MEMORY=unlimited\n" >> /etc/default/elasticsearch
	echo "elasticsearch - nofile 65536" >> /etc/security/limits.conf
	echo "elasticsearch - memlock unlimited" >> /etc/security/limits.conf
	log "es_heap_size has been set"
}
####### set elasticsearch Boot 
boot_elasticsearch()
{
	sudo service elasticsearch restart
	sudo update-rc.d elasticsearch defaults 95 10	
	log "elasticsearch has been restarted"
}
####### install elasticsearch plugin such as (head,kopf,marvel) marvel need to be installed after Kibana 
install_plugins()
{
	cd /usr/share/elasticsearch/
	sudo bin/plugin install lmenezes/elasticsearch-kopf
	sudo bin/plugin install mobz/elasticsearch-head
	sudo bin/plugin install license
	sudo bin/plugin install watcher
	sudo bin/plugin install marvel-agent
	cd /opt/kibana
	sudo bin/kibana plugin --install elasticsearch/marvel/2.1.0
	log "elasticsearch plugin has been installed"
}
########################################## Kibana functions ##################################################
install_kibana()
{	
	echo "deb http://packages.elastic.co/kibana/4.4/debian stable main" | sudo tee -a /etc/apt/sources.list.d/kibana-4.4.x.list
	sudo apt-get update
	sudo apt-get -y install kibana
	#configure kibana 	  
	sudo echo "server.host: '${HOSTNAME}'" >> /opt/kibana/config/kibana.yml
	sudo echo "elasticsearch.url: 'http://${HOSTNAME}:9200'" >> /opt/kibana/config/kibana.yml
	sudo update-rc.d kibana defaults 96 9
	sudo service kibana start
	log "kibana has been installed"
}

########################################## Begion to rull  the functions to deploy Elasticsearch+Kibana #######
# configure data disks for Elasticsearch
# you must use fileUri vm-disk-utils-0.1.sh
##
log "setting up data disk"
bash vm-disk-utils-0.1.sh
log "disk is OK"

#install java
log "begin to install java8"
install_java

#install elasticsearch
log "begin to install elastcisearch"
install_elasticsearch

#elastcisearch Datapath set
datapath_config=""
if [ -d '/datadisks' ]; then
    for disk_id in `find /datadisks/ -mindepth 1 -maxdepth 1 -type d`
    do
        # Configure disk permissions and folder for storage
        # We rely on ES default user name & group (elasticsearch)
        mkdir -p "${disk_id}/elasticsearch/data"
        chown -R elasticsearch:elasticsearch "${disk_id}/elasticsearch"
        chmod 755 "${disk_id}/elasticsearch"
        # Add to list for elasticsearch configuration
        datapath_config+="${disk_id}/elasticsearch/data,"
    done
    #Remove the extra trailing comma
    datapath_config="${datapath_config%?}"
else
    echo "Data disk directory not found, cannot set up storage for ElasticSearch service"
    exit 4
fi
log "disk has been set"

#configure elsticsearch
log "begin to configure elasticsearch"
configure_elasticsearch

#set elasticsearch heap
log "optimizing the elasticsearch heap"
optimizing_elasticsearchHeap

#start elasticsearch
log "begin to restart and boot elasticsearch"
boot_elasticsearch

#install kibana (contain boot configuration)
log "begin to install kibana"
install_kibana

#install elastcisearch plugins (marvel agent need to be installed after kibana)
log "begin to install elasticsearch plugins"
install_plugins

