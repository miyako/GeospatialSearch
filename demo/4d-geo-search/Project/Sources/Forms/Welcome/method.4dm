Case of 
	: (Form event code:C388=On Load:K2:1)
		
		var cityCount : Integer
		var siteCount : Integer
		
		cityCount:=ds:C1482.City.getCount()
		siteCount:=ds:C1482.TouristicSite.getCount()
		
End case 
