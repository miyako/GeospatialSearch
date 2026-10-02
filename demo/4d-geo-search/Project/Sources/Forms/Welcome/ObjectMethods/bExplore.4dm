Case of 
	: (Form event code:C388=On Load:K2:1)
		
		// Under FluentUI the title of a filled button keeps the theme's own
		// ink, which is unreadable on the accent blue
		If ((FORM theme:C1832="FluentUI") || Is macOS:C1572)
			OBJECT SET RGB COLORS:C628(*; "bExplore"; "white")
		End if 
		
	: (Form event code:C388=On Clicked:K2:4)
		
		runTechNote:=True:C214
		
End case 
