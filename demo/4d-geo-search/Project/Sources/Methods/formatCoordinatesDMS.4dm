//%attributes = {}
// Formats geographic coordinates expressed as a 4D.Vector with two components
// [latitude; longitude] (decimal degrees) into DMS notation
// (degrees, minutes, seconds) using the cardinal symbols N, S, E, W.
// Example: 4D.Vector.new([33.5992; -7.62]) -> "33°35'57\"N 7°37'12\"W"
#DECLARE($coords : 4D:C1709.Vector) : Text

If ($coords=Null:C1517)
	return ""
End if 

If ($coords.length#2)
	return ""
End if 

var $lat; $lon : Text
$lat:=formatCoordinatesDMS_component($coords[0]; "N"; "S")
$lon:=formatCoordinatesDMS_component($coords[1]; "E"; "W")

return $lat+" "+$lon
