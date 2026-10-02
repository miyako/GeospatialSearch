//%attributes = {}
#DECLARE($city : cs:C1710.CityEntity; $maxDistance : Real)->$sitesWithDistance : Collection

ASSERT:C1129($city#Null:C1517)
ASSERT:C1129($maxDistance>=0)

// MARK: use a formula that calls `geoDistance()` to perform the ORDA query
var $sites : cs:C1710.TouristicSiteSelection
$sites:=ds:C1482.TouristicSite\
.query(Formula:C1597(geoDistance(This:C1470.coordinates; $city.coordinates)<=$maxDistance))\
.orderByFormula(Formula:C1597(geoDistance(This:C1470.coordinates; $city.coordinates)); dk ascending:K85:31)


// MARK: add distances to each resulting touristic site
$sitesWithDistance:=[]

var $site : cs:C1710.TouristicSiteEntity
var $distance : Real
For each ($site; $sites)
	$distance:=geoDistance($site.coordinates; $city.coordinates)
	$sitesWithDistance.push({site: $site; distance: $distance})
End for each 
