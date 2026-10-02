# Project Title

Geospatial Search with 4D, ORDA and 4D.Vector

## Description

This technical note demonstrates how to build a geospatial search application using 4D, ORDA, and 4D.Vector. Using GPS coordinates (latitude and longitude), the application allows users to select a Moroccan city and search for tourist sites within a specified radius. Distances are calculated through a single ORDA query, results are sorted from nearest to farthest, and displayed both as a list and on an interactive map generated using Leaflet and OpenStreetMap. The example highlights how 4D can be used to create efficient location-based services commonly found in tourism, transportation, delivery, and real estate applications.

## Getting Started

### Pre-requisites

Windows
Windows 11
Windows Server 2016 – Windows Server 2025
The latest major Windows release is required, such as Windows 11 version 25H2.

macOS
macOS Sonoma (14) – macOS Tahoe (26)
The latest release of the major version is required, such as version 15.7.2.

* Download the latest Release version of 4D from: https://us.4d.com/product-download or the latest Beta version from: https://discuss.4d.com
* Follow the activation steps for 4D from: https://developer.4d.com/docs/GettingStarted/installation and https://developer.4d.com/docs/Admin/licenses


### Executing the Project

* Open the project in 4D 
* create new datafile 
* selects a city and a Touristic site, the application uses ORDA and the geoDistance() method to find and sort nearby tourist sites.
The results are then displayed on an interactive map generated with Leaflet and OpenStreetMap, embedded in a 4D Web Area, allowing users to visualize the locations and their geographic distribution.

## Authors

Karim Meghraoui
[Karim.meghraoui@4D.com](Karim.meghraoui@4D.com)