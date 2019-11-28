﻿Function ConvertTo-InfluxLineString {
    <#
        .SYNOPSIS
            Converts metric objects or data to the Influx line format.

        .DESCRIPTION
            Use to convert some metrics in to the Influx line format for later consumption in to Influx such as via the Telegraf exec plugin.

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

        .PARAMETER ExcludeEmptyMetric
            Switch: Use to exclude null or empty metric values from being processed. Useful where a metric is initially created as an integer but then
            an empty or null instance of that metric would attempt to be sent as an empty string, resulting in a datatype conflict.

        .EXAMPLE
            ConvertTo-InfluxLineString -Measure WebServer -Tags @{Server='Host01'} -Metrics @{CPU=100; Memory=50}
            
            Description
            -----------
            This command will output the provided tag and metric data for a measure called 'WebServer' as strings in the Influx line format.
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

        [switch]
        $ExcludeEmptyMetric
    )
    Begin {
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
                $TagData = ($TagData | Sort-Object) -Join ',' 
            }
            
            #No existance check performed since the parameter is mandatory
            $MetricData = foreach ($Metric in $MetricObject.Metrics.Keys) {
                if ([string]::IsNullOrEmpty($MetricObject.Metrics[$Metric])) {
                    Write-Verbose "$Metric skipped as -ExcludeEmptyMetric was specified and the value is null or empty."
                }
                #if not a number wrap in "" and escape all influx special char
                elseif ($MetricObject.Metrics[$Metric] -isnot [ValueType]) {
                    $MetricValue = '"' + ($MetricObject.Metrics[$Metric] | Out-InfluxEscapeString) + '"'
                }
                #no need to escape numeric values
                else {
                    $MetricValue = $MetricObject.Metrics[$Metric]
                }

                "$($Metric | Out-InfluxEscapeString)=$($MetricValue)"
            }
            $MetricData = $MetricData -Join ','

            $Body = "$($MetricObject.Measure | Out-InfluxEscapeString)"+ $(if($TagData) {","}) + $TagData + " " + $MetricData + $(if($timeStampNanoSecs) {" "}) + $timeStampNanoSecs 

            if ($Body) {
                $Body = $Body -Join "`n"

                if ($PSCmdlet.ShouldProcess($Body)) {
                    Return $Body
                }            
            }
        }
        
    }
    End { }
}
