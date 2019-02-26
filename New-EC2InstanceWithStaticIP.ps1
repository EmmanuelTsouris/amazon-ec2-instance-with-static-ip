
## AWS Region
$region = "us-west-2"

## KeyPair Used to retrive the Windows Administrator Password
$keyPair = "winec2keypair"

## Instance Type
$instanceType = "m5.large"

## Use the Latest Windows Server 2012 R2 RTM English Base AMI
$imageId = ((Get-SSMParameterValue -Region $region -Name "/aws/service/ami-windows-latest/Windows_Server-2012-R2_RTM-English-64Bit-Base").Parameters[0].Value)

## Find a Default VPC, Subnet, and Security Group
$vpc = Get-EC2Vpc -Region $region | Where-Object {$_.IsDefault -eq "True"}
$subnet = Get-EC2Subnet -Region $region -Filter @{Name = "vpc-id"; Value = $vpc.VpcId } | Select-Object -First 1
$sg = Get-EC2SecurityGroup -Region $region -Filter @{Name = "vpc-id"; Value = $vpc.VpcId } | Select-Object -First 1

## Create a Primary Interface with a Static IP Address
$primaryIinterface = New-Object Amazon.EC2.Model.InstanceNetworkInterfaceSpecification
$primaryIinterface.DeviceIndex = 0
$primaryIinterface.SubnetId = $subnet.SubnetId
$primaryIinterface.Groups.Add($sg.GroupId)
$primaryIinterface.PrivateIpAddress = "172.31.32.12"

## Tag on Launch
$NameTag = @{Key="Name"; Value="Windows Server with Static Private IP $($primaryIinterface.PrivateIpAddress)"}
$NameTagSpec = New-Object Amazon.EC2.Model.TagSpecification
$NameTagSpec.ResourceType = "instance"
$NameTagSpec.Tags.Add($NameTag)

## Execute some PowerShell Commands via User Data, or in this case a simple IP Config.
$userDataString = "IPConfig | Out-File c:\IPConfig.txt"

## Wrap PowerShell tags around the user data
$userDataString = @"
<powershell>
$userDataString
</powershell>
"@

## Encode the user data to base 64
$EncodeUserData = [System.Text.Encoding]::UTF8.GetBytes($userDataString)
$userData = [System.Convert]::ToBase64String($EncodeUserData)

## Launch an instance with all the settings from above.
$newInstance = New-EC2Instance -Region $region -ImageId "$($imageId)" -KeyName $KeyPair -UserData $userData -InstanceType $instanceType -NetworkInterface $primaryIinterface -TagSpecification $NameTagSpec -MinCount 1 -MaxCount 1 

## Show the Instance Id of the running instance
$newInstance | Select-Object -ExpandProperty RunningInstance | Select-Object -ExpandProperty InstanceId
