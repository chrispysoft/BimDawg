//
//  EFA.swift
//  BimDawg
//
//  LinzAG API Doc (2013)  http://data.linz.gv.at/katalog/linz_ag/linz_ag_linien/fahrplan/LINZ_AG_Linien_Schnitstelle_EFA_v7_Echtzeit.pdf
//  Updated 2015 https://www.data.gv.at/katalog/dataset/9faa1734-607f-4bfd-b8c9-c5692bf37d55
//  Wiener Linien http://data.wien.gv.at/pdf/wiener-linien-routing.pdf
//  OpenVVSDay Repository https://github.com/stz-online/OpenVVSDay
//

import Foundation
import CoreLocation

public class EFAClient {
	private let baseURL = "https://www.linzag.at/static/"
	private let departureLimit = 10
    
    
    public init() {} // needed for test cases only
	
	
	// MARK: - Load Stops
	public enum StopRequest {
		case searchText(String)
		case coordinate(latitude: Double, longitude: Double)
	}
	
	public enum StopResult {
		case success([Stop])
		case failure(EFAError)
	}
	
	private var stopDataTask: URLSessionDataTask?
	
	public func loadStops(for request: StopRequest, completion: @escaping (StopResult) -> Void) {
		stopDataTask?.cancel()
		
		var urlComponents = URLComponents(string: baseURL)!
		urlComponents.path += "XML_STOPFINDER_REQUEST"
		urlComponents.query = "locationServerActive=1&stateless=1&outputFormat=JSON"
		
		let params: String
		switch request {
		case .searchText (let searchText):
			urlComponents.query! += String(format: "&type_sf=stop&name_sf=%@", searchText)
		case .coordinate(let coordinate):
			urlComponents.query! += String(format: "&type_sf=coord&name_sf=%.6f:%.6f:WGS84&coordOutputFormat=WGS84%%5BDD.ddddd%%5D", coordinate.longitude, coordinate.latitude)
		}
		
		let urlRequest = URLRequest(url: urlComponents.url!, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 10)
		let urlSession = URLSession(configuration: .default)
		stopDataTask = urlSession.dataTask(with: urlRequest) { (data, response, error) in
			defer { self.stopDataTask = nil }
			
			var result: StopResult!
			
			if let data = data {
				do {
					let statusCode = (response as! HTTPURLResponse).statusCode
					guard statusCode == 200 else { throw EFAError.badServerResponse(statusCode) }
					
					let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
					guard let rootDict = jsonObject as? [String: Any] else { throw EFAError.jsonParsingError("root") }
					guard let stopFinderDict = rootDict["stopFinder"] as? [String: Any] else { throw EFAError.jsonParsingError("stopFinder") }
					
					switch request {
					case .searchText(_):
						guard let pointsArr = stopFinderDict["points"] as? [[String: Any]] else { throw EFAError.jsonParsingError("points") }
						var stops = [Stop]()
						for plist in pointsArr {
							let stop = try Stop(point: plist)
							stops.append(stop)
						}
						result = .success(stops)
						
					case .coordinate(_):
						if let jsonStopArray = stopFinderDict["itdOdvAssignedStops"] as? [[String: Any]] {
							var stops = [Stop]()
							for plist in jsonStopArray {
								let stop = try Stop(origin: plist)
								stops.append(stop)
							}
							result = .success(stops)
						}
						else if let jsonObject = stopFinderDict["itdOdvAssignedStops"] as? [String: Any] {
							let stop = try Stop(origin: jsonObject)
							result = .success([stop])
						}
						else {
							throw EFAError.jsonParsingError("itdOdvAssignedStops")
						}
					}
				}
				catch let error {
					result = .failure(.downloadError(error))
				}
			}
			else if let error = error {
				result = .failure(.downloadError(error))
			}
			DispatchQueue.main.async {
				completion(result)
			}
		}
		stopDataTask?.resume()
	}
	
	
	// MARK: - Load Lines
	public enum LineResult {
		case success([Line])
		case failure(EFAError)
	}
	
