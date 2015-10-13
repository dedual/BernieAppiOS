import Foundation
import CoreLocation

class ConcreteEventRepository: EventRepository {
    private let geocoder: CLGeocoder
    private let urlProvider: URLProvider
    private let jsonClient: JSONClient
    private let eventDeserializer: EventDeserializer
    private let operationQueue: NSOperationQueue

    init(
        geocoder: CLGeocoder,
        urlProvider: URLProvider,
        jsonClient: JSONClient,
        eventDeserializer: EventDeserializer,
        operationQueue: NSOperationQueue) {
            self.geocoder = geocoder
            self.urlProvider = urlProvider
            self.jsonClient = jsonClient
            self.eventDeserializer = eventDeserializer
            self.operationQueue = operationQueue
    }


    func fetchEventsWithZipCode(zipCode: String, radiusMiles: Float, completion: (Array<Event>) -> Void, error: (NSError) -> Void) {
        self.geocoder.geocodeAddressString(zipCode, completionHandler: { (placemarks, geocodingError) -> Void in
            if(geocodingError != nil) {
                error(geocodingError!)
                return
            }

            let placemark = placemarks!.first!
            let location = placemark.location!

            let url = self.urlProvider.eventsURL()


            let HTTPBodyDictionary = self.HTTPBodyDictionaryWithLatitude(
                location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                radiusMiles: radiusMiles)

            let eventsPromise = self.jsonClient.JSONPromiseWithURL(url, method: "POST", bodyDictionary: HTTPBodyDictionary)

            eventsPromise.then({ (jsonDictionary) -> AnyObject! in
                let parsedEvents = self.eventDeserializer.deserializeEvents(jsonDictionary as! NSDictionary)

                self.operationQueue.addOperationWithBlock({ () -> Void in
                    completion(parsedEvents)
                })

                return parsedEvents
                }, error: { (receivedError) -> AnyObject! in
                    self.operationQueue.addOperationWithBlock({ () -> Void in
                        error(receivedError!)
                    })
                    return receivedError
            })
        })
    }

    // MARK: Private

    func HTTPBodyDictionaryWithLatitude(latitude: CLLocationDegrees, longitude: CLLocationDegrees, radiusMiles: Float) -> NSDictionary {
        let filterConditions : Array = [
            [
                "geo_distance": [
                    "distance": "\(radiusMiles)mi",
                    "location": [
                        "lat": latitude,
                        "lon": longitude
                    ]
                ]
            ],
            [
                "range": [
                    "start_time": [
                        "lte": "now+6M/d",
                        "gte": "now"
                    ]
                ]
            ]
        ]


        return [
            "from": 0, "size": 30,
            "query": [
                "filtered": [
                    "query": [
                        "match_all": []
                    ],
                    "filter": [
                        "bool": [
                            "must": filterConditions
                        ]
                    ]
                ]
            ],
            "sort": [
                "_geo_distance": [
                    "location": [
                        "lat":  latitude,
                        "lon": longitude
                    ],
                    "order":         "asc",
                    "unit":          "km",
                    "distance_type": "plane"
                ]
            ]
        ]
    }
}
