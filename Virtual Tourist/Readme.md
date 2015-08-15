
### Deviations from / additions to the Virtual Tourist specs

-	Setup menu for following features:
    o	specify Flickr API key; 
    o	the variance (0.1-1.0 degree) of the area in which to look for photos; the smaller the area the less photos will be found in Flickr;
    o	specification of the number of photos to be downloaded from Flickr (1-12, default 12)
    o	a switch for a pop-up asking for confirmation when deleting a collection, or no pop-up and thus deleting a collection without asking for confirmation
    o	and a switch for support of dragging of pins or not (in order to reduce the number of pins on the map). When dragging is selected, a pin can be dragged to a different location and the associated photos collection is deleted right away; a short touch of the pin will display a call-out, selecting it will navigate to the corresponding photos collection. If dragging is deselected (this is the default and it is according to the provided specifications) then a short touch of the pin will navigate to the photos collection right away. 
-	Pin supports  touch and hold gesture.
-	When adding a pin, the app starts downloading of related photos from Flickr in the background.
-	When clicking on a photo (only when all photos are downloaded and the "New Collection" and "Add to Collection" buttons are activated) a detailed photo view is displayed with an enlarged image of the selected photo. On that screen the user can select ”Delete Photo” upon which the photo is deleted from the Collection view as well as from Core. Navigation is back to the collection view. Selecting "Back" navigates to the collection view without deleting the photo.
    This is a small deviation from the Virtual Tourist specs which asks for immediate removal of a photo after clicking. However I found it hard to judge a photo in the collection view since it is really too small.
-	On the collection view a button “New Collection” is available; after selecting that function by default a pop-up is displayed asking for confirmation for deleting the collection . This pop-up can be bypassed via an option in the Setup menu.
-	On the collection view there is also a button “+”. Selecting that option will add more photos to the collection.
    This is an addition to the Virtual Tourist specs.
-	Following an email from Jason@Udacity the pin-associated photos are stored in Core directly, not on disk. Core can decide by itself whether to store data in sqlite or on disk by activating the “Allows External Data” switch in the model builder tool. Thus I do not need to bother about managing files/photo images on disk myself.
-	I looked at encrypting/decrypting the Flickr API key provided by the user however I consider that too much beyond the scope of the Virtual Tourist project scope. It requires a 3rd party library.




Keep following layout-ing for the collection view
=================================================
extension PhotoAlbumVC : UICollectionViewDelegateFlowLayout {

//    func collectionView(collectionView: UICollectionView,
//        layout collectionViewLayout: UICollectionViewLayout,
//        sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
//            
//            // Determine screensize
//            let screenSize: CGRect = UIScreen.mainScreen().bounds
//            let screenWidth = screenSize.width
//            let screenHeight = screenSize.height
//            
//            return CGSize(width: (screenWidth-60)/3, height: (screenHeight-80-50-30)/4)
//    }
//    
//    func collectionView(collectionView: UICollectionView,
//        layout collectionViewLayout: UICollectionViewLayout,
//        insetForSectionAtIndex section: Int) -> UIEdgeInsets {
//            return sectionInsets
//    }

// Layout the collection view

override func viewDidLayoutSubviews() {
super.viewDidLayoutSubviews()

// Lay out the collection view so that cells take up 1/3 of the width,
// with no space in between.
let layout : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
layout.minimumLineSpacing = 0
layout.minimumInteritemSpacing = 0

let width = floor(self.myCollView.frame.size.width/3)
layout.itemSize = CGSize(width: width, height: width)
myCollView.collectionViewLayout = layout
}

}
