
#DTG_NOW=`date +%FT%H:%M:%S`
#echo "Time now is"
#echo $DTG_NOW
#echo "Getting spot price history:"
#ec2-describe-spot-price-history -H --instance-type c1.xlarge --start-time $DTG_NOW --filter product-description='Linux/UNIX (Amazon VPC)'

ec2-request-spot-instances ami-88ea62b8 -p 0.12 --region us-west-2 --key stepheekey3 --group default --instance-type c1.xlarge --instance-count 100 --type one-time --user-data-file povraydemo-client-startup.sh

ec2-request-spot-instances ami-88ea62b8 -p 0.12 --region us-west-2 --key stepheekey3 --group default --instance-type c1.medium --instance-count 100 --type one-time --user-data-file povraydemo-client-startup.sh

ec2-request-spot-instances ami-88ea62b8 -p 0.12 --region us-west-2 --key stepheekey3 --group default --instance-type m2.xlarge --instance-count 100 --type one-time --user-data-file povraydemo-client-startup.sh