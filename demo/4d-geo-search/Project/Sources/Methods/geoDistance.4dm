//%attributes = {}
// Computes the distance in kilometers between two geographic points expressed
// as 4D.Vector with two components [latitude; longitude] (decimal degrees),
// using the Haversine formula.
// See: https://en.wikipedia.org/wiki/Haversine_formula
#DECLARE($coordsA : 4D:C1709.Vector; $coordsB : 4D:C1709.Vector) : Real

If (($coordsA=Null:C1517) || ($coordsB=Null:C1517))
	return Num:C11("INF")
End if 

If (($coordsA.length#2) || ($coordsB.length#2))
	return Num:C11("INF")
End if 

var $earthRadius : Real
$earthRadius:=6371  // Mean radius of the Earth in kilometers

var $latA; $lonA; $latB; $lonB : Real
$latA:=$coordsA[0]*Degree:K30:2
$lonA:=$coordsA[1]*Degree:K30:2
$latB:=$coordsB[0]*Degree:K30:2
$lonB:=$coordsB[1]*Degree:K30:2

var $havCentralAngle; $centralAngle : Real
$havCentralAngle:=(Sin:C17(($latA-$latB)/2)^2)+(Cos:C18($latA)*Cos:C18($latB)*(Sin:C17(($lonA-$lonB)/2)^2))

If ($havCentralAngle>=1)  // Antipodal points (avoids a division by zero)
	$centralAngle:=Pi:K30:1
Else 
	$centralAngle:=2*Arctan:C20(Square root:C539($havCentralAngle)/Square root:C539(1-$havCentralAngle))
End if 

return $earthRadius*$centralAngle
