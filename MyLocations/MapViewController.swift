import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController {
  @IBOutlet weak var mapView: MKMapView!
  
  var managedObjectContext: NSManagedObjectContext! {
    didSet {
      NotificationCenter.default.addObserver(forName: Notification.Name.NSManagedObjectContextObjectsDidChange, object: managedObjectContext, queue: OperationQueue.main) { notification in
        if self.isViewLoaded {
          /*
          if let dictionary = notification.userInfo {
            print(dictionary["inserted"])
            print(dictionary["deleted"])
            print(dictionary["updated"])
          }
          */
          self.updateLocations()
        }
      }
    }
  }

  var locations = [Location]()

  override func viewDidLoad() {
    super.viewDidLoad()
    updateLocations()
    
    if !locations.isEmpty {
      showLocations()
    }
  }
  
  @IBAction func showUser() {
    let region = MKCoordinateRegion(
        center: mapView.userLocation.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
    mapView.setRegion(mapView.regionThatFits(region), animated: true)
  }
  
  @IBAction func showLocations() {
    let theRegion = region(for: locations)
    mapView.setRegion(theRegion, animated: true)
  }
  
  func updateLocations() {
    mapView.removeAnnotations(locations)
    
    let entity = Location.entity()
    
    let fetchRequest = NSFetchRequest<Location>()
    fetchRequest.entity = entity
    
    locations = try! managedObjectContext.fetch(fetchRequest)
    mapView.addAnnotations(locations)
  }
  
  func region(for annotations: [MKAnnotation]) -> MKCoordinateRegion {
    let region: MKCoordinateRegion
    
    switch annotations.count {
    case 0:
        region = MKCoordinateRegion(
            center: mapView.userLocation.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
      
    case 1:
      let annotation = annotations[annotations.count - 1]
      region = MKCoordinateRegion(
        center: annotation.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
      
    default:
      var topLeftCoord = CLLocationCoordinate2D(latitude: -90,
                                                longitude: 180)
      var bottomRightCoord = CLLocationCoordinate2D(latitude: 90,
                                                    longitude: -180)
      
      for annotation in annotations {
        topLeftCoord.latitude = max(topLeftCoord.latitude,
                                    annotation.coordinate.latitude)
        topLeftCoord.longitude = min(topLeftCoord.longitude,
                                     annotation.coordinate.longitude)
        bottomRightCoord.latitude = min(bottomRightCoord.latitude,
                                        annotation.coordinate.latitude)
        bottomRightCoord.longitude = max(bottomRightCoord.longitude,
                                         annotation.coordinate.longitude)
      }
      
      let center = CLLocationCoordinate2D(
        latitude: topLeftCoord.latitude -
          (topLeftCoord.latitude - bottomRightCoord.latitude) / 2,
        longitude: topLeftCoord.longitude -
          (topLeftCoord.longitude - bottomRightCoord.longitude) / 2)
      
      let extraSpace = 1.1
      let span = MKCoordinateSpan(
        latitudeDelta: abs(topLeftCoord.latitude -
          bottomRightCoord.latitude) * extraSpace,
        longitudeDelta: abs(topLeftCoord.longitude -
          bottomRightCoord.longitude) * extraSpace)
      
      region = MKCoordinateRegion(center: center, span: span)
    }
    
    return mapView.regionThatFits(region)
  }
  
    @objc func showLocationDetails(sender: UIButton) {
    performSegue(withIdentifier: "EditLocation", sender: sender)
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "EditLocation" {
      let navigationController = segue.destination as! UINavigationController
      let controller = navigationController.topViewController as! LocationDetailsViewController
      controller.managedObjectContext = managedObjectContext
      
      let button = sender as! UIButton
      let location = locations[button.tag]
      controller.locationToEdit = location
    }
  }
}

extension MapViewController: MKMapViewDelegate {
  func mapView(_ mapView: MKMapView,
               viewFor annotation: MKAnnotation) -> MKAnnotationView? {

    guard annotation is Location else {
      return nil
    }

    let identifier = "Location"
    var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
    if annotationView == nil {
      let pinView = MKPinAnnotationView(annotation: annotation,
                                        reuseIdentifier: identifier)
      pinView.isEnabled = true
      pinView.canShowCallout = true
      pinView.animatesDrop = false
      pinView.pinTintColor = UIColor(red: 0.32, green: 0.82,
                                            blue: 0.4, alpha: 1)
      pinView.tintColor = UIColor(white: 0.0, alpha: 0.5)
      
      let rightButton = UIButton(type: .detailDisclosure)
      rightButton.addTarget(self,
                            action: #selector(showLocationDetails),
                            for: .touchUpInside)
      pinView.rightCalloutAccessoryView = rightButton
      
      annotationView = pinView
    }
    
    if let annotationView = annotationView {
      annotationView.annotation = annotation
    
      let button = annotationView.rightCalloutAccessoryView as! UIButton
      if let index = locations.index(of: annotation as! Location) {
        button.tag = index
      }
    }

    return annotationView
  }
}

extension MapViewController: UINavigationBarDelegate {
  func position(for bar: UIBarPositioning) -> UIBarPosition {
    return .topAttached
  }
}