	public func loadLines(for stopID: String, completion: @escaping (LineResult) -> Void) {
		let params = String(format: "XML_DM_REQUEST?locationServerActive=1&stateless=1&outputFormat=JSON&useRealtime=1&mode=direct&type_dm=any&name_dm=%@&limit=%d", stopID, departureLimit)
		let url = URL(string: baseURL+params)!
		downloadJSONObject(from: url) { downloadResult in
			let efaResult: LineResult
			
			switch downloadResult {
			case .success(let jsonObject):
				guard let rootDict        = jsonObject              as? [String: Any] else { completion(.failure(.jsonParsingError("root"))); return }
				guard let servingLinesObj = rootDict["servingLines"] as? [String: Any] else { completion(.failure(.jsonParsingError("servingLines"))); return }
				
				var lines = [Line]()
				
				if let linesArr = servingLinesObj["lines"]	as? [[String: Any]] {
					for linesArrElem in linesArr {
						guard let lineDict = linesArrElem["mode"] as? [String: Any] else { NSLog("Error parsing json object 'mode'"); continue }
						do {
							let line = try Line(jsonDict: lineDict)
							if lines.map({$0.number}).contains(line.number) { continue }
							lines.append(line)
						} catch let error {
							NSLog("Datamodel init error: \(error)")
						}
					}
				}
				
				efaResult = .success(lines)
				
			case .failure(let error as NSError):
				efaResult = .failure(.downloadError(error))
			}
		
			DispatchQueue.main.async {
				completion(efaResult)
			}
		}
	}
	
	
	// MARK: - Load Departures
	public enum DepartureResult {
		case success([Departure])
		case failure(EFAError)
	}
	
	public func loadDepartures(for stopID: String, completion: @escaping (DepartureResult) -> Void) {
		let params = String(format: "XML_DM_REQUEST?locationServerActive=1&stateless=1&outputFormat=JSON&useRealtime=1&mode=direct&type_dm=any&name_dm=%@&limit=%d", stopID, departureLimit)
		let url = URL(string: baseURL+params)!
		downloadJSONObject(from: url) { downloadResult in
			let efaResult: DepartureResult
			
			switch downloadResult {
			case .success(let jsonObject):
				
				if let rootDict = jsonObject as? [String: Any], let departureListArr = rootDict["departureList"] as? [[String: Any]] {
					do {
						var departures = [Departure]()
						for departureObj in departureListArr {
							let departure = try Departure(propertyList: departureObj)
							departures.append(departure)
						}
						efaResult = .success(departures)
					} catch let error {
						efaResult = .failure(.datamodelInit(error))
					}
				}
				else {
					efaResult = .failure(.jsonParsingError("root"))
				}
				
			case .failure(let error as NSError):
				efaResult = .failure(.downloadError(error))
			}
			
			DispatchQueue.main.async {
				completion(efaResult)
			}
		}
	}
	
	
	// MARK: - Load Trip
//    private var tripDataTask: URLSessionDataTask?
//
//    public func loadTrip(from originStopID: String, to destinationStopID: String, completion: @escaping (StopResult) -> Void) {
//        tripDataTask?.cancel()
//
//        var urlComponents = URLComponents(string: baseURL)!
//        urlComponents.path += "XML_TRIP_REQUEST2"
//        urlComponents.query = "locationServerActive=1&stateless=1&outputFormat=JSON"
//        urlComponents.query! += String(format: "&type_origin=stopID&name_origin=%@&type_destination=stopID&name_destination=%@", originStopID, destinationStopID)
//        //urlComponents.query! += String(format: "&type_origin=stopID&name_origin=%@&type_destination=stop&name_destination=%@", originStopID, destinationName)
//
//        NSLog(urlComponents.url!)
//
//        let urlRequest = URLRequest(url: urlComponents.url!, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 10)
//        let urlSession = URLSession(configuration: .default)
//        tripDataTask = urlSession.dataTask(with: urlRequest) { (data, response, error) in
//            defer { self.tripDataTask = nil }
//
//            var result: StopResult!
//
//            if let data = data {
//                do {
//                    let statusCode = (response as! HTTPURLResponse).statusCode
//                    guard statusCode == 200 else { throw EFAError.badServerResponse(statusCode) }
//
//                    let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
//                    guard let rootDict = jsonObject as? [String: Any] else { throw EFAError.jsonParsingError("root") }
//                    guard let stopFinderDict = rootDict["stopFinder"] as? [String: Any] else { throw EFAError.jsonParsingError("stopFinder") }
//
//                    result = .success([])
//                }
//                catch let error {
//                    result = .failure(.downloadError(error))
//                }
//            }
//            else if let error = error {
//                result = .failure(.downloadError(error))
//            }
//            DispatchQueue.main.async {
//                completion(result)
//            }
//        }
//        tripDataTask?.resume()
//    }
	
	
	// MARK: - Generic JSON Download handler
	enum DownloadResult {
		case success(Any)
		case failure(DownloadError)
	}
	enum DownloadError: CustomNSError {
		case httpError(Error)
		case jsonDownloadSerialization(Error)
		case undefined
		
