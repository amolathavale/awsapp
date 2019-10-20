# Module 1: IDE Setup and Static Website Hosting

![Architecture](/images/module-1/architecture-module-1.png)

**Services used:**
* [AWS Cloud9](https://aws.amazon.com/cloud9/)
* [Amazon Simple Storage Service (S3)](https://aws.amazon.com/s3/)

In this module, follow the instructions to create your cloud-based IDE on [AWS Cloud9](https://aws.amazon.com/cloud9/) and deploy the first version of the static Mythical Mysfits website.  [Amazon S3](https://aws.amazon.com/s3/) is a highly durable, highly available, and inexpensive object storage service that can serve stored objects directly via HTTP. This makes it wonderfully useful for serving static web content (html, js, css, media content, etc.) directly to web browsers for sites on the Internet.  We will utilize S3 to host the content for our Mythical Mysfits website.

### Getting Started

#### Sign In to the AWS Console
To begin, sign in to the [AWS Console](https://console.aws.amazon.com) for the AWS account you will be using in this workshop.

#### Cloning the Mythical Mysfits Workshop Repository

```
git clone -b python https://github.com/aws-samples/aws-modern-application-workshop.git
cd aws-modern-application-workshop
```

### Creating a Static Website in Amazon S3

#### Create an S3 Bucket and Configure it for Website Hosting
Next, we will create the infrastructure components needed for hosting a static website in Amazon S3 via the [AWS CLI](https://aws.amazon.com/cli/).

```
aws s3 mb s3://amol.digitek
```

Now that we have created a bucket, we need to set some configuration options that enable the bucket to be used for [static website hosting](https://docs.aws.amazon.com/AmazonS3/latest/dev/WebsiteHosting.html).  This configuration enables the objects in the bucket to be requested using a registered public DNS name for the bucket, as well as direct site requests to the base path of the DNS name to a selected website homepage (index.html in most cases):

```
aws s3 website s3://amol.digitek --index-document index.html
```

#### Update the S3 Bucket Policy

All buckets created in Amazon S3 are fully private by default.  In order to be used as a public website, we need to create an S3 [Bucket Policy](https://docs.aws.amazon.com/AmazonS3/latest/dev/example-bucket-policies.html) that indicates objects stored within this new bucket may be publicly accessed by anyone. Bucket policies are represented as JSON documents that define the S3 *Actions* (S3 API calls) that are allowed (or not not allowed) to be performed by different *Principals* (in our case the public, or anyone).

The JSON document for the necessary bucket policy is located at: `~/environment/aws-modern-application-workshop/module-1/aws-cli/website-bucket-policy.json`.  This file contains a string that needs to be replaced with the bucket name you've chosen (indicated with `REPLACE_ME_BUCKET_NAME`).  

```
aws s3api put-bucket-policy --bucket REPLACE_ME_BUCKET_NAME --policy file://module-1/aws-cli/website-bucket-policy.json
```

#### Publish the Website Content to S3

Now that our new website bucket is configured appropriately, let's add the first iteration of the Mythical Mysfits homepage to the bucket.  Use the following S3 CLI command that mimics the linux command for copying files (**cp**) to copy the provided index.html page locally from your IDE up to the new S3 bucket (replacing the bucket name appropriately).

```
aws s3 cp ~/module-1/web/index.html s3://amol.digitek/index.html
```


## Alternatively, use Terraform script module1.tf to build the infrastructure
```
terraform apply
```

#### Verify the Website Content

Now, open up your favorite web browser and enter one of the below URIs into the address bar.  One of the below URIs contains a '.' before the region name, and the other a '-'. Which you should use depends on the region you're using.


```
http://amol.digitek.s3-website.us-east-1.amazonaws.com
```

Congratulations, you have created the basic static Mythical Mysfits Website!

### Tear Down the AWS infra

To delete the stack after testing is done using terraform

```
terraform destroy
```

## A Note about Amazon CloudFront - Best Practice for Serving Websites on AWS ##

In order for this workshop to move you quickly past the static website portion of the Mythical Mysfits Website, we've had you make an S3 bucket publicly accessible.  While creating public S3 buckets is perfectly OK and typical for many applications... when creating a public-facing website on AWS, it is best practice for you to use [**Amazon CloudFront**](https://aws.amazon.com/cloudfront/) as the global Content Delivery Network (CDN) and public-facing endpoint for your site. 

Amazon CloudFront enables many different capabilities that are beneficial for public websites (decreased latency, global redundancy, integration with AWS Web Application Firewall, etc.) and even reduces the data transfer costs for a website when compared to having customers directly request data from S3.

But, because of it's global nature, creation of a new CloudFront distribution can take over 15 minutes in some cases before it's available across the globe. Because of that, we've decided to skip that step in this tutorial to move you along faster.  But if you are building a public website on your own, the use of CloudFront should be considered a requirement in order for best practices to be met.

That concludes Module 1.



## [AWS Developer Center](https://developer.aws)
