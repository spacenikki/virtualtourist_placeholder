//
//  FlickrConvenience.swift
//  virtualTourist
//
//  Created by Nikki L on 11/12/17.
//  Copyright © 2017 Nikki. All rights reserved.
// Contains all network calls only

import Foundation

class FlickrConvenience: NSObject {

    var totalPages: Int? = nil  // change according to what is returned - this needs to be a sharedInstance, otherwise, it won;t be reset @ mapViewController when user hits "back", and do anohter pin.
    
    let stack = CoreDataStack.sharedInstance() // @ struct CoreDataStack.swift - init(modelName: String) -> it's expecting modelname input, modelnames can be found @  Model.xcdatamodeid file - which is "Model" (not Pin/ Photo - theses r entities)

    // MARK: All network calls should be here
    
    func getPhotoTotalPage(_ methodParameters: [String: AnyObject], _ completionHandlerForGetTotalPages: @escaping (_ totalPages: Int?, _ error: NSError?) -> Void) -> URLSessionDataTask { // error will be sent back to UI view - so that we can display on UI
        
        // When network call from func getPhotoArrayFromFlickrWithRandomPage returns, it comes with photoArray, and then pass it to completionHandlerForGetTotalPages back to viewController. And do the work there.. OR
        
        print("func getPhotoTotalPage is called ")
        // create session and request
        let session = URLSession.shared
        // 3. call a helper func to pass "url" as input to make the network call
        let request = URLRequest(url: flickrURLFromParameters(methodParameters))
        
        // create network request - check Flickr's app for the codes
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            
            // if an error occurs, print it and pass it to completion handler and it will be passed to the viewController where is calling this func
            func sendError(_ error: String) {
                print(error)
                let userInfo = [NSLocalizedDescriptionKey : error] // key:value pair - value is the error.String
                completionHandlerForGetTotalPages(nil, NSError(domain: "getPhotoTotalPageFromFlickr", code: 1, userInfo: userInfo))
            }
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                // unwrap "optional" error (since Guard ... already save value to error - only need when sth = nil - wouldn't work if we assign totalPage = some value!
                if let error = error {
                    sendError("\(error.localizedDescription)") // convert an "NSerror" to "errorString"
                }
                return
            }
            
