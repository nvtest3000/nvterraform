import boto3
 
def create_rds_instance():
    # Create a session using your AWS credentials
    session = boto3.Session(
        region_name='us-east-1'
    )
 
    # Create an RDS client
    rds_client = session.client('rds')
 
    try:
        response = rds_client.create_db_instance(
            DBInstanceIdentifier='nvdbinstance',
            MasterUsername='master',
            MasterUserPassword='password123',
            DBInstanceClass='db.t3.micro',
            Engine='postgres',
            AllocatedStorage=20,  # 20 GB
            BackupRetentionPeriod=2,  # Retain backups for 7 days
            MultiAZ=False,  # Single AZ deployment
            PubliclyAccessible=True,
            DBSubnetGroupName='default-vpc-009d2b0c8d27ac21c',
            Tags=[
                {
                    'Key': 'Name',
                    'Value': 'MyRDSInstance'
                },
            ]
        )
 
        print("Creating RDS instance...")
 
    except Exception as e:
        print(f"Error creating RDS instance: {e}")
        return
 
    print("RDS instance created successfully.")
    print(response)
 
if __name__ == '__main__':
    create_rds_instance()