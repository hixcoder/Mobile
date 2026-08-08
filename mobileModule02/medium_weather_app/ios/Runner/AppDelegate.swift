import CoreLocation
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var geolocationHandler: GeolocationHandler?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    geolocationHandler = GeolocationHandler()
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "GeolocationPlugin") else {
      return
    }

    let channel = FlutterMethodChannel(
      name: "com.example.weather_app/geolocation",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      self?.geolocationHandler?.handle(call: call, result: result)
    }
  }
}

private class GeolocationHandler: NSObject, CLLocationManagerDelegate {
  private let locationManager = CLLocationManager()
  private var pendingResult: FlutterResult?

  private func authorizationStatus(for manager: CLLocationManager) -> CLAuthorizationStatus {
    if #available(iOS 14.0, *) {
      return manager.authorizationStatus
    } else {
      return CLLocationManager.authorizationStatus()
    }
  }

  func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getCurrentLocation":
      getCurrentLocation(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func getCurrentLocation(result: @escaping FlutterResult) {
    guard CLLocationManager.locationServicesEnabled() else {
      result(["error": "serviceDisabled"])
      return
    }

    switch authorizationStatus(for: locationManager) {
    case .authorizedAlways, .authorizedWhenInUse:
      requestLocationUpdate(result: result)
    case .notDetermined:
      pendingResult = result
      locationManager.delegate = self
      locationManager.requestWhenInUseAuthorization()
    case .denied:
      result(["error": "permissionDenied"])
    case .restricted:
      result(["error": "permissionDeniedForever"])
    @unknown default:
      result(["error": "serviceDisabled"])
    }
  }

  private func requestLocationUpdate(result: @escaping FlutterResult) {
    pendingResult = result
    locationManager.delegate = self
    locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    locationManager.requestLocation()
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    handleAuthorizationChange(for: manager)
  }

  func locationManager(
    _ manager: CLLocationManager,
    didChangeAuthorization status: CLAuthorizationStatus
  ) {
    if #available(iOS 14.0, *) {
      return
    }
    handleAuthorizationChange(for: manager)
  }

  private func handleAuthorizationChange(for manager: CLLocationManager) {
    guard let result = pendingResult else {
      return
    }

    switch authorizationStatus(for: manager) {
    case .authorizedAlways, .authorizedWhenInUse:
      pendingResult = result
      manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
      manager.requestLocation()
    case .denied:
      pendingResult = nil
      result(["error": "permissionDenied"])
    case .restricted:
      pendingResult = nil
      result(["error": "permissionDeniedForever"])
    case .notDetermined:
      break
    @unknown default:
      pendingResult = nil
      result(["error": "serviceDisabled"])
    }
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let result = pendingResult, let location = locations.last else {
      return
    }

    pendingResult = nil
    result([
      "latitude": location.coordinate.latitude,
      "longitude": location.coordinate.longitude,
    ])
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    guard let result = pendingResult else {
      return
    }

    pendingResult = nil

    if let clError = error as? CLError, clError.code == .denied {
      result(["error": "permissionDenied"])
      return
    }

    result(["error": "serviceDisabled"])
  }
}
