Class extends Entity

Function get name() : Text
	
	var $lang : Text
	$lang:=Get database localization:C1009(Current localization:K5:22)
	
	Case of 
		: ($lang="ja")
			
			return This:C1470.nameJA
			
		: ($lang="fr")
			
			return This:C1470.nameFR
			
		Else 
			
			return This:C1470.nameEN
			
	End case 

Function orderBy name($event : Object) : Text
	
	var $lang : Text
	$lang:=Get database localization:C1009(Current localization:K5:22)
	
	Case of 
		: ($lang="ja")
			
			return "nameJA "+$event.operator
			
		: ($lang="fr")
			
			return "nameFR "+$event.operator
			
		Else 
			
			return "nameEN "+$event.operator
			
	End case 