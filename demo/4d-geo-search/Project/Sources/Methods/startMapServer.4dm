//%attributes = {}
// Starts 4D's web server (idempotent) so the Web Area can load map.html over http://.
// Loading over http (not file://) is what lets the browser send a valid Referer to the OSM tile server.

var $server : 4D:C1709.WebServer
$server:=WEB Server:C1674

If (Not:C34($server.isRunning))
	$server.start(New object:C1471(\
		"HTTPEnabled"; True:C214; \
		"HTTPPort"; 8044; \
		"HTTPSEnabled"; False:C215))
End if 
