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

sudo echo "network.host: elkSimple" >> /etc/elasticsearch/elasticsearch.yml
sudo echo "http.port: 9200" >> /etc/elasticsearch/elasticsearch.yml

sudo service elasticsearch restart
sudo update-rc.d elasticsearch defaults 95 10

log "elasticsearch has been installed"

#install elasticsearch plugin

cd /usr/share/elasticsearch/
sudo bin/plugin install lmenezes/elasticsearch-kopf
sudo bin/plugin install mobz/elasticsearch-head
sudo bin/plugin install license
sudo bin/plugin install watcher
sudo bin/plugin install marvel-agent
cd /opt/kibana
sudo bin/kibana plugin --install elasticsearch/marvel/2.1.0
#install kibana
log "begin to install kibana"
echo "deb http://packages.elastic.co/kibana/4.4/debian stable main" | sudo tee -a /etc/apt/sources.list.d/kibana-4.4.x.list

sudo apt-get update

sudo apt-get -y install kibana

#configure kibana
# take care of the server.host name  
sudo echo "server.host: 'elkSimple'" >> /opt/kibana/config/kibana.yml
sudo echo "elasticsearch.uri: 'http://elkSimple:9200'" >> /opt/kibana/config/kibana.yml
sudo update-rc.d kibana defaults 96 9
sudo service kibana start

log "kibana has been installed"

#install logstash
log "begin to install logstash"
echo 'deb http://packages.elastic.co/logstash/2.2/debian stable main' | sudo tee /etc/apt/sources.list.d/logstash-2.2.x.list
sudo apt-get update
sudo apt-get install logstash
cd /etc/logstash/conf.d
sudo touch test.conf

sudo echo "input { stdin { } }" >>test.conf
sudo echo "output { stdout { } }" >> test.conf

# service logstash configtest
sudo update-rc.d logstash defaults 96 9
sudo service logstash start
log "logstash has started"



