import boto3
session = boto3.Session(profile_name="saml")
sts = session.client("sts")
response = sts.assume_role(
    RoleArn="arn:aws:iam::975049908839:role/ManagementAccountDBOpsAdmin ",
    RoleSessionName="vnidhin"
)
print(response)