		var localizedDescription: String {
			switch self {
			case .httpError(_):
				return "HTTP error"
			case .jsonDownloadSerialization(_):
				return "JSON serialization error"
			case .undefined:
				return "Undefined error"
			}
		}
	}
	typealias DownloadCompletion = (DownloadResult) -> Void
	
	
	private func downloadJSONObject(from url: URL, completion: @escaping DownloadCompletion) {
		let request = URLRequest(url: url, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 30)
		let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
			let result: DownloadResult
			
			if let data = data {
				do {
					let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
					result = .success(jsonObject)
				} catch let error {
					result = .failure(.jsonDownloadSerialization(error))
				}
			}
			else if let error = error {
				result = .failure(.httpError(error))
			}
			else {
				result = .failure(.undefined)
			}
			
			DispatchQueue.main.async {
				completion(result)
			}
		}
		task.resume()
	}
}


public enum EFAError: CustomNSError {
	case downloadError(Error)
	case badServerResponse(Int)
	case jsonParsingError(String)
	case jsonSerialization(Error)
	case datamodelInit(Error)
	
	public var errorUserInfo: [String : Any] {
		return [NSLocalizedDescriptionKey: localizedDescription]
	}
	
	var localizedDescription: String {
		switch self {
		case .downloadError(let error):
			return "Download error: \(error.localizedDescription)"
		case .badServerResponse(let response):
			return "Bad Server Response: \(response)"
		case .jsonParsingError(let element):
			return "JSON parsing error: '\(element)'"
		case .jsonSerialization(let error):
			return "JSON serialization system error: \(error.localizedDescription)"
		case .datamodelInit(let error):
			return "Datamodel init error: \(error.localizedDescription)"
		}
	}
}


public enum EFATypeError: CustomNSError {
	case initFailed(Any.Type)
	case jsonParsingError(element: String)
	
	public var errorUserInfo: [String : Any] {
		return [NSLocalizedDescriptionKey: localizedDescription]
	}
	
	var localizedDescription: String {
		switch self {
		case .initFailed(let efaType):
			return "EFAType init failed: \(efaType)"
		case .jsonParsingError(let jsonElement):
			return "JSON parsing failed: \(jsonElement)"
		}
	}
}

public struct Stop {
	var id: String
	public var name: String
	var location: CLLocation?
	var distance: Int?
	var lines: [Line] = []
	
	init(origin: [String: Any]) throws {
		guard
			let id = origin["stopID"] as? String,
			let name = origin["name"] as? String,
			let distance = origin["distance"] as? String,
			let x = origin["x"] as? String,
			let y = origin["y"] as? String
			else { throw EFATypeError.initFailed(Stop.self) }
		self.id = id
		self.name = name
		self.location = CLLocation(latitude: Double(y)!, longitude: Double(x)!)
		self.distance = Int(distance)
	}
	
	init(point: [String: Any]) throws {
		guard
			let id = point["stateless"] as? String,
			let name = point["name"] as? String
			else { throw EFATypeError.initFailed(Stop.self) }
		self.id = id
		self.name = name
	}
	
}

public struct Line {
	var name: String
	public var number: String
	var type: String
	var destination: String
	
	init(jsonDict: [String: Any]) throws {
		guard let name        = jsonDict["name"]        as? String else { throw EFATypeError.jsonParsingError(element: "name") }
		guard let number      = jsonDict["number"]      as? String else { throw EFATypeError.jsonParsingError(element: "number") }
		guard let type        = jsonDict["type"]        as? String else { throw EFATypeError.jsonParsingError(element: "type") }
		guard let destination = jsonDict["destination"] as? String else { throw EFATypeError.jsonParsingError(element: "destination") }
		
		self.name = name
		self.number = number
		self.type = type
		self.destination = destination
	}
}

