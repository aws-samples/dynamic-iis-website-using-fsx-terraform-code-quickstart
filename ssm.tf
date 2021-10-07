data "template_file" "web_server_configs" {
  template = file("${path.module}/ssm_web_server_configs.yaml")
  vars = {
    DomainJoinCredentialSecretName = aws_secretsmanager_secret_version.mad_master_password.arn
    CloudWatchLogGroupName         = aws_cloudwatch_log_group.web_server_config.name
    automationAssumeRole           = aws_iam_role.web_server_config.arn
    HostnamePrefix                 = "web-srv"
    DomainJoinCredentialSecretName = local.DomainJoinCredentialSecretName
    FsxDnsName                     = aws_fsx_windows_file_system.fsx.dns_name
    WebSitePath                    = "share"
    IndexWebFile                   = "index.html"
    HtmlContent                    = "<html><h1>Sample WebSite</h1><img src=iisstart.png alt=IIS width=960 height=600/></html>"
    WebSiteName                    = "Sample WebSite"
    WebSitePort                    = "80"
    DefaultWebSiteName             = "Default Web Site"
  }
}

resource "aws_ssm_document" "ssm_web_server_config" {
  name            = format("%s-web-server-config", var.resource_prefix)
  document_type   = "Automation"
  content         = data.template_file.web_server_configs.rendered
  document_format = "YAML"
}

resource "aws_cloudwatch_log_group" "web_server_config" {
  name              = format("/aws/%s/web_server_config", var.resource_prefix)
  retention_in_days = 365
}

resource "aws_iam_role" "web_server_config" {
  name = format("%s-web-server-config-role", var.resource_prefix)
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ssm.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "web_server_config" {
  name = format("%s-web-server-config-policy", var.resource_prefix)
  role = aws_iam_role.web_server_config.id
  policy = jsonencode({
    "Version" = "2012-10-17"
    "Statement" = [{
      "Action" : [
        "ssm:DescribeAssociation",
        "ssm:GetDocument",
        "ssm:ListAssociations",
        "ssm:UpdateAssociationStatus",
        "ssm:UpdateInstanceInformation",
        "ssm:DescribeInstanceInformation",
        "ssm:CreateAssociation",
        "ssm:SendCommand",
        "ssm:ListCommands",
        "ssm:ListCommandInvocations",
        "autoscaling:CompleteLifecycleAction",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams",
        "logs:DescribeLogGroups"
      ],
      "Effect"   = "Allow"
      "Resource" = "*"
      },
      {
        "Effect" : "Allow",
        "Action" : "ec2:CreateTags"
        "Resource" : "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:instance/*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:DescribeTags",
          "ec2:DescribeInstances"
        ]
        "Resource" : "*"
      }
    ]
  })
}