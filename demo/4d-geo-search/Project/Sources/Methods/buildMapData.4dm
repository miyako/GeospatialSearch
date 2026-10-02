//%attributes = {}
// Builds the payload {src:{coords,label}, dst?:{coords,label}} consumed by the
// static map page's updateMap() JavaScript function. $site may be Null.
#DECLARE($city : cs:C1710.CityEntity; $site : cs:C1710.TouristicSiteEntity)->$data : Object

$data:={}
//$data.src:={coords: $city.coordinates.toCollection(); label: $city.nameEN}
$data.src:={coords: $city.coordinates.toCollection(); label: $city.name}

If ($site#Null:C1517)
	//$data.dst:={coords: $site.coordinates.toCollection(); label: $site.nameEN}
	$data.dst:={coords: $site.coordinates.toCollection(); label: $site.name}
End if 
