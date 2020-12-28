import * as s3 from '@aws-cdk/aws-s3'
import * as iam from '@aws-cdk/aws-iam'
import * as kineses from '@aws-cdk/aws-kinesisfirehose'
import * as cdk from '@aws-cdk/core';
import * as pinpoint from '@aws-cdk/aws-pinpoint';
import * as glue from '@aws-cdk/aws-glue';
import * as s3deploy from "@aws-cdk/aws-s3-deployment";

export class LakeStack extends cdk.Stack {
  constructor(scope: cdk.App, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    //LANDING
    //setup landing lake
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

    //setup firehose delivery to landing
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

    const customFireHoseRole = new iam.Role(this, 'pinpointFirehoseAccess', {
      roleName: 'pinpointFirehoseAccess',
      assumedBy: new iam.ServicePrincipal('pinpoint.amazonaws.com'),
      managedPolicies: [
          iam.ManagedPolicy.fromAwsManagedPolicyName("AmazonKinesisFirehoseFullAccess")
      ]
    })

    //setup event stream from pinpoint to firehose
    const eventStream = new pinpoint.CfnEventStream(this, "eventStream", {

      applicationId: "330daf0fb3a2484c93a5ce3b047664d3",
      destinationStreamArn: firehoseDelivery.attrArn,
      roleArn: customFireHoseRole.roleArn
    })


    //Tranformations
    //Setup Glue Database for initial crawl of data
    const landingDB = new glue.CfnDatabase(this, "landingDatabase",{
        catalogId: this.account,
        databaseInput:{
        name: "landingdb"
        }
    })

    //Setup crawler on landing data
    const landingCrawlers = new glue.CfnCrawler(this, "landingCrawlers", {
      targets: {
        s3Targets: [{path: "s3://" + myBucket.bucketName}]
      },
      role: "glueadmin",
      databaseName: "landingdb"
      
    })

    //Store spark script to flatten and transform data to parquet
    const sparkScriptBucket = new s3.Bucket(this, "sparkScriptBucket", {
      removalPolicy: cdk.RemovalPolicy.DESTROY
    });


    let deploy = new s3deploy.BucketDeployment(this, 'DeployFiles', {
      sources: [s3deploy.Source.asset('./spark')], 
      destinationBucket: sparkScriptBucket,
    });

    //Create temp bucket for glue job
    const glueJobTempBucket = new s3.Bucket(this, "glueJobTempBucket", {
      removalPolicy: cdk.RemovalPolicy.DESTROY
    });

    //Create a lake for the cleaner transformed data
    const transformedLake = new s3.Bucket(this, "transformedLake", {
      removalPolicy: cdk.RemovalPolicy.DESTROY
    });

    //Create glue job to transform data and store in new lake
    let job = new glue.CfnJob(this, "relationalizeJob",{
      role:  "glueadmin",
      glueVersion: "2.0",
      command:{
        name: "glueetl",
        pythonVersion: "3",
        scriptLocation: "s3://"+ sparkScriptBucket.bucketName +"/relationalize_spark.py"
      },
      defaultArguments:{
        "--glue_source_database": "landingdb",
        "--glue_source_table": "lakestack_mylakelanding6df26456_agqxvt1ngc70",
        "--glue_temp_storage": "s3://"+ glueJobTempBucket.bucketName,
        "--glue_relationalize_output_s3_path": "s3://" + transformedLake.bucketName
      }
    })

    //Setup Glue DB to catalog the new transformed data
    const transformedDB = new glue.CfnDatabase(this, "transformedDB",{
      catalogId: this.account,
      databaseInput:{
      name: "transformeddb"
      }
    })

    //Setup crawler to to crawl and catalog the transformed data
    const transformedCrawlers = new glue.CfnCrawler(this, "transformedCrawlers", {
      targets: {
        s3Targets: [{path: "s3://" + transformedLake.bucketName}]
      },
      role: "glueadmin",
      databaseName: "transformeddb"
      
    })
  }  
}
