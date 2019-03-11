﻿Function Write-Influx {
    <#
        .SYNOPSIS
            Writes data to Influx via the REST API.

        .DESCRIPTION
            Use to send data in to an Influx database by providing a hashtable of tags and values.

        .PARAMETER InputObject
            A metric object (generated by one of the Get-*Metric cmdlets from this module) which can be provided as pipeline input.

        .PARAMETER Measure
            The name of the measure to be updated or created.

        .PARAMETER Tags
            A hashtable of tag names and values.

        .PARAMETER Metrics
            A hashtable of metric names and values.

        .PARAMETER Timestamp
            Specify the exact date and time for the measure data point. If not specified the current date and time is used.

        .PARAMETER Server
            The URL and port for the Influx REST API. Default: 'http://localhost:8086'

        .PARAMETER Database
            The name of the Influx database to write to.

        .PARAMETER Credential
            A PSCredential object with the username and password to use if the Influx server has authentication enabled.
        
        .PARAMETER Bulk
            Switch: Use to have all metrics transmitted via a single connection to Influx.

        .PARAMETER ExcludeEmptyMetric
            Switch: Use to exclude null or empty metric values from being sent. Useful where a metric is initially created as an integer but then
            an empty or null instance of that metric would attempt to be sent as an empty string, resulting in a datatype conflict.

        .EXAMPLE
            Write-Influx -Measure WebServer -Tags @{Server='Host01'} -Metrics @{CPU=100; Memory=50} -Database Web -Server http://myinflux.local:8086
            
            Description
            -----------
            This command will submit the provided tag and metric data for a measure called 'WebServer' to a database called 'Web' 
            via the API endpoint 'http://myinflux.local:8086'
    #>
    [cmdletbinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Parameter(ParameterSetName = 'MetricObject', Mandatory = $true, ValueFromPipeline = $True, Position = 0)]
        [PSTypeName('Metric')]
        [PSObject[]]
        $InputObject,

        [Parameter(ParameterSetName = 'Measure', Mandatory = $true, Position = 0)]
        [string]
        $Measure,

        [Parameter(ParameterSetName = 'Measure')]
        [hashtable]
        $Tags,
        
        [Parameter(ParameterSetName = 'Measure', Mandatory = $true)]
        [hashtable]
        $Metrics,

        [Parameter(ParameterSetName = 'Measure')]
        [datetime]
        $TimeStamp,
        
        [Parameter(Mandatory = $true)]
        [string]
        $Database,
        
        [string]
        $Server = 'http://localhost:8086',

        [pscredential]
        $Credential,

        [switch]
        $Bulk,

        [switch]
        $ExcludeEmptyMetric
    )
    Begin {
        if ($Credential) {
            $Username = $Credential.UserName
            $Password = $Credential.GetNetworkCredential().Password

            $EncodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("$($Username):$($Password)"))

            $Headers = @{
                Authorization = "Basic $EncodedCreds"
            }
        }

        $BulkBody = @()
        $URI = "$Server/write?&db=$Database"
    }
    Process {
        if (-not $InputObject) {
            $InputObject = @{
                Measure = $Measure
                Metrics = $Metrics
                Tags = $Tags
                TimeStamp = $TimeStamp
            }
        }

        ForEach ($MetricObject in $InputObject) {
            
            if ($MetricObject.TimeStamp) {
                $timeStampNanoSecs = $MetricObject.Timestamp | ConvertTo-UnixTimeNanosecond
            }
            else {
                $null = $timeStampNanoSecs
            }

            if ($MetricObject.Tags) {
                $TagData = foreach ($Tag in $MetricObject.Tags.Keys) {
                    if ([string]::IsNullOrEmpty($MetricObject.Tags[$Tag])) {
                        Write-Warning "$Tag skipped as it's value was null or empty, which is not permitted by InfluxDB."
                    }
                    else {
                        "$($Tag | Out-InfluxEscapeString)=$($MetricObject.Tags[$Tag] | Out-InfluxEscapeString)"
                    }
                }
                $TagData = $TagData -Join ','
                $TagData = ",$TagData"
            }
        
            $Body = foreach ($Metric in $MetricObject.Metrics.Keys) {
            
                if ($ExcludeEmptyMetric -and [string]::IsNullOrEmpty($MetricObject.Metrics[$Metric])) {
                    Write-Verbose "$Metric skipped as -ExcludeEmptyMetric was specified and the value is null or empty."
                }
                Else {
                    if ($MetricObject.Metrics[$Metric] -isnot [ValueType]) { 
                        $MetricValue = '"' + $MetricObject.Metrics[$Metric] + '"'
                    }
                    else {
                        $MetricValue = $MetricObject.Metrics[$Metric] | Out-InfluxEscapeString
                    }
            
                    "$($MetricObject.Measure | Out-InfluxEscapeString)$TagData $($Metric | Out-InfluxEscapeString)=$MetricValue $timeStampNanoSecs"
                }            
            }
        
            if ($Body) {
                $Body = $Body -Join "`n"
            
                If ($Bulk) {
                    $BulkBody += $Body
                }
                Else {
                    if ($PSCmdlet.ShouldProcess($URI, $Body)) {
                        Invoke-RestMethod -Uri $URI -Method Post -Body $Body -Headers $Headers | Out-Null
                    }
                }
            
            }
        }
        
    }
    End {
        If ($Bulk) {
            $BulkBody = $BulkBody -Join "`n"
            
            if ($PSCmdlet.ShouldProcess($URI, $BulkBody)) {
                Invoke-RestMethod -Uri $URI -Method Post -Body $BulkBody -Headers $Headers | Out-Null
            }
        }
    }
}
