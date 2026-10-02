Case of 
	: (Form event code:C388=On Selection Change:K2:29)
		
		// Update the map view
		If (nearbySiteSelected#Null:C1517)
			mapData:=buildMapData(citySelected; nearbySiteSelected.site)
		Else 
			mapData:=buildMapData(citySelected; Null:C1517)
		End if 
		If (mapReady)
			pushMapData(mapData)
		End if 
		
End case 