public struct Departure {
	var nameWO: String
	var platform: String
	var stopID: String
	var stopName: String
	var countdown: Int
	var dateTime: DateTime
	var realDateTime: DateTime?
	public var servingLine: ServingLine
	var lineInfos: [LineInfo] = []
	
	var isRealtime: Bool {
		return realDateTime != nil
	}
	
	init(propertyList: [String: Any]) throws {
		guard let nameWO = propertyList["nameWO"] as? String,
			let platform = propertyList["platform"] as? String,
			let stopID = propertyList["stopID"] as? String,
			let stopName = propertyList["stopName"] as? String,
			let countdown = propertyList["countdown"] as? String,
			let dateTimeObj = propertyList["dateTime"] as? [String: Any],
			let servingLineObj = propertyList["servingLine"] as? [String: Any]
			else { throw EFATypeError.initFailed(Departure.self) }
		
		self.nameWO = nameWO
		self.platform = platform
		self.stopID = stopID
		self.stopName = stopName
		self.countdown = Int(countdown) ?? -1
		self.dateTime = try DateTime(propertyList: dateTimeObj)
		self.servingLine = try ServingLine(propertyList: servingLineObj)
		
		if let realDateTimeObj = propertyList["realDateTime"] as? [String: Any] {
			let realDateTime = try? DateTime(propertyList: realDateTimeObj)
			self.realDateTime = realDateTime
		}
		
		if let lineInfoArr = propertyList["lineInfos"] as? [[String: Any]] {
			self.lineInfos = try lineInfoArr.map { try LineInfo(propertyList: $0) }
		}
	}
}

struct DateTime {
	var hour: Int
	var minute: Int
	var day: Int
	var weekday: Int
	var month: Int
	var year: Int
	
	var timeString: String {
		return String(format: "%02d:%02d", hour, minute)
	}
	
	var datetimeString: String {
		return String(format: "%02d.%02d.%d %02d:%02d", day, month, year, hour, minute)
	}
	
	init(propertyList: [String: Any]) throws {
		guard let hour = propertyList["hour"] as? String,
			let minute = propertyList["minute"] as? String,
			let day = propertyList["day"] as? String,
			let weekday = propertyList["weekday"] as? String,
			let month = propertyList["month"] as? String,
			let year = propertyList["year"] as? String
			else { throw EFATypeError.initFailed(DateTime.self) }
		
		self.hour = Int(hour)!
		self.minute = Int(minute)!
		self.day = Int(day)!
		self.weekday = Int(weekday)!
		self.month = Int(month)!
		self.year = Int(year)!
	}
}

public struct ServingLine {
	public var direction: String
	var directionFrom: String
	var name: String
	public var number: String
	var delay: String?
	
	var hasDelay: Bool {
		return delay != nil && delay != "0"
	}
	
	var cleanDirection: String {
		let regex = try! NSRegularExpression(pattern: "Linz ", options: [])
		let result = regex.stringByReplacingMatches(in: direction, options: [], range: NSRange(location: 0, length: direction.count), withTemplate: "")
		return result
	}
	
	init(propertyList: [String: Any]) throws {
		guard let direction = propertyList["direction"] as? String,
			let directionFrom = propertyList["directionFrom"] as? String,
			let name = propertyList["name"] as? String,
			let number = propertyList["number"] as? String,
			let realtime = propertyList["realtime"] as? String
			else { throw EFATypeError.initFailed(ServingLine.self) }
		
		self.direction = direction
		self.directionFrom = directionFrom
		self.name = name
		self.number = number
		
		if realtime == "1" {
			if let delay = propertyList["delay"] as? String {
				self.delay = delay
			}
		}
	}
}

struct LineInfo {
	struct InfoText {
		init(propertyList: [String: Any]) throws {
			
		}
	}
	
	var infoLinkText: String
	var infoLinkURL: String
	var infoText: InfoText
	
	init(propertyList: [String: Any]) throws {
		guard let infoLinkText = propertyList["infoLinkText"] as? String,
			let infoLinkURL = propertyList["infoLinkURL"] as? String,
			let infoTextObj = propertyList["infoText"] as? [String: Any]
			else { throw EFATypeError.initFailed(LineInfo.self) }
		
		self.infoLinkText = infoLinkText
		self.infoLinkURL = infoLinkURL
		self.infoText = try InfoText(propertyList: infoTextObj)
	}
}
