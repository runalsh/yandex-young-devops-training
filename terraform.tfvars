
region = "eu-central-1"
domain = "aws.runalsh.ru"
prefix = "bingogogo"
studentemail = "shaidullin2@gmail.com"

#app instance (using autoscaling group)
app_instance_type = "t2.micro" #"c5a.xlarge"  ## "t2.micro" # https://eu-central-1.console.aws.amazon.com/ec2/home?region=eu-central-1#LaunchInstances:
app_desired_intsances = 2
app_minimum_instances = 2
app_maximum_instances = 2

#app instance (single instances)
app_si_instance_type = "t2.micro"
app_si_instances = 2
app_si_ip_internal = "10.0.0.24"

#balancer instancer
lb_instance_type = "t3.medium" #"c5a.xlarge" 

#monirtoing instancer
mon_instance_type = "t3.medium"

#database instance
db_ec2instance_type = "t2.micro"
database_ip_internal = "10.0.0.250" #must be from subnet0, rn - 10.0.0.0/24
dbname = "bingodatabase"
dbuser = "bingouser"
dbpassword = "bingouser"

#RDS
db_instance_type    = "db.t3.micro"
db_instance_name    = "dbforbingo"



