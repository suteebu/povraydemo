#!/bin/bash
set -e -x
EMAIL=suteebu@gmail.com

# Get some information about the running instance
instance_id=$(wget -qO- instance-data/latest/meta-data/instance-id)
public_hostname=$(wget -qO- instance-data/latest/meta-data/public-hostname)

# Send status email
/usr/sbin/sendmail -oi -t -f $EMAIL <<EOF
From: $EMAIL
To: $EMAIL
Subject: Running POV-Ray Demo Client

This email was generated on the EC2 instance: $instance_id
SSH into: ubuntu@$public_hostname

EOF

#cd /home/ubuntu/povraydemo
ruby /home/ubuntu/povraydemo/povraydemo-client.rb
