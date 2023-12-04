
region = "eu-central-1"
domain = "aws.runalsh.ru"
prefix = "bingogogo"
studentemail = "shaidullin2@gmail.com"

#app instance (using autoscaling group)
app_instance_type = "t2.micro" #"c5a.xlarge"  ## "t2.micro" # https://eu-central-1.console.aws.amazon.com/ec2/home?region=eu-central-1#LaunchInstances:
app_desired_intsances = 2
app_minimum_instances = 2
app_maximum_instances = 2

#balancer instancer
lb_instance_type = "t3.medium" #"c5a.xlarge" 

#database instance
db_ec2instance_type = "t2.micro"
dbname = "bingodatabase"
dbuser = "bingouser"
dbpassword = "bingouser"

