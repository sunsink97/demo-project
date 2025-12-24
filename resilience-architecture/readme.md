- create entire infrastructure using modules. so if future project need to be updated with new resource, like new lambda or api gateway we can just reuse module. made with future additional improved in mind, hence modularised architechture.
- list of resiliency = s3 versioning, 2 factor authentication
        
- hosted using ec2 just to showcase resiliency on how i would build the infrastructure. the application can be anything that is hosted on ec2. choosing linux over windows for faster boot time.

- custom vpc. note to remember : default vpc automatically assign resources with public ip and -public internet. hence why we need to create custom vpc. this has been causing issue on aws docs automation as it create resource on default vpc even if we piobnt to pirvate 

Feature
-create lb, lb template etc
-enable multi az for ec2
-enable  global table for dynamo
-create ami for ec2 made by lb
-create weekly ec2 server patching based on tagging
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
-code deploy implementation

user open the webiste and a dashboard will show a metric. this is an application hosted on ec2. metric will show lambda trigger rate based on cloudwatch metric, will have a button in website to trigger the lambda so user can check if the metric is working or not

consider connecting free monitoring service using grafana or something just for showcase

reason for modules and non modules - this is demo project. said module will likely be not used in other project as i intend this a s a solo self contained demo. as such reasources like vpc are made non modularise, on vpc.tf in root folder to make it easy to read and check what config are on the vpc itsef insread on makling it a module which can make it harde to read


for ec2.tf == ideally create ami using self made instance golden template. but for this demo purposes, i use official publicly available ami. lets pretend ami-0b8b20b0a6f3ad5c6 is our golden ami template
           == this will reduce replicatable result, also reduce the change of ami breaking becuase auto update is enabled.
           == using self made ami, the idea is to apply weekly automatic patching on already available instance, 
           == as for the ami itslef, create another pipeline that sole purpose is to run an ami patching job once a mont to patch the base line ami so that ami newly createed does not use ami taht is too old.
           == botton line : having 2 pathing shcedule. 1 is for the already created ami, this happen weekly. trigger patching using tagging. then 2, is the manually triggered job that will patch the origin ami that will be used by auto scaling to create 
                            new instance if neededd  

                            this cover the scenarion in which  instance update break the application on weekly patching. the lb ami will still  have a 1 month old ami and will create a healthy instance from that after lb health check fail and will only break again if next week come, and the weekly patching job is running again.

user data are for demo purposes and does nothing effectively. usually filled with script that need to run before the instance is ready. for example join domain script, or hardening script , etc.

in this case of demo, user data is installed via amazon linux and only need to be enabled. however, if we create our own ami, make sure to add installation process on the user data.

ami-093a7f5fbae13ff67 <----- this ami is singapore region only



-change storage location for the function for resilience to be inside the module instead the lambda folder. this change is done to make the code easier


-adding sqs. just for demo purporses as there will be no real use in this project since it will only receice once or twice trigger as this is only used for dedmo

- use rest api instead of non rest to directly connect to sqs


12/24/2025 progress : 
-api --> sqs --> lambda --> dynamo counter is already working.
-still welcome to ngin x default. not yet deploy front end.

NEXT step :
-wire front end button so it will work and trigger api 