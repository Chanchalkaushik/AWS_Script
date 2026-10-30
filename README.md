This script helps you identify the correct AWS region using the EC2 DescribeInstances API. It automatically executes the command across multiple AWS regions and highlights the regions where the target's EC2 instances are running.
This script automatically validates Secret Access Key credentials before enumerating EC2 instances.
How to execute and use
First, save and set permissions:
```chmod +x AWS_Region_Enum_Ec2Describe.sh```
Now pass your AWS profile name during execution:
```./AWS_Region_Enum_Ec2Describe.sh <AWS_Profile>```
