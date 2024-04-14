<#
.SYNOPSIS
Helper script to run Digital Speech Decoder (DSD)

.DESCRIPTION
Script helps to run Digital Speech Decoder (DSD) file 'dsd.exe' using
multiple decoding options. Single decoder process is supported that runs
in separate shell window.

.PARAMETER Path
Path to 'dsd.exe' executable. The parameter is optional if script is started
from within DSD folder.

.INPUTS
None.

.OUTPUTS
None.

.EXAMPLE
.\DsdLauncher.ps1 -Path C:\DSD\dsd.exe

.NOTES
DSD is written by Louis-Erig HERVE and compiled executable can be downloaded
from: https://www.1geniesup.fr/dsd/

.LINK
https://github.com/ZilvinasJonaitis/DsdLauncher
#>

param (
    [Parameter()]
    [string]
    $Path = (Split-Path -Path $MyInvocation.MyCommand.Path -Parent)
)

$dsdProgram = "dsd.exe"
$menuMap = @(
    @(1,"DMR"),
    @(2,"dPMR"),
    @(3,"D-Star"),
    @(4,"NXDN48"),
    @(5,"NXDN96"),
    @(6,"P25 P1"),
    @(7,"ProVoice"),
    @(8,"X2-TMDA"),
    @(0,"Auto detect")
)
# Get all console color values:
# ([System.ConsoleColor]).DeclaredFields | select name
$defItemColor = [System.ConsoleColor]::White    # default menu item color
$selItemColor = [System.ConsoleColor]::Yellow   # selected menu item color

if ((Split-Path -Path $Path -Leaf) -eq $dsdProgram) {
    $dsdPath = $Path
} else {
    $dsdPath = Join-Path -Path $Path -ChildPath $dsdProgram
}

# Test path to 'dsd.exe'
if (!(Test-Path $dsdPath)) {
    Write-Host
    Write-Host -ForegroundColor Red "'$dsdPath' not found!"
    Write-Host -ForegroundColor Yellow "Use -Path to specify location of '$dsdProgram' executable."
    Write-Host
    exit 1
}


# Funtion stops any runing DSD process and starts a new one in separate CLI window.
function RunDSDProcess {
    param (
        [Parameter(Mandatory)]
        [String]
        $Path,
        [Parameter(Mandatory)]
        [ValidateSet(
            "DMR", "dPMR", "D-Star", "NXDN48", "NXDN96", "P25-P1" , "ProVoice", "X2-TMDA", "Auto"
        )]
        [String]
        $DecodeFormat
    )

    Clear-Host

    # Default parameters for 'dsd.exe'
    $params = @(
        "-i /dev/dsp -o /dev/dsp"
    )

    # Append additional parameters specific to each decoder mode
    switch ($DecodeFormat) {
        "DMR" {
            Write-Host -ForegroundColor $selItemColor "Decoding $DecodeFormat..."
            $params += "-fr"
            break
        }

        "dPMR" {
            Write-Host -ForegroundColor $selItemColor "Decoding $DecodeFormat..."
            $params += "-fm"
            # Other optional or experimental parameters
            # $params += "-l"
            # $params += "-ma"
            # $params += "-mc"
            # $params += "-mg"
            # $params += "-mq"
            break
        }

        "D-Star" {
            $params += "-fd"
            Write-Host -ForegroundColor $selItemColor "Decoding $DecodeFormat..."
            break
        }

        "NXDN48" {
            Write-Host -ForegroundColor $selItemColor "Decoding $DecodeFormat..."
            $params += "-fi"
            break
        }

        "NXDN96" {
            Write-Host -ForegroundColor $selItemColor "Decoding $DecodeFormat..."
            $params += "-fn"
            break
        }

        "P25-P1" {
            Write-Host -ForegroundColor $selItemColor "Decoding $DecodeFormat..."
            $params += "-f1"
            break
        }

        "ProVoice" {
            Write-Host -ForegroundColor $selItemColor "Decoding $DecodeFormat..."
            $params += "-fp"
            break
        }

        "X2-TMDA" {
            Write-Host -ForegroundColor $selItemColor "Decoding $DecodeFormat..."
            $params += "-fx"
            break
        }

        "Auto" {
            Write-Host -ForegroundColor $selItemColor "$DecodeFormat decoding..."
            $params += "-fa"
            break
        }
    }

    $processName = $dsdProgram.Split('.')[0]
    Write-Host "$processName $params"

    # Stop any running dsd process
    Get-Process $processName -ErrorAction SilentlyContinue | Stop-Process
    Start-Sleep -Milliseconds 2000

    # Start new dsd process
    Start-Process -FilePath $Path -ArgumentList $params
}

