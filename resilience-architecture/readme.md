- create entire infrastructure using modules. so if future project need to be updated with new resource, like new lambda or api gateway we can just reuse module. made with future additional improved in mind, hence modularised architechture.
- list of resiliency = s3 versioning, 2 factor authentication
        
- hosted using ec2 just to showcase resiliency on how i would build the infrastructure. the application can be anything that is hosted on ec2. choosing linux over windows for faster boot time.

- custom vpc. note to remember : default vpc automatically assign resources with public ip and -public internet. hence why we need to create custom vpc. this has been causing issue on aws docs automation as it create resource on default vpc even if we piobnt to pirvate 

Feature
-enable multi az for ec2
-enable multi az for dynamo db
-create ami for lb
-creet weekly ec2 server patching based on tagging
-create custom pipeline to update ami with latest linux update. maybe create using git pipeline  to run code like i do it on PMI using jenkins. just run the system manager maintenance task 




architecture resource 
-ec2 (make simple apps so that it can be hosted in aws free service, need to setup user data to install nginx for webhosting)
-lambda
-vpc (apply best practice for resilience)
-api gateway (enable cloudwatch logging)
-cloudwatch
-s3 (mainly  store logging)
-cloudfront
-alb
-r53
-dynamo db -> to store lambda trigger. use dynamo becuase simple count keeping. for real project we need to decide weather rds or dynamo depending on needs

user open the webiste and a dashboard will show a metric. this is an application hosted on ec2. metric will show lambda trigger rate based on cloudwatch metric, will have a button in website to trigger the lambda so user can check if the metric is working or not

