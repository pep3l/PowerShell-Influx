# Send-ResourcePoolMetric

## SYNOPSIS
Sends Resource Pool metrics to Influx.

## SYNTAX

```
Send-ResourcePoolMetric [[-Measure] <String>] [[-Tags] <String[]>] [[-ResourcePool] <String[]>]
 [[-Database] <String>] [[-Server] <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
By default this cmdlet sends metrics for all Resource Pool returned by Get-ResourcePool.

## EXAMPLES

### EXAMPLE 1
```
Send-ResourcePoolMetric -Measure 'TestResources' -Tags Name,NumCpuShares -ResourcePool Test*
```

Description
-----------
This command will submit the specified tags and resource pool metrics to a measure called 'TestResources' for all resource pools starting with 'Test'

## PARAMETERS

### -Measure
The name of the measure to be updated or created.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: ResourcePool
Accept pipeline input: False
Accept wildcard characters: False
```

### -Tags
An array of Resource Pool tags to be included.
Default: 'Name','Parent'

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: ('Name', 'Parent')
Accept pipeline input: False
Accept wildcard characters: False
```

### -ResourcePool
One or more Resource Pools to be queried.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: *
Accept pipeline input: False
Accept wildcard characters: False
```

### -Database
The name of the Influx database to write to.
Default: 'vmware'.
This must exist in Influx!

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: Vmware
Accept pipeline input: False
Accept wildcard characters: False
```

### -Server
The URL and port for the Influx REST API.
Default: 'http://localhost:8086'

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: Http://localhost:8086
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
