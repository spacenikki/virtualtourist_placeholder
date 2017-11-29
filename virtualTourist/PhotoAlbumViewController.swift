//
//  PhotoAlbumViewController.swift
//  virtualTourist
//
//  Created by Nikki L on 11/12/17.
//  Copyright © 2017 Nikki. All rights reserved.
//

import UIKit

class PhotoAlbumViewController: UIViewController {
    @IBOutlet weak var noPhotoLabel: UILabel!  // hide it if PhotoArray > 0
    @IBOutlet weak var newCollection: UIButton!
    
    @IBAction func newCollection(_ sender: Any) {
        // not resetting TotalPage but calling func "getPhotoArrayFromFlickrWithRandomPage"
        
    }
    
    var currentPinObject:Pin? //  Error raised if -> var currentPinObject = Pin
    
    let stack = CoreDataStack(modelName: "Model")!  // because class func createPhotoInstance(_ mediaURL: String, _ photoName: String, _ currentPin: Pin, _ context: NSManagedObjectContext) -> Void { - has context as input... pass "stack.context" in context>
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setUIEnabled(false)
        
        print("currentPinObject being passed is ... \(currentPinObject)")
        
        // unwrapping optional
        if let currentPinObject = self.currentPinObject {
            // do something with the curret
            
            
            
        }
        // call getPhotoTotalPage and see what it returns - oh, also need to hard cord Hakone Garden @ the API call to make sure there are pictures to return for testing
        /*let methodParameters = [
            Constants.FlickrParameterKeys.Method : Constants.FlickrParameterValues.SearchMethod,
            Constants.FlickrParameterKeys.APIKey : Constants.FlickrParameterValues.APIKey,
            Constants.FlickrParameterKeys.SafeSearch : Constants.FlickrParameterValues.UseSafeSearch,
            Constants.FlickrParameterKeys.Extras : Constants.FlickrParameterValues.MediumURL,
            Constants.FlickrParameterKeys.Format : Constants.FlickrParameterValues.ResponseFormat,
            Constants.FlickrParameterKeys.NoJsonCallback : Constants.FlickrParameterValues.DisableJSONCallback,
            ] */

        /*
        FlickrConvenience.sharedInstance().getPhotoTotalPage (methodParameters as [String : AnyObject]) {(totalPages, error) in
        //   func getPhotoTotalPage(_ methodParameters: [String: AnyObject], _ completionHandlerForGetTotalPages: @escaping (_ totalPages: Int?, _ error: NSError?) -> Void) -> URLSessionDataTask {
        // it will return the total page there, and I will grab it ...
            if let totalPages = totalPages {
                print(totalPages)
            } else {
                print("error is \(error)")
            }
        }*/
        
        
        // call getPhotoArrayByRandPage to test it out first. After testing, move it to
        /* prolly don't even have to pass latitude/ longitude as currentPinObject is passed to another viewcontroller ???
        FlickrConvenience.sharedInstance().getPhotoArrayByRandPage(latitude, longitude, currentPinObject) { (photosArray, error) in
            // code here
            // ??? where to put this code??? - should call this @ collection view, because photosArray got pass to there??? - but that means saving mediaURL and title will be done on collection view..... is that what we want? dont' we prefer doing it here @ FlickrConvenience???
            /* Passing photosArray to CHForGetPhotoArray - and return back to the View controller, can display "No image" there if there is no photo returned */
            // when random page pictures returned, save the Photo to CoreData - by creating Photo instance. Save Photo URL, title
            // parse the data - that only contains 1 page's PhotoArray - if count > 1 photo
            if (photosArray?.count)! > 0 { // if photosArray has > 0 photo = have photo at all
                // add placeholder for how many pictures
                // we need - each Photo's Title & MediumURL right now
                for photoDict in photosArray! {
                    // save each to core data
                    // each photoDict has Title (=name), MediumURL (=mediaURL)
                    let mediaURL = photoDict[Constants.FlickrResponseKeys.MediumURL]
                    let photoName = photoDict[Constants.FlickrResponseKeys.Title]
                    
                    // photoName, mediaURL are the names in CoreData exactly - add them one by one
                    FlickrConvenience.sharedInstance().createPhotoInstance(mediaURL as! String, photoName as! String)  
                    
                } // END of for photoDict in photosArray
            } // END of if photosArray.count > 0 {
        } // END of FlickrConvenience.sharedInstance().getPhotoArrayByRandPage {
        */
    } // END of viewDidLoad()
    
    // need to handle error passed back ...
    // when error is passed to ViewController, do below..
    // call displayError() -> expects String -> it shows alert box with string
    // instead of calling ViewController's func displayError, we pass the "error" to completion handler!
    // self.displayError("There was an error with your request \(error?.localizedDescription)") // convert NSError to String with ".localizedDescription"
    
} // END of class PhotoAlbumViewController: UIViewController {

private extension PhotoAlbumViewController {
     // MARK - call these func here on PhotoAlbumViewController.swift
    // nikki's // call below API starts calling Flickr server and update it to false by hideAI(false) when photos returned
    // Configure hidding the activity indicator - for each picture placeholder! do it later Nikki
    func hideAI(_ enabled: Bool) -> Void {
        
    }
    
    // disable "New Collection"
    func setUIEnabled(_ enabled: Bool) {
        newCollection.isEnabled = enabled  // 1. to disable newCollection button, need to pass "false", 2. enable new collection when API is done calling. - need to work on nikki
    }
    
    // Set a function here - TO show label if TotalPage == 0
    // func
    
    
    
    
    
    
    

}
