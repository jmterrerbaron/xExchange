function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]

    param(
        # The name of the address book
        [Parameter(Mandatory = $true)]
        [string]
        $DomainName,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential
    )

    Write-Verbose -Message 'Getting the Exchange Accepted Domains List'

    Write-FunctionEntry -Parameters @{'Identity' = $DomainName } -Verbose:$VerbosePreference

    # Establish remote PowerShell session
    Get-RemoteExchangeSession -Credential $Credential -CommandsToLoad 'Get-AcceptedDomain' -Verbose:$VerbosePreference

    $acceptedDomain = Get-AcceptedDomain -Identity $DomainName -ErrorAction SilentlyContinue

    $acceptedDomainProperties = @(
        'Name'
        'DomainName'
        'AddressBookEnabled'
        'DomainType'
        'Default'
        'MatchSubDomains'
    )

    if ($null -ne $acceptedDomain)
    {
        $returnValue = @{
            Ensure = 'Present'
        }
        foreach ($property in $acceptedDomain.PSObject.Properties.Name)
        {
            if ($acceptedDomain.$property -and $acceptedDomainProperties -contains $property)
            {
                $returnValue[$property] = $acceptedDomain.$property
            }
        }
    }
    else
    {
        $returnValue = @{
            Ensure = 'Absent'
        }
    }

    return $returnValue
}
function Set-TargetResource
{
    [CmdletBinding()]
    param(
        # The name of the accepted domain
        [Parameter(Mandatory = $true)]
        [string]
        $DomainName,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $false)]
        [bool]
        $AddressBookEnabled = $true,

        [Parameter(Mandatory = $false)]
        [string]
        $DomainType,

        [Parameter(Mandatory = $false)]
        [bool]
        $Default = $false,

        [Parameter(Mandatory = $false)]
        [bool]
        $MatchSubDomains = $false,

        [Parameter(Mandatory = $false)]
        [string]
        $Name

    )

    Write-Verbose -Message 'Setting the Exchange AddresslList settings'

    Write-FunctionEntry -Parameters @{'Identity' = $DomainName } -Verbose:$VerbosePreference

    # Establish remote PowerShell session
    Get-RemoteExchangeSession -Credential $Credential -CommandsToLoad '*-AcceptedDomain' -Verbose:$VerbosePreference

    # Ensure an empty string is $null and not a string
    Set-EmptyStringParamsToNull -PSBoundParametersIn $PSBoundParameters
    Remove-FromPSBoundParametersUsingHashtable -PSBoundParametersIn $PSBoundParameters -ParamsToRemove Credential, Ensure, 'Default'

    $acceptedDomain = Get-TargetResource -Name $DomainName -Credential $Credential

    if ($acceptedDomain['Ensure'] -eq 'Present')
    {
        if ($Ensure -eq 'Absent')
        {
            Write-Verbose -Message ('Removing the address list {0}' -f $acceptedDomain.Name)
            Remove-AcceptedDomain -Identity $acceptedDomain.Name -confirm:$false
        }
        else
        {
            Write-Verbose -Message ('Address list {0} not compliant. Setting the desired attributes.' -f $acceptedDomain.Name)

            if ($null -eq $PSBoundParameters['Name'])
            {
                $PSBoundParameters['Identity'] = $acceptedDomain['DomainName']
            }
            else
            {
                $PSBoundParameters['Identity'] = $acceptedDomain['Name']
            }

            Set-AcceptedDomain @PSBoundParameters -confirm:$false
        }
    }
    else
    {
        Write-Verbose -Message ('Address list {0} does not exist. Creating it...' -f $acceptedDomain.Name)

        New-AcceptedDomain -DomainName $DomainName -confirm:$false

        if ($null -eq $PSBoundParameters['Name'])
        {
            $PSBoundParameters['Identity'] = $acceptedDomain['DomainName']
        }
        else
        {
            $PSBoundParameters['Identity'] = $acceptedDomain['Name']
        }

        Set-AcceptedDomain @PSBoundParameters -confirm:$false
    }
}
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param(
        # The name of the accepted domain
        [Parameter(Mandatory = $true)]
        [string]
        $DomainName,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $false)]
        [bool]
        $AddressBookEnabled = $true,

        [Parameter(Mandatory = $false)]
        [string]
        $DomainType,

        [Parameter(Mandatory = $false)]
        [bool]
        $Default = $false,

        [Parameter(Mandatory = $false)]
        [bool]
        $MatchSubDomains = $false,

        [Parameter(Mandatory = $false)]
        [string]
        $Name
    )

    Write-Verbose -Message 'Testing the Exchange AddresslList settings'

    Write-FunctionEntry -Parameters @{'Identity' = $DomainName } -Verbose:$VerbosePreference

    Set-EmptyStringParamsToNull -PSBoundParametersIn $PSBoundParameters

    $targetResourceInCompliance = $true

    $acceptedDomain = Get-TargetResource -Name $DomainName -Credential $Credential

    Remove-FromPSBoundParametersUsingHashtable -PSBoundParametersIn $PSBoundParameters -ParamsToRemove 'Credential'
    $DifferenceObjectHashTable = @{ } + $PSBoundParameters

    if ($null -eq $PSBoundParameters['Name'])
    {
        $DifferenceObjectHashTable['Name'] = $DomainName
    }

    if ($acceptedDomain['Ensure'] -eq 'Absent' -and $Ensure -ne 'Absent')
    {
        $targetResourceInCompliance = $false
    }
    else
    {
        $referenceObject = [PSCustomObject]$acceptedDomain
        $differenceObject = [PSCustomObject]$DifferenceObjectHashTable

        foreach ($property in $DifferenceObjectHashTable.Keys)
        {
            if (Compare-Object -ReferenceObject $referenceObject -DifferenceObject $differenceObject -Property $property)
            {
                Write-Verbose -Message ("Invalid setting '{0}'. Expected value: {1}. Actual value: {2}" -f $property, $DifferenceObjectHashTable[$property], $acceptedDomain[$property])
                $targetResourceInCompliance = $false
                break;
            }
        }
    }

    return $targetResourceInCompliance
}
