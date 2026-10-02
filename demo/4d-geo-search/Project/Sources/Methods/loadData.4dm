//%attributes = {}
If ((ds:C1482.City.getCount()#0) || (ds:C1482.TouristicSite.getCount()#0))
	// Data tables `City` and/or `TouristicSite` already contain data.
	return 
End if 

var $citiesData : Collection
var $touristicSitesData : Collection

$citiesData:=JSON Parse:C1218(File:C1566("/RESOURCES/japan-cities.json").getText())
$touristicSitesData:=JSON Parse:C1218(File:C1566("/RESOURCES/touristic-sites.json").getText())

var $cityData : Object
var $touristicSiteData : Object

var $cityEntity : cs:C1710.CityEntity
var $touristicSiteEntity : cs:C1710.TouristicSiteEntity

For each ($cityData; $citiesData)
	$cityEntity:=ds:C1482.City.new()
	$cityEntity.nameEN:=$cityData.nameEn
	$cityEntity.nameFR:=$cityData.nameFr
	//$cityEntity.nameAR:=$cityData.nameAr
	$cityEntity.nameJA:=$cityData.nameJa
	$cityEntity.coordinates:=4D:C1709.Vector.new($cityData.coord)
	$cityEntity.wikidataRef:=$cityData.item
	$cityEntity.population:=Num:C11($cityData.population)
	$cityEntity.save()
End for each 

For each ($touristicSiteData; $touristicSitesData)
	$touristicSiteEntity:=ds:C1482.TouristicSite.new()
	$touristicSiteEntity.nameEN:=$touristicSiteData.nameEn
	$touristicSiteEntity.nameFR:=$touristicSiteData.nameFr
	//$touristicSiteEntity.nameAR:=$touristicSiteData.nameAr
	$touristicSiteEntity.nameJA:=$touristicSiteData.nameJa
	$touristicSiteEntity.coordinates:=4D:C1709.Vector.new($touristicSiteData.coord)
	$touristicSiteEntity.wikidataRef:=$touristicSiteData.item
	$touristicSiteEntity.save()
End for each 
