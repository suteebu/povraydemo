
#DTG_NOW=`date +%FT%H:%M:%S`
#echo "Time now is"
#echo $DTG_NOW
#echo "Getting spot price history:"
#ec2-describe-spot-price-history -H --instance-type m1.xlarge --start-time $DTG_NOW --filter product-description='Linux/UNIX (Amazon VPC)'

ec2-request-spot-instances ami-26c44c16 -p 0.10 --key stepheekey3 --group default --instance-type m1.xlarge --instance-count 100 --type one-time --user-data "/home/ubuntu/.rvm/rubies/ruby-1.9.3-p327/bin/ruby /home/ubuntu/povraydemo/povraydemo-client.rb"  --region us-west-2