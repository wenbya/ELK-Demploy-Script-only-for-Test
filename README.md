# ELK-Demploy-Script-only-for-Test
1.
My test ELK Deployment
only for test
maybe will do some help when you want to deploy ELK in single VM

2.
You can convert your logstash configuration to Base64 encoded in http://codepen.io/juliusl/pen/ZGJJQB
So that you can set the "encodedConfigString" in logstashParameter.json

such as:
input  {
  stdin {}
}
output {
  stdout { codec => rubydebug }
}

converted to encodedConfigString "aW5wdXQgIHsgICBzdGRpbiB7fSB9IG91dHB1dCB7ICAgc3Rkb3V0IHsgY29kZWMgPT4gcnVieWRlYnVnIH0gfQ=="
you can change your own configuration into encodedConfigString as a parameter in logstashParameter.json
