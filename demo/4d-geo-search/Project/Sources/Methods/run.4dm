//%attributes = {}
var $windowRef : Integer
$windowRef:=Open form window:C675("Welcome"; Is macOS:C1572 ? Plain form window no title:K39:19 : Plain form window:K39:10; Horizontally centered:K39:1; Vertically centered:K39:4)
DIALOG:C40("Welcome")
CLOSE WINDOW:C154($windowRef)

If (runTechNote)
	$windowRef:=Open form window:C675("TouristicSiteFinder"; Plain form window:K39:10; Horizontally centered:K39:1; Vertically centered:K39:4)
	DIALOG:C40("TouristicSiteFinder")
	CLOSE WINDOW:C154($windowRef)
End if 