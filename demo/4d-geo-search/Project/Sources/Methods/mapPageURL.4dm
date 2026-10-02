//%attributes = {}
// Returns the http:// URL of the static Leaflet map page, served by 4D's web server.
// http (not file://) is required so the Web Area sends a valid Referer to the OSM tile server.
#DECLARE->$url : Text

startMapServer()

$url:="http://127.0.0.1:8044/map.html"
