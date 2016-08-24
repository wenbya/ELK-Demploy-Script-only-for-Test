#install java8

echo "begin install"
logger "begin install"
sudo add-apt-repository -y ppa:webupd8team/java
sudo apt-get -y update  > /dev/null
echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections
sudo apt-get -y install oracle-java8-installer > /dev/null
echo "java8 has been installed"
logger "java8 has been installed"

#
mkdir /opt/elk
cd /opt/elk
#install elasticsearch
echo "begin install elasticsearch"
logger "begin install elasticsearch"
wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -

echo "deb http://packages.elastic.co/elasticsearch/2.x/debian stable main" | sudo tee -a /etc/apt/sources.list.d/elasticsearch-2.x.list

sudo apt-get update

sudo apt-get -y install elasticsearch

# configure the elasticsearch
#permission issues
sudo echo "network.host: MyUbuntuVM" >> /etc/elasticsearch/elasticsearch.yml
sudo echo "http.port: 9200" >> /etc/elasticsearch/elasticsearch.yml


sudo service elasticsearch restart
sudo update-rc.d elasticsearch defaults 95 10

echo "elasticsearch has been installed"
logger "elasticsearch has been installed"

#install elasticsearch plugin
#permission issues
cd /usr/share/elasticsearch/
sudo bin/plugin install lmenezes/elasticsearch-kopf
sudo bin/plugin install mobz/elasticsearch-head
sudo bin/plugin install license
sudo bin/plugin install watcher
sudo bin/plugin install marvel-agent
cd /opt/kibana
sudo bin/kibana plugin --install elasticsearch/marvel/2.1.0
#install kibana
echo "begin to install kibana"
logger "begin to install kibana"
echo "deb http://packages.elastic.co/kibana/4.4/debian stable main" | sudo tee -a /etc/apt/sources.list.d/kibana-4.4.x.list

sudo apt-get update

sudo apt-get -y install kibana

#configure kibana
sudo echo "server.host: "MyUbuntuVM"" >> /opt/kibana/config/kibana.yml
sudo echo "elasticsearch.uri: "http://MyUbuntuVM:9200"" >> /opt/kibana/config/kibana.yml


sudo update-rc.d kibana defaults 96 9
sudo service kibana start

echo "kibana has been installed"
logger "kibana has been installed"
#install logstash
echo "begin to install logstash"
logger "begin to install logstash"
echo 'deb http://packages.elastic.co/logstash/2.2/debian stable main' | sudo tee /etc/apt/sources.list.d/logstash-2.2.x.list

sudo apt-get update

sudo apt-get install logstash

cd /etc/logstash/conf.d

sudo touch test.conf

sudo echo "input { stdin { } }" >>test.conf
sudo echo "output { stdout { } }" >> test.conf

sudo service logstash configtest

sudo service logstash restart

sudo update-rc.d logstash defaults 96 9

sudo service logstash restart

echo "logstash has been installed"
logger "logstash has been installed"
