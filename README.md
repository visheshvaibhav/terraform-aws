# terraform-aws

Prerequisites:
Before executing this deployment on your local machine, ensure that you have Terraform installed. If Terraform is not already installed on your system, you can download and install it from here based on your operating system.

Additionally, you'll need to set up your AWS credentials as environment variables. Follow the steps below to set up your credentials:

## AWS Access Key## : Log in to your AWS account and create an access key if one has not been created already.

## AWS Secret Key## : This key is associated with the access key and provides authentication.

# Steps to Set Up :
  Download and open the main.tf file from this repository in your preferred Integrated Development Environment (IDE) such as Visual Studio Code (VSCode).
  
  In your IDE, download the "Terraform from HashiCorp" extension and restart your IDE to ensure proper functionality.
  
  Open the terminal in VSCode and set your AWS credentials as environment variables. 

Use the following commands:

## For Windows:

```terminal 
setx ACCESS_KEY <your_access_key>
setx SECRET_KEY <your_secret_key>
```


## For MacOS/Linux:
```terminal
export ACCESS_KEY=<your_access_key>
export SECRET_KEY=<your_secret_key>
```

## Deployment:
Once you've set up your credentials and configured the main.tf file, you're ready to deploy the web application to AWS. Navigate to the directory containing the main.tf file in your terminal and execute the following commands:

## Initialize Terraform:
```terminal

terraform init
```

## Preview the execution plan:
```terminal

terraform plan
'''

## Apply the changes to deploy the web application:## 
```terminal

terraform apply
```

## Testing:
To test the deployed web application, access the public DNS of the Application Load Balancer in your web browser. Ensure that the web application is functioning correctly and serving the expected content.

## Additional Notes:
Make sure to review the main.tf file and customize any configurations or settings according to your requirements before deploying.
Take caution while executing Terraform commands, as they will make changes to your AWS infrastructure.
For more information on Terraform commands and best practices, refer to the Terraform documentation.

Remember to destroy the resources once they are no longer needed to avoid incurring unnecessary costs. You can do this by running:
```terminal
terraform destroy
```
