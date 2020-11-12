$SNMP = New-Object -ComObject olePrn.OleSNMP
$snmp.open('10.80.64.38','notpublic79',2,1000)
$snmp.get('.1.3.6.1.2.1.1.1.0')
#$snmp.get('.1.3.6.1.4.1.3375.2.4.0.26')
$snmp.GetList()
