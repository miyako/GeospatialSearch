Case of 
	: (Form event code:C388=On Data Change:K2:15)
		
		// Run the geographic search query
		citySelected:=ds:C1482.City.get(cityChoices.cityIDs[cityChoices.index])
		nearbySites:=geoQuery(citySelected; maxDistance)
		
		// Update the map view
		nearbySiteSelected:=Null:C1517
		mapData:=buildMapData(citySelected; Null:C1517)
		If (mapReady)
			pushMapData(mapData)
		End if 
		
End case 
