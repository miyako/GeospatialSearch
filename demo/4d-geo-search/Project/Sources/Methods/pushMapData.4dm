//%attributes = {}
// Pushes the map payload to the static page's updateMap() function (no reload).
#DECLARE($data : Object)

WA EXECUTE JAVASCRIPT FUNCTION:C1043(*; "webMapView"; "updateMap"; *; $data)
