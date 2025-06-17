# Amazon ECS Service Terraform Module

This Terraform module creates and manages an Amazon ECS service with associated resources including task definitions, security groups, load balancer target groups, and auto-scaling configurations.

## Prerequisites

Before using this module, ensure the following AWS resources exist in your environment:

### Required Infrastructure

1. **ECS Cluster**
   - An existing Amazon ECS cluster (can be EC2-based or Fargate)
   - The cluster must be in the same region where you plan to deploy the service

2. **Application Load Balancer (ALB)**
   - A configured Application Load Balancer
   - ALB listener with at least one HTTPS listener
   - The ALB must be in the same VPC as your ECS cluster

3. **KMS Key for Logging**
   - A KMS key with appropriate policies for CloudWatch Logs encryption
   - The key policy must allow the ECS service to encrypt/decrypt log data
   - Required permissions: `kms:Encrypt`, `kms:Decrypt`, `kms:ReEncrypt*`, `kms:GenerateDataKey*`, `kms:DescribeKey` for more info please visit [Set permissions on the KMS key](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/encrypt-log-data-kms.html#cmk-permissions)

4. **Network Infrastructure**
   - VPC with appropriate subnets (public/private based on your architecture)
   - Internet Gateway (for public subnets) or NAT Gateway (for private subnets)

5. **IAM Roles and Policies**
   - ECS Task Execution Role with necessary permissions
   - ECS Task Role (if your containers need AWS API access)
   - Appropriate policies attached to these roles

## Overall Platform Architecture

This module is designed to fit into a larger ecosystem that typically includes:

- **VPC**: Network isolation and security boundaries
- **Database**: RDS instances or other data storage solutions
- **Load Balancing**: Application Load Balancer for traffic distribution
- **Monitoring**: CloudWatch for logging and metrics
- **Security**: IAM roles, security groups, and KMS encryption
- **Service Discovery**: AWS Cloud Map for service-to-service communication

The module enables developers to deploy containerized applications that can scale automatically based on CPU utilization and integrate seamlessly with existing AWS infrastructure.

## Module Design & Usage

### Inputs

This reusable module accepts the following key inputs:

- **Project Configuration**: Project name, environment, AWS region
- **Container Configuration**: Image, CPU, memory, port mappings, environment variables
- **ECS Configuration**: Cluster ID, task family, desired count, launch type
- **Network Configuration**: VPC, subnets, security groups, load balancer settings
- **Auto-scaling Configuration**: Min/max capacity, CPU thresholds
- **Logging Configuration**: CloudWatch log groups, retention, KMS encryption

### Outputs

The module provides outputs for:

- ECS service ARN and name
- Task definition ARN
- Security group ID
- Target group ARNs
- CloudWatch log group name

### Self-Service Capabilities

This module enables development teams to:

- Deploy containerized applications without deep AWS knowledge
- Configure auto-scaling based on application needs
- Set up monitoring and logging automatically
- Integrate with existing load balancers and networking

## CI/CD Pipeline

### Application Deployment Pipeline

For product teams deploying applications:

1. **Build Stage**: Container image build and push to ECR
2. **Test Stage**: Automated testing of the application
3. **Deploy Stage**: Terraform apply with updated image tags
4. **Validation Stage**: Health checks and smoke tests

### Infrastructure Module Pipeline

For platform teams managing the module:

1. **Validation**: Terraform validate and plan
2. **Security Scanning**: Checkov, tfsec for security compliance
3. **Testing**: Terratest for infrastructure testing
4. **Documentation**: Automated README and documentation updates
5. **Release**: Semantic versioning and module registry publication

**Key Tools**: GitHub Actions, Terraform Cloud, Datadog for monitoring

## Security & Compliance

### Security Best Practices

This module enforces security best practices including:

- **Least Privilege**: IAM roles with minimal required permissions
- **Secure by Default**:
  - Encryption at rest using KMS
  - Flexibility to use encryption in transit for all communications
  - Private subnets for container workloads
  - Flexibility security groups for restrictive rules

### SOC 2 Compliance

The module supports SOC 2 compliance through:

- **Logging**: Comprehensive CloudWatch logging with encryption
- **Monitoring**: CloudWatch metrics and alarms for security events
- **Access Control**: IAM-based access control with audit trails
- **Data Protection**: KMS encryption for sensitive data
- **Network Security**: VPC isolation and security group controls

## Assumptions & Trade-offs

### Key Assumptions

1. **Single Container per Service**: The module is designed for single-container services
2. **Fargate Focus**: Optimized for AWS Fargate launch type
3. **ALB Integration**: Assumes Application Load Balancer for traffic routing
4. **CloudWatch Logging**: Uses CloudWatch Logs as the primary logging solution

### Design Trade-offs

1. **Simplicity vs. Flexibility**:
   - **Choice**: Simplified interface with sensible defaults
   - **Trade-off**: Less flexibility for complex multi-container scenarios

2. **Opinionated Defaults vs. Customization**:
   - **Choice**: Opinionated defaults for security and compliance
   - **Trade-off**: May require customization for specific use cases

3. **Auto-scaling Approach**:
   - **Choice**: CPU-based auto-scaling as default
   - **Trade-off**: May not be optimal for all application types

## Usage Example

```hcl
module "ecs_service" {
  source = "./path-to-this-module"

  # Project Configuration
  project_name = "my-app"
  environment  = "production"
  aws_region   = "us-east-1"

  # ECS Configuration
  cluster_id    = "arn:aws:ecs:us-east-1:123456789012:cluster/my-cluster"
  task_family   = "my-app-production"
  task_cpu      = 512
  task_memory   = 1024
  desired_count = 2

  # Container Configuration
  container_name     = "my-app"
  container_image    = "123456789012.dkr.ecr.us-east-1.amazonaws.com/my-app:latest"
  container_cpu      = 256
  container_memory   = 512
  container_port     = 8080
  container_environment_variables = {
    "NODE_ENV" = "production"
    "PORT"     = "8080"
  }

  # Network Configuration
  vpc_id           = "vpc-12345678"
  subnets          = ["subnet-12345678", "subnet-87654321"]
  alb_listener_arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:listener/app/my-alb/1234567890123456/1234567890123456"

  # Auto Scaling
  scale_target_min_capacity = 1
  scale_target_max_capacity = 10
  max_cpu_threshold         = 70
  min_cpu_threshold         = 30

  # Logging
  log_retention_days = 30
  kms_key_id        = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_appautoscaling_policy.scale_down_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_policy) | resource |
| [aws_appautoscaling_policy.scale_up_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_policy) | resource |
| [aws_appautoscaling_target.scale_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_target) | resource |
| [aws_cloudwatch_log_group.ecs_log_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_metric_alarm.cpu_high](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.cpu_low](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_ecs_service.ecs_service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_task_definition.ecs_task](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_iam_policy.task_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.task_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.managed_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.task_role_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lb_listener_rule.main_alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule) | resource |
| [aws_lb_target_group.alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_security_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_service_discovery_private_dns_namespace.namespace](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/service_discovery_private_dns_namespace) | resource |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_service_discovery_dns_namespace.existing](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/service_discovery_dns_namespace) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alb_listener_arn"></a> [alb\_listener\_arn](#input\_alb\_listener\_arn) | ARN ALB Listener. | `string` | `"arn:aws:elasticloadbalancing:us-east-1:841162703316:loadbalancer/net/myprojectmy-workload-dev/18a9a0132121ceeb"` | no |
| <a name="input_alb_listener_rules"></a> [alb\_listener\_rules](#input\_alb\_listener\_rules) | n/a | <pre>map(map(object({<br/>    priority = number<br/>    conditions = list(object({<br/>      type   = string<br/>      values = list(string)<br/>      key    = optional(string)<br/>    }))<br/>  })))</pre> | n/a | yes |
| <a name="input_assign_public_ip"></a> [assign\_public\_ip](#input\_assign\_public\_ip) | Assign a public IP address to the ECS service. | `bool` | `false` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | The AWS region to deploy the resources. | `string` | `"us-east-1"` | no |
| <a name="input_compatibilities"></a> [compatibilities](#input\_compatibilities) | The launch types the task definition is compatible with. | `list(string)` | <pre>[<br/>  "FARGATE"<br/>]</pre> | no |
| <a name="input_container_cpu"></a> [container\_cpu](#input\_container\_cpu) | CPU units for the container | `number` | `256` | no |
| <a name="input_container_environment_variables"></a> [container\_environment\_variables](#input\_container\_environment\_variables) | Map of environment variables for the container | `map(string)` | `{}` | no |
| <a name="input_container_essential"></a> [container\_essential](#input\_container\_essential) | Whether the container is essential | `bool` | `true` | no |
| <a name="input_container_image"></a> [container\_image](#input\_container\_image) | Docker image for the container | `string` | `"public.ecr.aws/nginx/nginx:latest"` | no |
| <a name="input_container_memory"></a> [container\_memory](#input\_container\_memory) | Memory (in MiB) for the container | `number` | `512` | no |
| <a name="input_container_name"></a> [container\_name](#input\_container\_name) | Name of the container | `string` | `"nginx-svc"` | no |
| <a name="input_container_port"></a> [container\_port](#input\_container\_port) | Port that the container exposes | `number` | `80` | no |
| <a name="input_cooldown"></a> [cooldown](#input\_cooldown) | Cooldown period for scaling actions | `number` | `60` | no |
| <a name="input_desired_count"></a> [desired\_count](#input\_desired\_count) | The number of tasks to run. | `number` | `1` | no |
| <a name="input_ecs_cluster_id"></a> [ecs\_cluster\_id](#input\_ecs\_cluster\_id) | ECS cluster ID. | `string` | `"arn:aws:ecs:us-east-1:841162703316:cluster/myprojectmy-workload-dev-ecs-cluster"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Deployment Environment | `string` | `"development"` | no |
| <a name="input_exec_role_arn"></a> [exec\_role\_arn](#input\_exec\_role\_arn) | Execution role ARN. | `string` | `"arn:aws:iam::841162703316:role/ecs-myprojectmy-workload-dev-task-exec-iam-role"` | no |
| <a name="input_force_new_deployment"></a> [force\_new\_deployment](#input\_force\_new\_deployment) | This can be used to update tasks to use a newer Docker image with same image/tag combination (e.g. myimage:latest. | `bool` | `true` | no |
| <a name="input_health_check_path"></a> [health\_check\_path](#input\_health\_check\_path) | Path health\_check ALB | `string` | `"/health"` | no |
| <a name="input_host_port"></a> [host\_port](#input\_host\_port) | Host port to map to container port | `number` | `80` | no |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | The ARN of the KMS Key to use when encrypting log data. If not provided, logs will not be encrypted. | `string` | `null` | no |
| <a name="input_launch_type"></a> [launch\_type](#input\_launch\_type) | The launch type on which to run your ECS service. | `string` | `"FARGATE"` | no |
| <a name="input_log_retention_days"></a> [log\_retention\_days](#input\_log\_retention\_days) | Number of days to retain CloudWatch logs | `number` | `7` | no |
| <a name="input_managed_policies"></a> [managed\_policies](#input\_managed\_policies) | List of managed policy ARNs to attach to the ECS task role. | `list(string)` | <pre>[<br/>  "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"<br/>]</pre> | no |
| <a name="input_max_cpu_evaluation_period"></a> [max\_cpu\_evaluation\_period](#input\_max\_cpu\_evaluation\_period) | The number of periods over which data is compared to the specified threshold for max cpu metric alarm | `string` | `"3"` | no |
| <a name="input_max_cpu_period"></a> [max\_cpu\_period](#input\_max\_cpu\_period) | The period in seconds over which the specified statistic is applied for max cpu metric alarm | `string` | `"60"` | no |
| <a name="input_max_cpu_threshold"></a> [max\_cpu\_threshold](#input\_max\_cpu\_threshold) | Threshold for max CPU usage | `string` | `"85"` | no |
| <a name="input_min_cpu_evaluation_period"></a> [min\_cpu\_evaluation\_period](#input\_min\_cpu\_evaluation\_period) | The number of periods over which data is compared to the specified threshold for min cpu metric alarm | `string` | `"3"` | no |
| <a name="input_min_cpu_period"></a> [min\_cpu\_period](#input\_min\_cpu\_period) | The period in seconds over which the specified statistic is applied for min cpu metric alarm | `string` | `"60"` | no |
| <a name="input_min_cpu_threshold"></a> [min\_cpu\_threshold](#input\_min\_cpu\_threshold) | Threshold for min CPU usage | `string` | `"10"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | The app namespace to deploy the resources and local DNS. | `string` | `"my-workload"` | no |
| <a name="input_network_mode"></a> [network\_mode](#input\_network\_mode) | The Docker networking mode to use for the containers in the task. | `string` | `"awsvpc"` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Name of the project | `string` | `"my-workload"` | no |
| <a name="input_scale_target_max_capacity"></a> [scale\_target\_max\_capacity](#input\_scale\_target\_max\_capacity) | The max capacity of the scalable target | `number` | `5` | no |
| <a name="input_scale_target_min_capacity"></a> [scale\_target\_min\_capacity](#input\_scale\_target\_min\_capacity) | The min capacity of the scalable target | `number` | `1` | no |
| <a name="input_security_group_rules_cidrs"></a> [security\_group\_rules\_cidrs](#input\_security\_group\_rules\_cidrs) | Map of security group rules with CIDR block, port, and description | <pre>map(object({<br/>    cidr        = string<br/>    from_port   = number<br/>    to_port     = number<br/>    description = string<br/>    protocol    = string<br/>  }))</pre> | <pre>{<br/>  "http": {<br/>    "cidr": "10.0.0.0/24",<br/>    "description": "Allow HTTP from spicific CIDR or IP address",<br/>    "from_port": 80,<br/>    "protocol": "tcp",<br/>    "to_port": 80<br/>  },<br/>  "https": {<br/>    "cidr": "10.0.0.0/24",<br/>    "description": "Allow HTTPS from spicific CIDR or IP address",<br/>    "from_port": 443,<br/>    "protocol": "tcp",<br/>    "to_port": 443<br/>  },<br/>  "ssh": {<br/>    "cidr": "10.0.0.0/24",<br/>    "description": "Allow SSH from spicific CIDR or IP address",<br/>    "from_port": 22,<br/>    "protocol": "tcp",<br/>    "to_port": 22<br/>  }<br/>}</pre> | no |
| <a name="input_security_group_rules_prefix_list_id"></a> [security\_group\_rules\_prefix\_list\_id](#input\_security\_group\_rules\_prefix\_list\_id) | Map of security group rules with Prefix List, port, and description | <pre>map(object({<br/>    prefix_list_id = string<br/>    from_port      = number<br/>    to_port        = number<br/>    description    = string<br/>    protocol       = string<br/>  }))</pre> | <pre>{<br/>  "http": {<br/>    "description": "Allow HTTP from Cloudfront",<br/>    "from_port": 80,<br/>    "prefix_list_id": "pl-b6a144df",<br/>    "protocol": "tcp",<br/>    "to_port": 80<br/>  },<br/>  "https": {<br/>    "description": "Allow HTTPS from Cloudfront",<br/>    "from_port": 443,<br/>    "prefix_list_id": "pl-b6a144df",<br/>    "protocol": "tcp",<br/>    "to_port": 443<br/>  }<br/>}</pre> | no |
| <a name="input_security_group_rules_security_group_id"></a> [security\_group\_rules\_security\_group\_id](#input\_security\_group\_rules\_security\_group\_id) | Map of security group rules with Security Group Id, port, and description | <pre>map(object({<br/>    sec_group_id = string<br/>    from_port    = number<br/>    to_port      = number<br/>    description  = string<br/>    protocol     = string<br/>  }))</pre> | <pre>{<br/>  "http": {<br/>    "description": "Allow HTTP from XYZ resource",<br/>    "from_port": 443,<br/>    "protocol": "tcp",<br/>    "sec_group_id": "sg-0330684950b8346df",<br/>    "to_port": 443<br/>  },<br/>  "https": {<br/>    "description": "Allow HTTPS from XYZ resource",<br/>    "from_port": 443,<br/>    "protocol": "tcp",<br/>    "sec_group_id": "sg-0dcf4141c6f37d67f",<br/>    "to_port": 443<br/>  },<br/>  "ssh": {<br/>    "description": "Allow SSH from XYZ resource",<br/>    "from_port": 22,<br/>    "protocol": "tcp",<br/>    "sec_group_id": "sg-091f2edc4c7e88785",<br/>    "to_port": 22<br/>  }<br/>}</pre> | no |
| <a name="input_sns_topic_arn"></a> [sns\_topic\_arn](#input\_sns\_topic\_arn) | The ARN of an SNS topic to send notifications on alarm actions. | `string` | `""` | no |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | List of subnet IDs for the service. | `list(string)` | <pre>[<br/>  "subnet-0521aa00427d156e0",<br/>  "subnet-0854fca60e5b9ef64"<br/>]</pre> | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to assign to resources. | `map(string)` | `{}` | no |
| <a name="input_target_group_protocol"></a> [target\_group\_protocol](#input\_target\_group\_protocol) | Protocol for the Target Group: HTTP or HTTPS | `string` | `"HTTP"` | no |
| <a name="input_target_type"></a> [target\_type](#input\_target\_type) | Target type: instance, ip, lambda or alb. | `string` | `"ip"` | no |
| <a name="input_task_cpu"></a> [task\_cpu](#input\_task\_cpu) | The number of CPU units for the task. | `string` | `"512"` | no |
| <a name="input_task_family"></a> [task\_family](#input\_task\_family) | Family of the ECS task definition. | `string` | `"my-workload-nginx"` | no |
| <a name="input_task_memory"></a> [task\_memory](#input\_task\_memory) | The amount of memory (in MiB) to allocate for the task. | `string` | `"1024"` | no |
| <a name="input_task_role_policy"></a> [task\_role\_policy](#input\_task\_role\_policy) | IAM Policy document for the ECS task role in JSON format. | `string` | `"{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n    {\n      \"Effect\": \"Allow\",\n      \"Action\": [\n        \"logs:CreateLogStream\",\n        \"logs:PutLogEvents\"\n      ],\n      \"Resource\": \"arn:aws:logs:*:*:*\"\n    },\n    {\n      \"Effect\": \"Allow\",\n      \"Action\": [\n        \"ecs:DescribeTasks\",\n        \"ecs:UpdateTaskExecution\"\n      ],\n      \"Resource\": \"*\"\n    },\n    {\n      \"Effect\": \"Allow\",\n      \"Action\": [\n          \"application-autoscaling:*\",\n          \"ecs:DescribeServices\",\n          \"ecs:UpdateService\",\n          \"cloudwatch:DescribeAlarms\",\n          \"cloudwatch:PutMetricAlarm\",\n          \"cloudwatch:DeleteAlarms\",\n          \"cloudwatch:DescribeAlarmHistory\",\n          \"cloudwatch:DescribeAlarmsForMetric\",\n          \"cloudwatch:GetMetricStatistics\",\n          \"cloudwatch:ListMetrics\",\n          \"cloudwatch:DisableAlarmActions\",\n          \"cloudwatch:EnableAlarmActions\",\n          \"iam:CreateServiceLinkedRole\",\n          \"sns:CreateTopic\",\n          \"sns:Subscribe\",\n          \"sns:Get*\",\n          \"sns:List*\"\n      ],\n      \"Resource\": [\"*\"]\n    }\n  ]\n}\n"` | no |
| <a name="input_use_existing_namespace"></a> [use\_existing\_namespace](#input\_use\_existing\_namespace) | Indicates whether to use an existing Service Discovery namespace or create a new one | `bool` | `false` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID | `string` | `"vpc-0db92d66d4dd147da"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ecs_service_names"></a> [ecs\_service\_names](#output\_ecs\_service\_names) | Names of the ECS Services created |
| <a name="output_ecs_task_definition_arn"></a> [ecs\_task\_definition\_arn](#output\_ecs\_task\_definition\_arn) | ARN of the ECS Task Definition |
| <a name="output_sec_group_id"></a> [sec\_group\_id](#output\_sec\_group\_id) | ID of the Security Group |
