# This is the IAM role that the Lambda function will execute under.
# This is analogous to an EC2 instance role.  It defines the things
# the Lambda function is allowed to do.
resource "aws_iam_role" "lambda-iam-role" {
  name = "week7-lambda-iam-role"

  # In order for this role to be "assumed" by our function we need
  # to give Lambda permission to do so.  If you look back at the
  # Terraform you used to create the instance role in week5 (which
  # should be in your "automation" directory) you'll see we did
  # the same thing but instead of the Lambda service it was the EC2
  # service, because in that case it's a VM (managed by EC2) that
  # assumes the role.
  #
  # The "assume role policy" attached to a role doesn't say what
  # the role is allowed to do, it says *who is allowed to use the
  # role*.
  #
  # ALSO NOTE that I'm embedding the "assume role" policy right here,
  # but there are other ways to do it.  For now I just want you to...
  # 1) understand why we need this - we need it to tell AWS that it's
  #    ok for the Lambda service to take on this role when it runs
  #    our Lambda function.
  # 2) see the similarity between this code and the code you have in
  #    the week5 "automation" directory, which does the same thing,
  #    but for the EC2 service instead.
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": "AllowLambdaToAssumeTheRole"
    }
  ]
}
EOF
}


# This is another way to define a policy and I like it more.  Instead of
# defining the policy using JSON we use HCL.  In my opinion it's cleaner.
# Note the use of the "data" directive - we're defining something here
# that we'll use later.  This is similar to what do for the AMI lookup.
data "aws_iam_policy_document" "lambda-iam-policy" {
  statement {
    sid    = "Week7LambdaLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "*"
    ]
  }
}


# Now that we've defined the *contents* of our policy let's create the
# actual resource.
resource "aws_iam_policy" "lambda-iam-policy" {
  name = "week7-lambda-iam-policy"
  path = "/"

  # Note that we use our "data" item from above, and access the "json" attribute,
  # which implicitly converts it to JSON.
  policy = data.aws_iam_policy_document.lambda-iam-policy.json
}


# Lastly, we've got that dumb "attachment" thing where we need to connect
# the role and the policy together.  You did this in week5 too.
resource "aws_iam_role_policy_attachment" "automation-role" {
  role       = aws_iam_role.lambda-iam-role.name
  policy_arn = aws_iam_policy.lambda-iam-policy.arn
}


resource "aws_lambda_function" "lambda" {
  # This file contains the code for our Lambda.
  filename      = "lambda_code.zip"
  function_name = "week7-lambda"
  role          = aws_iam_role.lambda-iam-role.arn

  # This is the name of the file followed by the name of the function.
  handler       = "lambda_code.lambda_handler"

  # This tells Terraform whether the code has changed or not.
  source_code_hash = filebase64sha256("lambda_code.zip")

  runtime = "python3.9"
  timeout = 10

  environment {
    variables = {
        week = "week7"
    }
  }
}
