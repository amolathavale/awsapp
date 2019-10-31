provider "aws" {
  profile = "default"
  region  = "us-east-2"
}
resource "aws_vpc" "mainvpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "digitek-vpc"
  }
}
resource "aws_subnet" "PublicSubnet1" {
  vpc_id            = "${aws_vpc.mainvpc.id}"
  cidr_block        = "10.0.0.0/24"
  availability_zone = "us-east-2a"
  tags = {
    Name = "PublicSubnet1"
  }
}
resource "aws_subnet" "PublicSubnet2" {
  availability_zone = "us-east-2b"
  vpc_id            = "${aws_vpc.mainvpc.id}"
  cidr_block        = "10.0.1.0/24"
  tags = {
    Name = "PublicSubnet2"
  }
}
resource "aws_subnet" "PrivateSubnet1" {
  availability_zone = "us-east-2a"
  vpc_id            = "${aws_vpc.mainvpc.id}"
  cidr_block        = "10.0.2.0/24"
  tags = {
    Name = "PrivateSubnet1"
  }
}
resource "aws_subnet" "PrivateSubnet2" {
  availability_zone = "us-east-2b"
  vpc_id            = "${aws_vpc.mainvpc.id}"
  cidr_block        = "10.0.3.0/24"
  tags = {
    Name = "PrivateSubnet2"
  }
}

resource "aws_internet_gateway" "igw" {
    vpc_id = "${aws_vpc.mainvpc.id}"
  tags = {
    Name = "Digitek.IGW"
  }
}
resource "aws_route_table" "MainRouteTable" {
  vpc_id = "${aws_vpc.mainvpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw.id}"
  }
  tags = {
    Name = "MainRouteTable"
  }
}
resource "aws_route_table_association" "PublicSubnet1RouteAssociation" {
    route_table_id = "${aws_route_table.MainRouteTable.id}"
    subnet_id = "${aws_subnet.PublicSubnet1.id}"
}
resource "aws_route_table_association" "PublicSubnet2RouteAssociation" {
    route_table_id = "${aws_route_table.MainRouteTable.id}"
    subnet_id = "${aws_subnet.PublicSubnet2.id}"
}
resource "aws_nat_gateway" "NatGateway1" {
    allocation_id = "${aws_eip.NatIp1.id}" 
    subnet_id = "${aws_subnet.PublicSubnet1.id}"
}
resource "aws_nat_gateway" "NatGateway2" {
    allocation_id = "${aws_eip.NatIp2.id}" 
    subnet_id = "${aws_subnet.PublicSubnet2.id}"
}
resource "aws_route_table" "PrivateRouteTable1" {
  vpc_id = "${aws_vpc.mainvpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.NatGateway1.id}"
  }
  tags = {
    Name = "PrivateRouteTable"
  }
}
resource "aws_route_table" "PrivateRouteTable2" {
  vpc_id = "${aws_vpc.mainvpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.NatGateway2.id}"
  }
  tags = {
    Name = "PrivateRouteTable"
  }
}
resource "aws_eip" "NatIp1" {
    vpc = true
}
resource "aws_eip" "NatIp2" {
    vpc = true
}
resource "aws_vpc_endpoint" "DynamoDbEndpoint" {
    vpc_id = "${aws_vpc.mainvpc.id}"
    service_name = "com.amazon.us-east-2.dynamodb"
    route_table_ids = ["${aws_route_table.PrivateRouteTable1.id}", "${aws_route_table.PrivateRouteTable2.id}"]
    policy = "${aws_iam_policy.DynamoDBPolicy}"
}
resource "aws_iam_policy" "DynamoDBPolicy" {

    policy = <<EOF
{
        "Version": "2012-10-17",
        "Statement": [ {
            "Action": "*",
            "Effect": "Allow",
            "Principal": "*",
            "Resource": "*"
        }]
}
    EOF
}
resource "aws_security_group" "FargateContainerSecurityGroup" {
    vpc_id = "${aws_vpc.mainvpc.id}"
    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["10.0.0.0/16"]
    } 
    tags = {
        Name = "FargateContainerSecurityGroup"
    }
}
data "aws_iam_policy_document" "EcsServicePolicy" {
    statement {
        effect = "Allow"
        actions = [
                "ec2:AttachNetworkInterface",
               "ec2:CreateNetworkInterface",
               "ec2:CreateNetworkInterfacePermission",
               "ec2:DeleteNetworkInterface",
               "ec2:DeleteNetworkInterfacePermission",
               "ec2:Describe*",
               "ec2:DetachNetworkInterface",
               "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
               "elasticloadbalancing:DeregisterTargets",
               "elasticloadbalancing:Describe*",
               "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
               "elasticloadbalancing:RegisterTargets",
               "iam:PassRole",
               "ecr:GetAuthorizationToken",
               "ecr:BatchCheckLayerAvailability",
               "ecr:GetDownloadUrlForLayer",
               "ecr:BatchGetImage",
               "logs:DescribeLogStreams",
               "logs:CreateLogStream",
               "logs:CreateLogGroup",
               "logs:PutLogEvents"
        ]
        resources = ["*"]

    }
}

resource "aws_iam_role" "EcsServiceRole" {
    name = "EcsServiceRole"
    assume_role_policy = "${data.aws_iam_policy_document.EcsServicePolicy.json}"
}
data "aws_iam_policy_document" "AmazonECSTaskRolePolicy" {
    statement {
        effect = "Allow"
        actions = [
                "ecr:GetAuthorizationToken",
               "ecr:BatchCheckLayerAvailability",
               "ecr:GetDownloadUrlForLayer",
               "ecr:BatchGetImage",
               "logs:CreateLogStream",
               "logs:CreateLogGroup",
               "logs:PutLogEvents"
        ]
        resources = ["*"]
    }
    statement {
        effect = "Allow"
        actions = [
                "dynamodb:Scan",
               "dynamodb:Query",
               "dynamodb:UpdateItem",
               "dynamodb:GetItem"
        ]
        resources = ["arn:aws:dynamodb:*:*:table/MysfitsTable*"]
    }

}

resource "aws_iam_role" "ECSTaskRole" {
    name = "EcsServiceRole"
    assume_role_policy = "${data.aws_iam_policy_document.EcsServicePolicy.json}"
}

## NLB
resource "aws_lb" "digitek-nlb" {
    load_balancer_type = "network"
    name = "digitek-nlb"
    subnets = ["${aws_subnet.PublicSubnet1}", "${aws_subnet.PublicSubnet2}"]

}
resource "aws_lb_target_group" "DigitekLB-TargetGroup" {
    name = "DigitekLB-TargetGroup"
    port = 8080
    protocol = "TCP"
    target_type = "ip"
    vpc_id = "${aws_vpc.mainvpc.id}"
    health_check = {
        path = "/"
        interval = "10"
        protocol = "HTTP"
        threshold = 3
        unhealthy = 3

    }
}

resource "aws_lb_listener" "Digitek-LBListener" {
    load_balancer_arn = "${aws_lb.digitek-nlb.arn}"
    port = 80
    protocol = "TCP"
}
#aws elbv2 create-listener --default-actions TargetGroupArn=REPLACE_ME_NLB_TARGET_GROUP_ARN,Type=forward --load-balancer-arn REPLACE_ME_NLB_ARN --port 80 --protocol TCP