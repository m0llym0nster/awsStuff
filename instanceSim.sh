#!/bin/bash
#molly@m0llym0nster.ninja

####Set variables for deployment: Will default if parameters not set####
subnet=subnet-04b5b2f95645dfb5a
secgrp=sg-0b585d6ba9289cdbe
numhosts=2
ami=ami-00a208c7cdba991ea
instrolearn=arn:aws:iam::310090471142:instance-profile/ec2-kms-instance-profile-pumped-reptile
keyname=e588-keypair
del=R
theday=$(date +"%Y%m%d-%H%m")
#awskeyprofile=lab22 add: --profile $awskeyprofile to the ec2 commands below

####Deploy instances###
function deployInstances
{
for i in $(seq 1 $numhosts)
    do
#        echo "aws ec2 run-instances --image-id $ami --iam-instance-profile Arn=$instrolearn --key-name $keyname --subnet-id $subnet --security-group-ids $secgrp"
#       if [ -f "studentSim.out" ] ; then
#               date >> instanceSim.out
#               cat instanceSim.out >> instanceSim.out.old
#               rm instanceSim.out
#       fi
aws ec2 run-instances --image-id $ami --iam-instance-profile Arn=$instrolearn --key-name $keyname --subnet-id $subnet --security-group-ids $secgrp | jq '.Instances[] | "\(.InstanceId)"' | tr -d '"' 2>&1 | tee -a instanceSim.out
    done

sleep 5
}

###Get Public IPs####
function getPublicIPs {
if [ -f "studentSim.ip.out" ] ; then
        date >> instanceSim.ip.out
fi
cat instanceSim.out | xargs -i aws ec2 describe-instances --instance-ids {} | jq '.Reservations[].Instances[] | "\(.InstanceId) \(.PublicIpAddress)"' | tr -d '"' 2>&1 | tee -a instanceSim.ip.out
}

####Delete instances####
function terminateInstances {
cat instanceSim.out | xargs -i aws ec2 terminate-instances --instance-ids {} | jq '.TerminatingInstances[] | "\(.InstanceId)"' | tr -d '"' 2>&1 | tee -a instanceSim.term.out.$theday
rm instanceSim.out instanceSim.ip.out
}

####usage####
function usage {
 echo "Usage: $0 -s=<subnet-a1111111> g=<sg-a0000000> -a=<ami-a000000> -r=<arn:aws:iam::310090471142:instance-profile/ec2-kms-instance-profile-pumped-reptile> -k=<Ec2keypairname> -d=<Y to delete, blank to run>"
}

###start main####

##get params##

for arg in "$@"
do

        case $arg in
                -s=*|-subnet=*)
                subnet="${arg#*=}"
                echo "$subnet"
                shift
                ;;
                -g=*|-secgrp=*)
                secgrp="${arg#*=}"
                shift
                ;;
                -a=*|-ami=*)
                ami="${arg#*=}"
                shift
                ;;
                -r=*|-role=*)
                instrolearn="${arg#*=}"
                shift
                ;;
                -k=*|-keypair=*)
                keyname="${arg#*=}"
                shift
                ;;
                -d=*|-del=*)
                del="${arg#*=}"
                shift
                ;;
                -n=*|-numhosts=*)
                numhosts="${arg#*=}"
                shift
                ;;
                -h | --help | ? )
                usage
                exit
                shift
                ;;
        esac
done


##echo stuff for testing###
#echo " subnet:$subnet securitygroup:$secgrp numberhosts:$numhosts amiid:$ami instrole:$instrolearn keypair:$keyname delete: $del"

##run stuff##
if [[ $del = "Y" || $del = "y" ]]
    then
#            echo "delete"
        terminateInstances
    else
#            echo "run"
        deployInstances
        getPublicIPs
fi

