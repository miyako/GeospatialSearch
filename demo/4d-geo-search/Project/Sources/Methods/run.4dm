//%attributes = {}
#DECLARE($params : Object)

var $windowTitle : Text
$windowTitle:=Localized string("Welcome_WindowTitle")

var $window : Integer

If (Count parameters=0)
	
	// If the demo is already open, bring its window to the front instead of opening a duplicate
	ARRAY LONGINT($windows; 0)
	WINDOW LIST($windows)
	
	var $i : Integer
	For ($i; 1; Size of array($windows))
		$window:=$windows{$i}
		If (Window process($window)=1) && (Get window title($window)=$windowTitle)
			var $left; $top; $right; $bottom : Integer
			GET WINDOW RECT($left; $top; $right; $bottom; $window)
			CALL FORM($window; Formula(SET WINDOW RECT($left; $top; $right; $bottom; $window)))
			return 
		End if 
	End for 
	
	// Run the forms in the application process, without blocking
	CALL WORKER(1; Current method name; {})
	
Else 
	
	SET MENU BAR(1)
	
	$window:=Open form window:C675("Welcome"; Is macOS:C1572 ? Plain form window no title:K39:19 : Plain form window:K39:10; Horizontally centered:K39:1; Vertically centered:K39:4)
	SET WINDOW TITLE($windowTitle; $window)
	DIALOG:C40("Welcome"; *)
	
End if 
