$script:DSCModuleName = 'xExchange'
$script:DSCResourceName = 'MSFT_xExchAutoMountPoint'
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'tests' -ChildPath (Join-Path -Path 'TestHelpers' -ChildPath 'xExchangeTestHelper.psm1'))) -Global -Force

function Invoke-TestSetup
{
    try
    {
        Import-Module -Name DscResource.Test -Force
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
    }

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Invoke-TestSetup

# Begin Testing
try
{
    InModuleScope $script:DSCResourceName {
        function Get-DiskInfo
        {

        }
        Describe 'MSFT_xExchAutoMountPoint\Get-TargetResource' -Tag 'Get' {
            AfterEach {
                Assert-VerifiableMock
            }

            $getTargetResourceParams = @{
                Identity                       = 'AutodiscoverVirtualDirectory'
                AutoDagDatabasesRootFolderPath = 'C:\ExchangeDatabases'
                AutoDagVolumesRootFolderPath   = 'C:\ExchangeVolumes'
                DiskToDBMap                    = @('DB1,DB2,DB3,DB4')
                SpareVolumeCount               = 1
            }

            Context 'When Get-TargetResource is called' {
                Mock -CommandName Write-FunctionEntry -Verifiable
                Mock -CommandName Get-DiskInfo -Verifiable -MockWith { return @{ } }
                Mock -CommandName Get-DiskToDBMap -Verifiable -MockWith { return $getTargetResourceParams.DiskToDBMap }

                Test-CommonGetTargetResourceFunctionality -GetTargetResourceParams $getTargetResourceParams
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}

