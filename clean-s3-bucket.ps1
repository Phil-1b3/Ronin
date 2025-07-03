# PowerShell script to completely clean S3 bucket
param(
    [Parameter(Mandatory=$true)]
    [string]$BucketName = "phils-codepipeline-artifacts-ycfx8xeo"
)

Write-Host "Cleaning S3 bucket: $BucketName" -ForegroundColor Yellow

try {
    # First, remove all current objects
    Write-Host "Removing all current objects..." -ForegroundColor Green
    aws s3 rm "s3://$BucketName" --recursive
    
    # Get all object versions
    Write-Host "Getting all object versions..." -ForegroundColor Green
    $versions = aws s3api list-object-versions --bucket $BucketName --query 'Versions[].{Key:Key,VersionId:VersionId}' --output json | ConvertFrom-Json
    
    if ($versions) {
        Write-Host "Found $($versions.Count) versions to delete" -ForegroundColor Green
        
        # Delete versions in batches of 1000 (AWS limit)
        for ($i = 0; $i -lt $versions.Count; $i += 1000) {
            $batch = $versions[$i..([Math]::Min($i + 999, $versions.Count - 1))]
            $deleteRequest = @{
                Objects = $batch
                Quiet = $true
            } | ConvertTo-Json -Depth 3
            
            $tempFile = [System.IO.Path]::GetTempFileName()
            $deleteRequest | Out-File -FilePath $tempFile -Encoding utf8
            
            Write-Host "Deleting batch $([Math]::Floor($i/1000) + 1)..." -ForegroundColor Green
            aws s3api delete-objects --bucket $BucketName --delete "file://$tempFile"
            
            Remove-Item $tempFile
        }
    }
    
    # Get all delete markers
    Write-Host "Getting delete markers..." -ForegroundColor Green
    $deleteMarkers = aws s3api list-object-versions --bucket $BucketName --query 'DeleteMarkers[].{Key:Key,VersionId:VersionId}' --output json | ConvertFrom-Json
    
    if ($deleteMarkers) {
        Write-Host "Found $($deleteMarkers.Count) delete markers to remove" -ForegroundColor Green
        
        # Delete markers in batches
        for ($i = 0; $i -lt $deleteMarkers.Count; $i += 1000) {
            $batch = $deleteMarkers[$i..([Math]::Min($i + 999, $deleteMarkers.Count - 1))]
            $deleteRequest = @{
                Objects = $batch
                Quiet = $true
            } | ConvertTo-Json -Depth 3
            
            $tempFile = [System.IO.Path]::GetTempFileName()
            $deleteRequest | Out-File -FilePath $tempFile -Encoding utf8
            
            Write-Host "Deleting delete markers batch $([Math]::Floor($i/1000) + 1)..." -ForegroundColor Green
            aws s3api delete-objects --bucket $BucketName --delete "file://$tempFile"
            
            Remove-Item $tempFile
        }
    }
    
    Write-Host "S3 bucket $BucketName has been completely cleaned!" -ForegroundColor Green
    
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Make sure your AWS credentials are configured correctly" -ForegroundColor Yellow
    Write-Host "Run: aws configure --profile phils_profile" -ForegroundColor Yellow
}
