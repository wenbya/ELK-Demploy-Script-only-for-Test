# First login the ARM models in AzureChinaCloud
Login-AzureRmAccount -EnvironmentName AzureChinaCloud

# Enter your account

# Create resourceGroup
$locName = "China North"
$rgName = "yourresourcegroup"
New-AzureRmResourceGroup -Name $rgName -Location $locName

#Please download the ***Template.json and ***Parameter.json  into your local path

$deployName="yourDeploymentName"
$templatePath = "path\***Template.json"
$parameterFile = "path\***Parameter.json"
New-AzureRmResourceGroupDeployment -ResourceGroupName $rgName -TemplateFile $templatePath -TemplateParameterFile $parameterFile  

# Waiting for the deployment. It may takes long
