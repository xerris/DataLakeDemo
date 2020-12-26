import * as s3 from '@aws-cdk/aws-s3'
import * as iam from '@aws-cdk/aws-iam'
import * as kineses from '@aws-cdk/aws-kinesisfirehose'
import * as cdk from '@aws-cdk/core';

export class LakeStack extends cdk.Stack {
  constructor(scope: cdk.App, id: string, props?: cdk.StackProps) {
    super(scope, id, props);


    const myBucket = new s3.Bucket(this, "my-lake-landing", {
      removalPolicy: cdk.RemovalPolicy.DESTROY
   });

   const customRole = new iam.Role(this, 'firehoseS3Access', {
    roleName: 'firehoseS3Access',
    assumedBy: new iam.ServicePrincipal('firehose.amazonaws.com'),
    managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName("AmazonS3FullAccess")
    ]
})

   const firehoseDelivery = new kineses.CfnDeliveryStream(this, "firehoseLake", {
    deliveryStreamName: "FirehoseDelivery",
    s3DestinationConfiguration: {
      bucketArn: myBucket.bucketArn,
      roleArn: customRole.roleArn,
      bufferingHints:{
        intervalInSeconds: 60
      }
    }

   })
  myBucket.grantWrite(customRole)
  }
}
