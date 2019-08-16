function Find-SoftwareGUID {
# Modified from https://4sysops.com/archives/find-the-product-guid-of-installed-software-with-powershell/
    <#
        Get-InstalledSoftware
        Get-InstalledSoftware -name Python
        Get-InstalledSoftware -GUID `{05EC21B8-4593-3037-A781-A6B5AFFCB19D`}
        # need to escape { } using `, or they disappear in the string
    #>

    [OutputType([System.Management.Automation.PSObject])]
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Name = "",
	    [string]$GUID = ""
    )

    $UninstallKeys = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall", "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
    $null = New-PSDrive -Name HKU -PSProvider Registry -Root Registry::HKEY_USERS
    $UninstallKeys += Get-ChildItem HKU: -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'S-\d-\d+-(\d+-){1,14}\d+$' } | ForEach-Object { "HKU:\$($_.PSChildName)\Software\Microsoft\Windows\CurrentVersion\Uninstall" }
    $GUIDPattern = '^{[A-Z0-9]{8}-([A-Z0-9]{4}-){3}[A-Z0-9]{12}}$'
    if (-not $UninstallKeys) {
        Write-Verbose -Message 'No software registry keys found'
    } else {
        foreach ($UninstallKey in $UninstallKeys) {
            # Choose Where filter depends on the param
            if ($PSBoundParameters.ContainsKey('Name')) {
                $WhereBlock = { ($_.PSChildName -match $GUIDPattern) -and ($_.GetValue('DisplayName') -like "$Name*") }
                # like -> case insensitive
                # clike -> case sensitive
            } 
            ElseIf ($PSBoundParameters.ContainsKey('GUID')) {
		        $WhereBlock = { ($_.PSChildName -match $GUIDPattern) -and ($_.PSChildName -like "$GUID*") }
	        } 
            else {
                $WhereBlock = { ($_.PSChildName -match $GUIDPattern) -and ($_.GetValue('DisplayName')) }
            }
            $gciParams = @{
                Path        = $UninstallKey
                ErrorAction = 'SilentlyContinue'
            }
            $selectProperties = @(
                @{n='GUID'; e={$_.PSChildName}}
                @{n='Name'; e={$_.GetValue('DisplayName')}}
            )
            #$WhereBlock
            Get-ChildItem @gciParams | Where $WhereBlock | Select-Object -Property $selectProperties
        }
    }
}
