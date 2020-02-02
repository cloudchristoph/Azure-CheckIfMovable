param (
    [Parameter(Mandatory)]
    [ValidateSet('ResourceGroup','Subscription')]
    [string]$Source,

    [string]$SubscriptionId,
    [string]$ResourceGroupName,

    [Parameter(Mandatory)]
    [ValidateSet('ResourceGroup','Subscription')]
    [string]$Destination    
)

$supportedResourcesFile = Import-Csv -Path .\modules\resource-capabilities\move-support-resources.csv

Write-Verbose "Loading resources..."
switch ($Source) {
    'ResourceGroup' {
        $resources = Get-AzResource -ResourceGroupName $ResourceGroupName      
    }
    Default {
        if (-not [String]::IsNullOrEmpty($SubscriptionId)) {
            Select-AzSubscription -SubscriptionId $SubscriptionId
        }
        $resources = Get-AzResource
    }
}

if ($resources.length -eq 0) {
    Write-Warning -Message "No resources found"
    return
}

Write-Verbose ("Found " + $resources.Count + " resources")
$nonMovableResources = 0

foreach ($resource in $resources) {
    #Write-Output $resources.Type
    $result = Write-Output $supportedResourcesFile | `
        Where-Object { $_.Resource.ToLower() -eq $resource.Type.ToString().ToLower() }

    if (($Destination -eq "Subscription" -and $result.'Move Subscription' -eq 0) -or 
        $Destination -eq "ResourceGroup" -and $result.'Move Resource Group' -eq 0) {
        $nonMovableResources++
        Write-Warning ($resource.Name + " not movable. (ID: " + $resource.ResourceId + ")") 
    }
}

if ($nonMovableResources -eq 0) {
    Write-Output "Every resource is movable"
} else {
    Write-Output "$nonMovableResources resource(s) are not movable to your choosen destination ($Destination)"
}