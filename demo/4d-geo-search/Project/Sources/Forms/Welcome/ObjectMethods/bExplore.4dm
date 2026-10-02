Case of 
	: (Form event code:C388=On Load:K2:1)
		
		// Under FluentUI the title of a filled button keeps the theme's own
		// ink, which is unreadable on the accent blue
		If ((FORM theme:C1832="FluentUI") || Is macOS:C1572)
			OBJECT SET RGB COLORS:C628(*; "bExplore"; "white")
		End if 
		
	: (Form event code:C388=On Clicked:K2:4)
		
		// The button's Accept action closes the Welcome window afterwards
		var $window : Integer
		$window:=Open form window:C675("TouristicSiteFinder"; Plain form window:K39:10; Horizontally centered:K39:1; Vertically centered:K39:4)
		SET WINDOW TITLE(Get window title(Current form window); $window)
		DIALOG:C40("TouristicSiteFinder"; *)
		
End case 
