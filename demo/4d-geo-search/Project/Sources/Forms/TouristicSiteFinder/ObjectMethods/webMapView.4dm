Case of 
	: (Form event code:C388=On End URL Loading:K2:47)
		
		// The static page is ready: push the current coordinates.
		mapReady:=True:C214
		If (mapData#Null:C1517)
			pushMapData(mapData)
		End if 
		
End case 
