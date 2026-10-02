//%attributes = {}
// Serves only Resources/map.html to the Web Area. Nothing else in Resources is exposed.
#DECLARE($url : Text; $header : Text; $ipClient : Text; $ipServer : Text; $user : Text; $password : Text)

Case of 
	: ($url="/") | ($url="/map.html")
		WEB SEND FILE:C619(File:C1566("/RESOURCES/map.html").platformPath)
End case 
