To get started:
- run: ruby povraydemo-server.rb
--> this queues up the iamges

when it starts polling for how many queue images are left:
- run: request_spot_instances.sh
- verify that these spot instances are starting by looking at aws console

when the SQS queue is empty:
- check povraydemo-server.rb output
- click any key to continue to generate movie
