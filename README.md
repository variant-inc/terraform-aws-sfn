# Terraform moduleName module

- [Terraform moduleName module](#terraform-modulename-module)
  - [Input Variables](#input-variables)
  - [Variable definitions](#variable-definitions)
    - [name](#name)
    - [tags](#tags)
    - [create_role](#create_role)
    - [role](#role)
    - [type](#type)
    - [definition_filename](#definition_filename)
    - [definition_variables](#definition_variables)
    - [logging_configuration](#logging_configuration)
    - [enable_tracing](#enable_tracing)
  - [Examples](#examples)
    - [`main.tf`](#maintf)
    - [`terraform.tfvars.json`](#terraformtfvarsjson)
      - [definition_variables example](#definition_variables-example)
      - [logging_configuration example](#logging_configuration-example)
    - [`state-machine.json`](#state-machinejson)
    - [`provider.tf`](#providertf)
    - [`variables.tf`](#variablestf)
    - [`outputs.tf`](#outputstf)

## Input Variables
| Name     | Type    | Default   | Example     | Notes   |
| -------- | ------- | --------- | ----------- | ------- |
| name | string |  | "test-sfn" |  |
| tags | map(string) | {} | {"environment": "prod"} | |
| create_role | bool | true | false |  |
| role | string | "" | "arn:aws:iam::319244236588:role/service-role/test-sfn-role" | required if `create_role` is `false` |
| type | string | "STANDARD" | "EXPRESS" |  |
| definition_filename | string | "state-machine.json" | "my-sfn.json" |  |
| definition_variables | map(any) | {} | `see below` | works together with definition file template |
| logging_configuration | any | {} | `see below` | supported only when `type` is `"EXPRESS"` |
| enable_tracing | bool | false | true |  |

## Variable definitions

### name
Name of the state machine.
Also used for naming role and log group if applicable.
```json
"name": "<Name>"
```

### tags
Tags for created bucket.
```json
"tags": {<map of tag keys and values>}
```

Default:
```json
"tags": {}
```

### create_role
Specifies should role be created with module or will there be external one provided.
```json
"create_role": <true or false>
```

Default:
```json
"create_role": true
```

### role
ARN of externally created custom role that we want to use with this SFN.
Required if `create_role` is set to `false`.
```json
"role": "<custom role ARN>"
```

Default:
```json
"role": ""
```

### type
Type of the State Machine.
```json
"type": "<STANDARD or EXPRESS>"
```

Default:
```json
"type": "STANDARD"
```

### definition_filename
Name of the file that contains definition or definition template for this SFN.
```json
"definition_filename": "<name of the file/template>"
```

Default:
```json
"definition_filename": "state-machine.json"
```

### definition_variables
Map of variables and their values to be used in the definition file.
```json
"definition_variables": {<map of variables and values>}
```

Default:
```json
"definition_variables": {}
```

### logging_configuration
Contains logging information.
Supported only when `type` is `"EXPRESS"`.
```json
"logging_configuration": {
  "level": "<OFF, ERROR, FATAL, ALL>",
  "include_execution_data": <true or false>,
  "log_destination": "<ARN of the CloudWatch group ending with :* or ommit/leave empty for module to create log group>",
  "log_retention": <number of days for log retention, supported only if module is creation the log group>,
  "log_kms_key": "<ARN of the KMS key used for log encryption, supported only if module is creation the log group>"
}
```

Default:
```json
"logging_configuration": {}
```

### enable_tracing
Enables AWS X-Ray tracing.
```json
"enable_tracing": <true or false>
```

Default:
```json
"enable_tracing": false
```

## Examples
### `main.tf`
```terarform
module "sfn" {
  source  = "github.com/variant-inc/terrafom-aws-sfn?refs=v1"

  name        = var.name
  tags        = var.tags
  create_role = var.create_role
  role        = var.role
  type        = var.type

  definition_filename   = var.definition_filename
  definition_variables  = var.definition_variables
  logging_configuration = var.logging_configuration
  enable_tracing        = var.enable_tracing
}
```

### `terraform.tfvars.json`
```json
{
  "name": "test-sfn",
  "tags": {
    "environment": "prod"
  },
  "create_role": true,
  "role": "",
  "type": "STANDARD",
  "definition_filename": "state-machine.json",
  "definition_variables": {},
  "logging_configuration": {}, 
  "enable_tracing": false
}
```

Basic
```json
{
  "name": "test-sfn"
}
```

#### definition_variables example
```json
{
  "test_lambda": "arn:aws:lambda:us-east-1:319244236588:function:lambda-test"
}
```

#### logging_configuration example
Precreated destination.
```json
{
  "level": "ERROR",
  "include_execution_data": true,
  "log_destination": "arn:aws:logs:us-east-1:319244236588:log-group:/aws/states/test-sfn-log-group:*"
}
```

No existing destination
```json
{
  "level": "ERROR",
  "include_execution_data": true,
  "log_retention": 0,
  "log_kms_key": "arn:aws:kms:us-east-1:319244236588:key/dfed962d-0968-42b4-ad36-7762dac7ca20"
}
```

Minimal
```json
{
  "level": "ERROR"
}
```

### `state-machine.json`
Example of variable usage for templating is in `Resource`.
```json
{
  "Comment": "A Hello World example of the Amazon States Language using an AWS Lambda Function",
  "StartAt": "HelloWorld",
  "States": {
    "HelloWorld": {
      "Type": "Task",
      "Resource": "${test_lambda}",
      "End": true
    }
  }
}
```

### `provider.tf`
```terraform
provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      team : "DataOps",
      purpose : "sfn_test",
      owner : "Luka"
    }
  }
}
```

### `variables.tf`
copy ones from module

### `outputs.tf`
```terraform
output "sfn_arn" {
  value       = module.sfn.sfn_arn
  description = "ARN of the Step Function."
}
```
