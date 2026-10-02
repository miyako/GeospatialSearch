Case of 
	: (Form event code:C388=On Data Change:K2:15)
		// Run the geographic search query
		nearbySites:=geoQuery(citySelected; maxDistance)
		
		// Update map view (only if a touristic site was selected)
		If (nearbySiteSelected#Null:C1517)
			nearbySiteSelected:=Null:C1517
			mapData:=buildMapData(citySelected; Null:C1517)
			If (mapReady)
				pushMapData(mapData)
			End if 
		End if 
		
End case 
