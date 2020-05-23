To create the AMI from the template, update the variables.json file with your access and secret key and then run the command:
packer build -var-file=variables.json ubuntu_web_server.json
