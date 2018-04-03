//
//  WeatherViewController.swift
//  MyWeatherApp
//
//  Created by WanliMa on 2018/4/2.
//  Copyright © 2018年 WanliMa. All rights reserved.
//

import UIKit
import CoreLocation

import Alamofire
import SwiftyJSON


class WeatherViewController: UIViewController, CLLocationManagerDelegate {
    
    // MARK - constants
    let WEATHER_API = "https://api.openweathermap.org/data/2.5/weather"
    let APP_ID = "17ef502fb892835b7b39e5244ee161dc"
    
    // MARK: - instance
    let weatherDataModel = WeatherDataModel()
    let locationManager = CLLocationManager()
    
    // MARK: -outlets
    @IBOutlet weak var city: UILabel!
    @IBOutlet weak var temperature: UILabel!
    @IBOutlet weak var weatherIcon: UIImageView!
    @IBOutlet weak var degreeUnit: UISegmentedControl!
    
    @IBOutlet weak var newCityName: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters  // 定位准确性
        locationManager.requestWhenInUseAuthorization() // ask permission
        locationManager.startUpdatingLocation() // Asycn
        locationManager.startMonitoringSignificantLocationChanges()
        
         (UIApplication.shared.delegate as! AppDelegate).weatherVC = self    // 获取AppDelegate reference
    }
    
    // MARK: - Restful
    // getWeatherData from open weather api
    func getWeatherData(url: String) {
        Alamofire.request(url, method: .get).responseJSON(completionHandler: {
            res in
            if res.result.isSuccess {
                print("request succeed!")
                
                let weatherData = JSON(res.result.value!)
                
                if weatherData["cod"].int! < 400 {
                    print(weatherData)
                    self.updateWeatherModel(data: weatherData)
                }
                else {
                    self.city.text = "Weather unavailable"
                }
            }
            else {
                self.city.text = "Internet issue"
                print(res)
            }
        })
    }
    
    
    // MARK: - update Model
    // updateWeatherModel from restful request
    func updateWeatherModel(data: JSON) {
        var temperatureData = data["main"]["temp"].double!
        
        if degreeUnit.titleForSegment(at: degreeUnit.selectedSegmentIndex) == "C" {
            temperatureData -= 273.15
        }
        
        weatherDataModel.temperature = temperatureData
        weatherDataModel.city = data["name"].stringValue
        weatherDataModel.condition = data["weather"][0]["id"].int!
        weatherDataModel.weatherIconName = weatherDataModel.updateWeatherIcon(condition: weatherDataModel.condition)
        
        updateWeatherViews()
    }
    
    // MARK: - update UI
    // updateUIWithWeatherData from Model
    func updateWeatherViews() {
        city.text = weatherDataModel.city
        temperature.text = String(round(weatherDataModel.temperature)) + "°"
        weatherIcon.image = UIImage(named: weatherDataModel.weatherIconName)
    }
    
    // Mark: - toggelDegreeUnit
    @IBAction func toggleDegreeUnit(_ sender: UISegmentedControl) {
        if sender.titleForSegment(at: sender.selectedSegmentIndex) == "F" {
            weatherDataModel.temperature += 273.15
        }
        else if sender.titleForSegment(at: sender.selectedSegmentIndex) == "C" {
            weatherDataModel.temperature -= 273.15
        }
        
        updateWeatherViews()
    }
    
    // Mark: - sugue to change city VC
    
    // MARK: - update city delegate
    
    // MARK: - callback didUpdateLocations
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {  // 定位过程中，locations array会越来越精确
            if location.horizontalAccuracy > 0 {    // 定位所在范围的半径。负数为invalid
                locationManager.stopUpdatingLocation()
                
                let lat = String(location.coordinate.latitude)
                let lon = String(location.coordinate.longitude)
                
                let url = "\(WEATHER_API)?lat=\(lat)&lon=\(lon)&appid=\(APP_ID)"
                getWeatherData(url: url)
            }
        }
    }

    @IBAction func getMyLocationWeather() {
        locationManager.startUpdatingLocation()
    }
    
    @IBAction func getNewCityWeather() {
        let normalizedCityName = newCityName.text!.trimmingCharacters(in: .whitespacesAndNewlines).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let url = "\(WEATHER_API)?q=\(normalizedCityName)&appid=\(APP_ID)"
        
        getWeatherData(url: url)
    }
}
