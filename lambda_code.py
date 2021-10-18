import json
import boto3

# The format of a schedule file is JSON and is a simple dictionary where
# the keys are instance ids and the values are the schedule.  For example:
#
# {
#   "i-0123456789": "00:00-08:00",
#   "i-7890123456": "16:00-02:00"
# }
#
# That would say to run the instance that ends in "9" from midnight to 8
# each day (GMT) and to run the instance that ends in "6" from 8 pm to 2
# am each day (so it spans midnight GMT).

def get_schedule(event):

    # Extract the bucket name and object key from the event.
    bucket = event['Records'][0]['s3']['bucket']['name']
    object = event['Records'][0]['s3']['object']['key']

    # Download the file from S3 to local storage.
    s3 = boto3.client('s3')
    s3.download_file(bucket, object, '/tmp/schedule.json')

    # Now that we've grabbed the file from S3 we can load it.
    with open('/tmp/schedule.json') as fp:
        schedule = json.load(fp)

    # We have now loaded the JSON file that contains a schedule into
    # a Python data structure that matches.
    return schedule


def lambda_handler(event, context):

    # Get the schedule that was uploaded.
    schedule = get_schedule(event)

    # The next thing to do is loop through all the EC2 instances,
    # to see if they match.  If a VM is in the schedule we update
    # a tag.  If not we clear the tag.
    ec2 = boto3.client('ec2')
    res = ec2.describe_instances()

    # I hate how AWS doesn't return a single list of instances,
    # but instead can spread them across "reservations".
    for reservation in res['Reservations']:
        for instance in reservation['Instances']:
            instance_id = instance['InstanceId']
            if instance_id in schedule.keys():
                ec2.create_tags(Resources=[instance_id], Tags=[{'Key': 'Schedule', 'Value': schedule[instance_id]}])
            else:
                ec2.delete_tags(Resources=[instance_id], Tags=[{'Key': 'Schedule'}])


if __name__ == '__main__':
    # Create a fake event for testing locally.
    event = {'Records': [{'s3': {'bucket': {'name': 'ece592-week7-bornmannc'}, 'object': {'key': 'schedule.json'}}}]}
    lambda_handler(event, None)

