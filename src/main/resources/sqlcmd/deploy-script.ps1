$_InstanceName = $($deployed.container.InstanceName)
$_DatabaseName = $($deployed.container.DatabaseName)
$_Username = $($deployed.container.Username)
$_Password = $($deployed.container.Password)
$_TempScriptsPath = $($deployed.container.TempPath)

function ExecuteDeployment()
{
	Write-Host "---------------------------------------------------"
	Write-Host "---- Instance name: $($_InstanceName)" 
	Write-Host "---- Database name: $($_DatabaseName)"
	Write-Host "---- Username name: $($_Username)"
	Write-Host "---- Temp folder: $($_TempScriptsPath)"

	# Call function to extract all scripts from zip file
	ExtractScriptsFromZipFile

	# Call function to use sqlcmd utility to execute all scripts
	ExecuteScripts
}

function ExtractScriptsFromZipFile()
{	
	PrintMessage "Deleting all files from target directory $($_TempScriptsPath)..."
	if (Test-Path $_TempScriptsPath) 
	{
		Get-ChildItem -Path $_TempScriptsPath -Recurse | Remove-Item -Force -Recurse | Out-Null
		Remove-Item $_TempScriptsPath -Force | Out-Null
		Write-Host "Done!"
	}

	PrintMessage "Unzipping and copying new files to target directory $($_TempScriptsPath)..."
	$shell = new-object -com shell.application
	$zip = $shell.NameSpace($deployed.file)
	$x = New-Item -Path $_TempScriptsPath -ItemType directory
	foreach($item in $zip.items()) 
	{
		Write-Host "Copying script $($item.name)"
		$shell.Namespace($_TempScriptsPath).copyhere($item)
	}
	Write-Host "Done!"
}

function ExecuteScripts()
{
	PrintMessage "Executing scripts against the target server/database..."

	Get-ChildItem $_TempScriptsPath -Filter *.sql | 
	Foreach-Object {
	    & sqlcmd -S $_InstanceName -d $_DatabaseName -U $_Username -P $_Password -i "$($_.FullName)"
	}
	Write-Host "Done!"
}

function PrintMessage($message)
{
	Write-Host "---------------------------------------------------"
	Write-Host "---- $message"
}

# Call main function 
ExecuteDeployment