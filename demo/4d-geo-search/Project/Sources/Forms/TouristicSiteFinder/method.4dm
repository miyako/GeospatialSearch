Case of 
	: (Form event code:C388=On Load:K2:1)
		
		// Initialize form variables
		var maxDistance : Integer
		var cityChoices : Object
		var citySelected : cs:C1710.CityEntity
		var nearbySites : Collection
		var nearbySiteSelected : Object
		var mapViewURL : Text
		var mapData : Object
		var mapReady : Boolean
		
		maxDistance:=200
		cityChoices:={}
		nearbySites:=[]
		nearbySiteSelected:=Null:C1517
		mapData:=Null:C1517
		mapReady:=False:C215
		
		// Load the static map page once; coordinates are pushed via `updateMap()`
		mapViewURL:=mapPageURL()
		
		// Load known cities from table `ds.City`
		var $knownCities : cs:C1710.CitySelection
		$knownCities:=ds:C1482.City.all().orderBy("nameEN")
		cityChoices.values:=$knownCities.extract("nameEN")
		cityChoices.cityIDs:=$knownCities.extract("ID")
		cityChoices.index:=0
		
		If (cityChoices.cityIDs.length#0)
			// Use the first selected city (by default) to perform the geo query
			citySelected:=ds:C1482.City.get(cityChoices.cityIDs[cityChoices.index])
			nearbySites:=geoQuery(citySelected; maxDistance)
			
			// Built now, pushed once the page finishes loading (On End URL Loading)
			mapData:=buildMapData(citySelected; Null:C1517)
		End if 
End case 
