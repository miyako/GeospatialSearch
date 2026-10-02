//%attributes = {}
// Formats a single decimal-degree value into DMS notation
// (degrees, minutes, seconds), appending the cardinal symbol
// $positiveSymbol when the value is >= 0, or $negativeSymbol otherwise.
// Example: formatCoordinatesDMS_component(-7.62; "E"; "W") -> "7°37'12\"W"
#DECLARE($value : Real; $positiveSymbol : Text; $negativeSymbol : Text) : Text

var $cardinal : Text
$cardinal:=($value>=0) ? $positiveSymbol : $negativeSymbol

var $abs : Real
$abs:=Abs:C99($value)

var $degrees; $minutes; $seconds : Integer
$degrees:=Int:C8($abs)
$minutes:=Int:C8(($abs-$degrees)*60)
$seconds:=Round:C94((($abs-$degrees)*60-$minutes)*60; 0)

// Handle rounding overflow (e.g. 59.6 seconds -> 60)
If ($seconds>=60)
	$seconds:=$seconds-60
	$minutes:=$minutes+1
End if 
If ($minutes>=60)
	$minutes:=$minutes-60
	$degrees:=$degrees+1
End if 

return String:C10($degrees)+"°"+String:C10($minutes)+"'"+String:C10($seconds)+"\""+$cardinal