            // no error - have data or response
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                // if data == nil, do below
                sendError("No data was returned by getTotalPages Request")
                return
            }
            
            // after passing "guard let data=data" - means data != nil now...
            print("data for totalPages is -", NSString(data:data, encoding: String.Encoding.utf8.rawValue)!)
            print("data is ...\(data)")
            
            // look at what data comes back, get the total page, then pass it to the second func by passing it to the completion handler...
            
            // parse the data - to get the totalPage ONLY - this is to show corrupted data
            let parsedResult : [String: AnyObject]! // cuz JSON response can have String:[Array] or String:{Dict} or String:[Array:{Dict}]
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:AnyObject] // "as!" to force downcast!
            } catch {
                sendError("Could not parse the data as JSON '\(data)' from getTotalPages")
                return
            }
            
            /* GUARD: check inside parsedResult Did Flickr return an error (stat!= ok)? */
            guard let stat = parsedResult[Constants.FlickrResponseKeys.Status] as? String, stat == Constants.FlickrResponseValues.OKStatus else { // something is wrong if status code != 200 OK
                sendError("Flickr API returned an error from getTotalPage. See error code and message in \(parsedResult)")
                return
            }
            
            // we need keys "photos" & "totalPage" exist -> to get totalPage
            /* GUARD: Is "photos" key in our result? */
            guard let photosDictionary = parsedResult[Constants.FlickrResponseKeys.Photos] as? [String: AnyObject] else {
                // display Error
                sendError("Cannot find keys '\(Constants.FlickrResponseKeys.Photos) in \(parsedResult)")
                return
            }
            
            /* GUARD: is "pages" key in photosDictionary? */
            guard let totalPages = photosDictionary[Constants.FlickrResponseKeys.Pages] as? Int else {
                sendError("Cannot find key '\(Constants.FlickrResponseKeys.Pages)' in \(photosDictionary)")
                return
            }
            
            self.totalPages = totalPages
            
            
            // pass "pages" to completionHandler
            completionHandlerForGetTotalPages(self.totalPages, error as NSError?)
            // EXIT
        }
        
        task.resume()
        return task
        
    } // end of private func getPhotoTotalPage
    
    // MARK - call below func ONCE inside func "getPhotoTotalPageFromFlickrBySearch" & also when user tap "New Collection" - this func RETURNS ACTUAL PHOTO
    // Call below func @ ViewController, inside this func, call another func that returns totalPage, so that we can calculate the randPage. And pass it another network call to get photoArray, and pass it back to completion Hanlder, which is returned @ ViewController
    
    // bboxString already includes latitude/ longitude as a parameter to ask server
    private func bboxString(_ latitude: Double, _ longitude: Double) -> String {
        
        // ASK MENTOR ?? do i still need to check if self.lon has something? but with i wrote if let latitude = self.lat -> it raised error...
        
        // ensure bbox is bounded by min and max
        let minimumLon = max(longitude - Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.0)
        let minimumLat = max(latitude - Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.0)
        let maximumLon = min(longitude + Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.1)
        let maximumLat = min(latitude + Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.1)
        return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
    }
    
    
    func getPhotoArrayByRandPage(_ currentPin: Pin, _ completionHandlerForPhotoArray: @escaping (_ photoArray: [[String: AnyObject]]?, _ error: NSError?) -> Void) -> URLSessionDataTask {
        
        let methodParameters = [
            Constants.FlickrParameterKeys.Method : Constants.FlickrParameterValues.SearchMethod,
            Constants.FlickrParameterKeys.APIKey : Constants.FlickrParameterValues.APIKey,
            // need to add bboxstring here. we need lon, and lat. ...
            Constants.FlickrParameterKeys.BoundingBox : bboxString(currentPin.latitude, currentPin.longitude),
            Constants.FlickrParameterKeys.SafeSearch : Constants.FlickrParameterValues.UseSafeSearch,
            Constants.FlickrParameterKeys.Extras : Constants.FlickrParameterValues.MediumURL,
            Constants.FlickrParameterKeys.Format : Constants.FlickrParameterValues.ResponseFormat,
            Constants.FlickrParameterKeys.NoJsonCallback : Constants.FlickrParameterValues.DisableJSONCallback,
            ]
        
        
        print("returning totalPage is... ") // 50
   
        // call .getPhotoTotalPage here -> getPhotoTotalPage call is a "URLSessionDataTask"??
       let getTotalPagesCall = self.getPhotoTotalPage(methodParameters as [String : AnyObject]) { (totalPage, error) in
        
            print("total page is \(self.totalPages)") // totalPage is returned
            self.totalPages = totalPage // reset this @ viewWillAppear @ mapViewController
        
            // needs randPage Calcuation + call .getPhotoArray network call with randPage
            let pageLimit = min(self.totalPages!, 60)
            let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
            let randomPageString = String(randomPage)
            print("randomPageString is \(randomPageString)")
        
            // call another netowrk call, add new parameter and get the photoArray on this randPage
            // add randPage to parameter...
            var methodParametersWithPageNumber = methodParameters
            methodParametersWithPageNumber[Constants.FlickrParameterKeys.Page] = randomPageString // ASK
        
            // add "per_page" to methodParameters -> to limit only 27 photos are downloaded at each call
            methodParametersWithPageNumber[Constants.FlickrParameterKeys.PhotosPerCall] = Constants.FlickrParameterValues.PhotosPerCall  // Passing String "27"
        
            // Make another network call, this time, search with the random number obtained from above
            // create session and request
            let session = URLSession.shared
            // call a helper func to pass "url" as input to make the network call
            let request = URLRequest(url: self.flickrURLFromParameters(methodParametersWithPageNumber as [String : AnyObject]))
            
            // create network request - check Flickr's app for the codes
            // below can be copied from func getTotalPages that also does .dataTask network call
            // check Flickr app's func displayImageFromFlickrBySearch code + OnTheMap's code
            // since it's a repeated process to parsedResult... re-use func convertDataWithCompletionHandler call -> not neccessary as Virtual Tourist only need to parse result twice
            
            let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
                
                // create func sendError to handle error
                func sendError(_ error: String){
                    print(error)
                    let userInfo = [NSLocalizedDescriptionKey: error] // key:value pair - value is the error.String
                    completionHandlerForPhotoArray(nil, NSError(domain: "getPhotoArrayFromFlickr", code: 1, userInfo: userInfo))
                }
                
                // check what onthemap app has to deal with error, data, response (stat code, may have to change it here and @ the func fetTotalPage
                /* GUARD: Was there an error? */
                guard (error == nil) else {
                    if let error = error { // unwrap error that is optional - error here is NSerror still
                        print(error)
                        sendError("\(error.localizedDescription)")
                    }
                return
                }
                
                /* no error - have data/ response */
                /* GUARD: Was there any data returned? */
                guard let data = data else {
                    // if data has nothing...
                    sendError("No data was returned by getPhotoArray Request")
                    return
                }
                
                // after passing "guard let data=data"- means data != nil now
                print("data for Photo Array is", NSString(data:data, encoding: String.Encoding.utf8.rawValue)!)
                print("data is ...\(data)")
                
                // JSONate the data
                let parsedResult : [String: AnyObject]! // cuz JSON response can have String:[Array] or String:{Dict} or String:[Array:{Dict}]
                do {
                    parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: AnyObject] // "as!" to force downcast!
                } catch {
                    sendError("Could not prase the data as JSON '\(data)' from getPhotoArray")
                    return
                }
                
                /* GUARD: check inside parsedResult - Did Flickr return an error (stat!= ok)? */
                guard let stat = parsedResult[Constants.FlickrResponseKeys.Status] as? String, stat == Constants.FlickrResponseValues.OKStatus else {
                    sendError("Flickr API returned an error from getPhotoArray. See error code and message in \(parsedResult)")
                    return
                }
                
                // Check if keys we are looking for is in photoDictionary
                /* GUARD - Is the "photos" key in our result? */
                guard let photosDictionary = parsedResult[Constants.FlickrResponseKeys.Photos] as? [String: AnyObject] else {
                    sendError("Cannot find keys '\(Constants.FlickrResponseKeys.Photos) in \(parsedResult) in photoDictionary")
                    return
                }
                print("photo dictionary is \(photosDictionary)")
                // Data returned is from that ONE random page - now, get PhotoArray!
                /* GUARD - is "photo" key in photosDictionary? */
                guard let photosArray = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String: AnyObject]] else {
                    sendError("Cannot find the key '\(Constants.FlickrResponseKeys.Photo)' in photoArray")
                    return
                }
                
                // Passing photoArray to completionHandler, and go back to the MapViewController
                completionHandlerForPhotoArray(photosArray, nil)
 
            } // END of let task = dataTask
            
            task.resume()
            
        } // END of let getTotalPagesCall = self.getPhotoTotalPage
        
        return getTotalPagesCall

    } // END of private func getPhotoArrayByRandPage
    
    func getImageData(_ currentCellPhoto: Photo, _ ImageURLString: String, completionHandlerForGetImageData: @escaping (_ imageData: NSData?, _ error: NSError?) -> Void) -> URLSessionTask { // return nothing, as we just gonna update the coreData directly
        
        // convert String to url
        let imageURL = URL(string: ImageURLString)
        
        let session = URLSession.shared
        
        let task = session.dataTask(with: imageURL!) { (data, response, error) in
            
            // download has finished
            
            // handle error
            guard (error == nil) else {
                // has error:
                if let error = error {
                    print("Error downloading photo: \(error)")
                    completionHandlerForGetImageData(nil, error as NSError?)
                }
            return
            } // END of guard (error == nil) else {
            
            // check for response code
            if let res = response as? HTTPURLResponse {
                print("Downloaded photo with response code \(res.statusCode)")
            }
            
            // deal with returned data!
            if let returnedImageData = data {
                // add to photo's property
                DispatchQueue.main.async {
                    currentCellPhoto.imageData = returnedImageData as NSData? // Photo's @NSManaged public var imageData: NSData?
                }
                
                // should I update view here??? not really... - because you will block the UI as there are lots of photos! - do it at PhotoAlbumViewController...
                completionHandlerForGetImageData(returnedImageData as NSData, nil)
            }
        } // END of let task =
        task.resume()
        return task
    } // END of getImageData()
    
    // 3. Create a helper func make "url", so we can pass it to func "" inside the network call
    private func flickrURLFromParameters(_ parameters: [String:AnyObject]) -> URL {
        
        var components = URLComponents()
        components.scheme = Constants.Flickr.APIScheme
        components.host = Constants.Flickr.APIHost
        components.path = Constants.Flickr.APIPath
        /* Above already add .scheme/ .host/ .path these properties to components
         to form -> https://api.flickr.com/services/rest/? */
        
        components.queryItems = [URLQueryItem]() // declare a property queryItems and create an array for it, so we can start adding DICT key:value to this array. This array datatype is URLQueryItem (= A single name-value pair)
        
        for (key, value) in parameters {
            // CONVERT parameter's dictionary to TYPE queryItem's dictionary
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            
            // APPEND EACH pair of queryItem's dictionary to array [components.queryItems]
            components.queryItems!.append(queryItem)
        } // END of for loop
        
        return components.url! // includes components's scheme, host, path, and dictionary from "parameters"
        
    } // END of private func flickrURLFromParameters

    /* MARK: Shared Instance  -- A singleton class returns the same instance no matter how many times an application requests it. "FlickrConvenience" is the return object of a singleton
        so that totalPage can be reset @ VC and write FlickrConvenience.sharedInstance.totalPages to rest the totalPages variable from FlickrConvenience */
    // NEED TO KEEP THIS -> AS ONLY WAY TO GET .total{ages here ?!?!
    class func sharedInstance() -> FlickrConvenience {
        struct Singleton {
            static var sharedInstance = FlickrConvenience()
        }
        return Singleton.sharedInstance
    }

} // END of class FlickrConvenience: NSObject {


    











