# Retrac

## About Retrac
|           |                                              |
| --------- | -------------------------------------------- |
| Author    | Nnoduka Eruchalu                             |
| Date      | 08/01/2014                                   |
| Website   | [http://RetracApp.com](http://RetracApp.com) |
| App Store | [Download on the App Store](https://itunes.apple.com/us/app/retrac/id906573871?ls=1&mt=8) |


### Motivation
Way too many people forget where they parked their cars and no app provides a 
simple way to retrace steps. Retrac solves this somewhat obvious problem.


## Software Description
### 3rd-party Objective-C Modules
* [SVPulsingAnnotationView](https://github.com/TransitApp/SVPulsingAnnotationView)


## Core Data Design Decisions
### Fetch Batch Size
* On an iPhone only 10 rows are visible 
* So doesn't make sense to fetch every possible object
* Hence chose to use a fetch batch size of 20


## Testing
Generate gpx files here: [http://gpx-poi.com](http://gpx-poi.com)