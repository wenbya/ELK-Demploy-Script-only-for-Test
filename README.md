# ELK-Demploy-Script-only-for-Test
My test ELK Deployment
only for test
maybe will do some help when you want to deploy ELK in single VM


You can convert your logstash configuration to Base64 encoded in http://base64encode.net/
So that you can set the "encodedConfigString" in logstashParameter.json


such as:
input  {
  stdin {}
}
output {
  stdout { codec => rubydebug }
}

converted to encodedConfigString "aW5wdXQgIHsNCiAgc3RkaW4ge30NCn0NCm91dHB1dCB7DQogIHN0ZG91dCB7IGNvZGVjID0+IHJ1YnlkZWJ1ZyB9DQp9"

you can change your own configuration into encodedConfigString as a parameter in logstashParameter.json