# Function to draw a menu
function DrawMenu {
    param (
        [UInt16]
        $SelectionId,
        [System.ConsoleColor]
        $SelectionColor,
        [System.ConsoleColor]
        $DefaultColor
    )

    Clear-Host
    
    foreach ($item in $menuMap) {
        if ($SelectionId -eq $item[0]) {
            Write-Host -ForegroundColor $SelectionColor $item[0], "-", $item[1], "decoding..."
        } else {
            Write-Host -ForegroundColor $DefaultColor $item[0], "-", $item[1]
        }
    }

    Write-Host -ForegroundColor $DefaultColor "Esc - Exit"
}


# Draw menu for the first time using dummy '255' SelectionId ('nothing yet selected')
DrawMenu -SelectionId 255 -SelectionColor $selItemColor -DefaultColor $defItemColor

# Main script loop
do {
    # Wait for a key to be pressed
    if ([Console]::KeyAvailable)
    {
        # Read the key, and consume it so it won't be echoed to the console
        $keyInfo = [Console]::ReadKey($true)
        # https://learn.microsoft.com/en-us/dotnet/api/system.consolekey?view=net-8.0
        switch ($keyInfo.Key)
        {
            # exit
            ([ConsoleKey]::Escape)
            {
                # Stop running dsd process if any
                Get-Process "dsd" -ea SilentlyContinue | Stop-Process
                # Exit DSDlauncher
                Clear-Host
                exit
            }
            
            # DMR
            ({$PSItem -eq "D1" -or $PSItem -eq "NumPad1"})
            {
                RunDSDProcess -Path $dsdPath -DecodeFormat "DMR"
                DrawMenu -SelectionId 1 -SelectionColor $selItemColor -DefaultColor $defItemColor
                break
            }
            
            # dPMR
            ({$PSItem -eq "D2" -or $PSItem -eq "NumPad2"})
            {
                RunDSDProcess -Path $dsdPath -DecodeFormat "dPMR"
                DrawMenu -SelectionId 2 -SelectionColor $selItemColor -DefaultColor $defItemColor
                break
            }

            # D-Star
            ({$PSItem -eq "D3" -or $PSItem -eq "NumPad3"})
            {
                RunDSDProcess -Path $dsdPath -DecodeFormat "D-Star"
                DrawMenu -SelectionId 3 -SelectionColor $selItemColor -DefaultColor $defItemColor
                break
            }

            # NXDN48
            ({$PSItem -eq "D4" -or $PSItem -eq "NumPad4"})
            {
                RunDSDProcess -Path $dsdPath -DecodeFormat "NXDN48"
                DrawMenu -SelectionId 4 -SelectionColor $selItemColor -DefaultColor $defItemColor
                break
            }

            # NXDN96
            ({$PSItem -eq "D5" -or $PSItem -eq "NumPad5"})
            {
                RunDSDProcess -Path $dsdPath -DecodeFormat "NXDN96"
                DrawMenu -SelectionId 5 -SelectionColor $selItemColor -DefaultColor $defItemColor
                break
            }

            # P25 Phase 1
            ({$PSItem -eq "D6" -or $PSItem -eq "NumPad6"})
            {
                RunDSDProcess -Path $dsdPath -DecodeFormat "P25-P1"
                DrawMenu -SelectionId 6 -SelectionColor $selItemColor -DefaultColor $defItemColor
                break
            }
            
            # ProVoice
            ({$PSItem -eq "D7" -or $PSItem -eq "NumPad7"})
            {
                RunDSDProcess -Path $dsdPath -DecodeFormat "ProVoice"
                DrawMenu -SelectionId 7 -SelectionColor $selItemColor -DefaultColor $defItemColor
                break
            }

            # X2-TMDA
            ({$PSItem -eq "D8" -or $PSItem -eq "NumPad8"})
            {
                RunDSDProcess -Path $dsdPath -DecodeFormat "X2-TMDA"
                DrawMenu -SelectionId 8 -SelectionColor $selItemColor -DefaultColor $defItemColor
                break
            }

            # Auto detect
            ({$PSItem -eq "D0" -or $PSItem -eq "NumPad0"})
            {
                RunDSDProcess -Path $dsdPath -DecodeFormat "Auto"
                DrawMenu -SelectionId 0 -SelectionColor $selItemColor -DefaultColor $defItemColor
                break
            }
        }
    }
    Start-Sleep -Milliseconds 150
} while ($true)
