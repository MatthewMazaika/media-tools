Set-Location -Path Z:\media-tools
$logFile = "logs\$(Get-Date -Format "yyyyMMdd-HHmmss").log"


function TimeStamp {
    Get-Date -Format "yyyy-MM-dd HH:mm:ss"
}

function Write-ConsoleAndLog {
    Param(
        $Message,
        $file = $logFile
    )

    "[$(TimeStamp)] $Message" | Tee-Object -FilePath $file -Append
}

function UnacceptableTime {
    if ($(Get-Date).Hour -ge 10) {
        $true
    } else {
        $false
    }
}

$dryRun = $false
$clean = $false

$skippedFileCount = 0
$encodedFileCount = 0
$cleanedFileCount = 0

Write-ConsoleAndLog "Beginning processing: dryRun=$($dryRun), clean=$($clean)"

$files = Get-ChildItem -Path "Z:\Recorded TV Shows" -Recurse -File *.ts
foreach ($file in $files) {
     $videoDir = $file.Directory.FullName
     $sourceFileName = $file.Name
     $destFileName = $file.Name -replace ".ts$", "-h265-720p.mkv" 

     if ($videoDir -match "#recycle") {
        continue
     }

     if ($(UnacceptableTime) -and -Not $dryRun) {
        Write-ConsoleAndLog "Stopping execution due to current time"
        $skippedFileCount += ($files.Count - $skippedFileCount - $encodedFileCount)
        break
     }

     if (((Get-Date) - ($file).LastWriteTime).TotalSeconds -lt 3600) {
        Write-ConsoleAndLog "Skipping recently recorded item: $($videoDir)\$($sourceFileName)"
        $skippedFileCount++
        continue
     }   

     if (-Not (Test-Path "$($videoDir)\$($destFileName)")) {
        $command = "HandBrakeCLI -i `"$($videoDir)\$($sourceFileName)`" -o `"$($videoDir)\$($destFileName)`" -e x265 -q 21 --comb-detect --decomb --width 1280 --height 720"
        
        if (-Not $dryRun) {
            Write-ConsoleAndLog "Processing: $($sourceFileName)"
            Write-ConsoleAndLog $command
            & cmd /c $command
            $encodedFileCount++
        } else {
            Write-ConsoleAndLog "Dry run - not processing: $($videoDir)\$($sourceFileName)"
        }
     } else {                
        if (-Not $dryRun -And $clean) {
            Write-ConsoleAndLog "Cleaning: $($videoDir)\$($sourceFileName)"
            Remove-Item "$($videoDir)\$($sourceFileName)"
            $cleanedFileCount++
        } else {
            Write-ConsoleAndLog "Found already processed item: $($videoDir)\$($sourceFileName)"
        }
     }
}

Write-ConsoleAndLog "Skipped $($skippedFileCount) files"
Write-ConsoleAndLog "Encoded $($encodedFileCount) files"
Write-ConsoleAndLog "Cleaned $($cleanedFileCount) files"
Write-ConsoleAndLog "Completed processing!"
