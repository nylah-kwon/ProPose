/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view controller for the AVCamFilter camera interface.
*/

import UIKit
import AVFoundation
import CoreVideo
import Photos
import MobileCoreServices
import Vision
import SQLite3
//import ASHorizontalScrollView


class MyCollectionViewCell: UICollectionViewCell {
    
 
    @IBOutlet weak var myButton: UIButton!
    @IBOutlet weak var myLabel: UILabel!
    
    @IBOutlet weak var myImage: UIImageView!
    
    @IBAction func bclick(_ sender: Any) {
        
    }
}

var db: OpaquePointer?
/*
func opendb(){
       let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("pose.db")
       
       if sqlite3_open(fileURL.path, &db) == SQLITE_OK {
           print("DB 열기 실패222")
       }
       print(fileURL)
      if sqlite3_exec(db, "CREATE TABLE IF NOT EXISTS Test (id INTEGER PRIMARY KEY AUTOINCREMENT, DN_title TEXT, DN_subline TEXT, DN_date TEXT)", nil, nil, nil) != SQLITE_OK {
           let errmsg = String(cString: sqlite3_errmsg(db)!)
           print("error creating table: \(errmsg)")
       }

   }
*/
class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureDepthDataOutputDelegate, AVCaptureDataOutputSynchronizerDelegate,
                            UICollectionViewDataSource,UICollectionViewDelegate{
    
    let ad = UIApplication.shared.delegate as? AppDelegate
    //yolo
    static let maxInflightBuffers = 3
    var inflightBuffer = 0

    var resizedPixelBuffers: [CVPixelBuffer?] = []
    let yolo = YOLO()
    var boundingBoxes = [BoundingBox]()
    var colors: [UIColor] = []
    var startTimes: [CFTimeInterval] = []
    let semaphore = DispatchSemaphore(value: CameraViewController.maxInflightBuffers)
    let drawBoundingBoxes = true
    var framesDone = 0
    var frameCapturingStartTime = CACurrentMediaTime()
    let ciContext = CIContext()
    var pcount = 0
    
    //DB
    var pm = [[13, 1,2, 3, 3],[13, 1,3, 3, 3],
    [14,1, 1, 1, 2],
    [14, 1,2, 1, 2],
    [14, 1,3, 1, 2],
    [ 15,1, 1, 1, 1],
    [15, 1,3, 1, 1],
   [ 16, 1,2, 3, 0],
    [16, 1,3, 3, 0],
   [ 6, 1,4, 1, 0],
   [ 7, 3,1, 2, 0],
   [ 7, 3,3, 2, 0],
  [  9,3, 1, 1, 2],
   [ 9, 3,2, 1, 2],
   [ 9, 3,3, 1, 2],
   [ 10, 2,1, 2, 0],
   [ 11, 2,1, 3, 0],
   [ 11, 2,5, 3, 0],
   [12, 3,1, 1, 1],
    [12, 3,1, 1, 3],
 [   12, 3,5, 1, 1],
 [   12, 3,5, 1, 3],


 [   0, 1,1, 1, 0],
 [   0, 1,1, 3, 0],
 [   0, 1,2, 1, 0],
 [   0, 1,2, 3, 0],
  [  0,1, 3, 1, 0],
  [  0,1, 3, 3, 0],

  [  1,1, 2, 1, 0],
[     1, 1,2, 3, 0],
[ 1,1, 3, 1, 0],
   [ 1, 1,3, 3, 0],
   [ 2, 2,4, 1, 0],
   [ 3,1, 5, 1, 1],
   [ 4,1, 3, 3, 0],
   [ 5, 1,1, 1, 0]]
    
    
    
    let reuseIdentifier = "cell" // also enter this string as the cell identifier in the storyboard
    var items = [0, 1, 2, 3, 4, 5, 6, 7, 9, 10, 11,12,13,14,15,16]
    var images = [UIImage(named: "pose0.png"),UIImage(named: "pose1.png"),UIImage(named: "pose2.png"),UIImage(named: "pose3.png"),UIImage(named: "pose4.png"),UIImage(named: "pose5.png"),UIImage(named: "pose6.png"),UIImage(named: "pose7.png"),
                  UIImage(named: "pose8.png"), UIImage(named: "pose9.png"),UIImage(named: "pose10.png"),UIImage(named: "pose11.png"),UIImage(named: "pose12.png"),UIImage(named: "pose13.png"),UIImage(named: "pose14.png") ,UIImage(named: "pose15.png"),UIImage(named: "pose16.png") ]
    // MARK: - UICollectionViewDataSource protocol
        
    // tell the collection view how many cells to make
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print(self.items.count)
        return self.items.count
    }
        
    // make a cell for each cell index path
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            
            // get a reference to our storyboard cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath as IndexPath) as! MyCollectionViewCell
            
            // Use the outlet in our custom class to get a reference to the UILabel in the cell
            cell.myLabel.text = String(self.items[indexPath.item])
        
            cell.myLabel.isHidden = true
        
            //print(self.items[indexPath.item], "????!#!#!#")
            cell.myButton.setImage(self.images[self.items[indexPath.item]], for: .normal)
            cell.myButton.isHidden = true
        
            cell.myImage.image = self.images[self.items[indexPath.item]]
            //cell.backgroundColor = UIColor.white // make cell more visible in our example project
            
        return cell
    }
    
    
        
    // MARK: - UICollectionViewDelegate protocol
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            // handle tap events
            PoseScreen.image = self.images[self.items[indexPath.item]]
       
            print("You selected cell #\(indexPath.item)!")
    }
    


    @IBOutlet weak var morepose: UIButton!
    

    @IBAction func moseclick(_ sender: Any) {
        
        if PoseView.isHidden{
            PoseView.isHidden = false
        }
        else{
            PoseView.isHidden = true
        }
    }
    
    
    // gny
    var bufferSize: CGSize = .zero
    
    var persons = 0
    var background = "All"
    var style = "All"
    var etc = "All"
    
    @IBOutlet weak var PoseScreen: UIImageView!
    
    @IBOutlet weak var PoseView: UICollectionView!
    
    @IBOutlet weak var BackgroundPredictLabel: UILabel!
    @IBOutlet weak var PredictImage: UIImageView!
    
    @IBOutlet weak var tagButton: UIButton!
    
    @IBOutlet weak var AutoTagButton: UIButton!
    
    
    @IBAction func PoseClick(_ sender: Any) {
        let ad = UIApplication.shared.delegate as? AppDelegate
        items = []
        
        
        for i in (0..<pm.count){
            if ad?.persons == 0 || pm[i][1] == ad?.persons {
            if ad?.background == 0 || pm[i][2] == ad?.background {
                if ad?.style == 0 || pm[i][3] == ad?.style{
                    if ad?.etc == 0 || pm[i][4] == ad?.etc{
                        items.append(pm[i][0])
                    }
                }
            }
            }
        }
        
        let b = Set(items)
        items = Array(b)
        print(items)
        //images = [UIImage(named: "pose4.png"),UIImage(named: "pose5.png"),UIImage(named: "pose6.png") ]
        
        PoseView.reloadData()
        
       // ad?.pose = items[0]
        if items.count > 0 {
            ad?.pose = items[0]
            PoseScreen.image = self.images[items[0]]
        }
    }
    @IBOutlet weak var PoseButton: UIButton!
    
    @IBAction func AutoTagClick(_ sender: Any) {
        
        let ad = UIApplication.shared.delegate as? AppDelegate
        
        //PoseScreen.image = images[ad!.pose]
        
        //yolo.pre
        print(pcount)
        ad?.persons = pcount
        
        
        switch BackgroundPredictLabel.text {
        case "landscape":
            ad?.background = 1;
        case "street":
            ad?.background = 2;
        case "wall":
            ad?.background = 3;
        case "circle":
            ad?.background = 5;
        default:
            ad?.background = 0;
        }
        
        
        
        //let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("p.db")
        
        //if sqlite3_open(fileURL.path, &db) != SQLITE_OK { print("error opening database", fileURL.path) }else{ print("SUCESS opening database") }
        
        //db = openSQLite(path: fileURL.path)
        
        /*
        let createStatment: String = """
        CREATE TABLE Pose (
            id INT PRIMARY KEY NOT NULL,
            filename string,
         persons int
            );
        
        Insert into pose(id, filename, persons) values (0, "pose0.png", 1);
        Insert into pose(id, filename, persons) values (1, "pose1.png", 1);
        Insert into pose(id, filename, persons) values (2, "pose2.png", 2);
        Insert into pose(id, filename, persons) values (3, "pose3.png", 1);
        Insert into pose(id, filename, persons) values (4, "pose4.png", 1);
        Insert into pose(id, filename, persons) values (5, "pose5.png", 1);
        Insert into pose(id, filename, persons) values (6, "pose6.png", 1);
        Insert into pose(id, filename, persons) values (7, "pose7.png", 6);
        Insert into pose(id, filename, persons) values (9, "pose9.png", 3);
        Insert into pose(id, filename, persons) values (10, "pose10.png", 2);
        Insert into pose(id, filename, persons) values (11, "pose11.png", 2);
        Insert into pose(id, filename, persons) values (12, "pose12.png", 3);
        Insert into pose(id, filename, persons) values (13, "pose13.png", 1);
        Insert into pose(id, filename, persons) values (14, "pose14.png", 1);
        Insert into pose(id, filename, persons) values (15, "pose15.png", 1);
        Insert into pose(id, filename, persons) values (16, "pose16.png", 1);


        CREATE TABLE Background (
            id INT PRIMARY KEY NOT NULL,
            name string
            );

        Insert into background (id, name) values (1, "landscape");
        Insert into background (id, name) values (2, "street");
        Insert into background (id, name) values (3, "wall");
        Insert into background (id, name) values (4, "mirror");
        Insert into background (id, name) values (5, "sunset");

        CREATE TABLE Style (
            id INT PRIMARY KEY NOT NULL,
            name string
            );

        Insert into style (id, name) values (1, "normal");
        Insert into style (id, name) values (2, "funny");
        Insert into style (id, name) values (3, "cool");


        CREATE TABLE ETC (
            id INT PRIMARY KEY NOT NULL,
            name string
            );


        Insert into etc (id, name) values (0, "none");
        Insert into etc (id, name) values (1, "heart");
        Insert into etc (id, name) values (2, "selfie");
        Insert into etc (id, name) values (3, "sitdown");


        CREATE TABLE posemap(
            pid INT ,
            bid int,
         sid int,
        eid int,
        Foreign key(pid) references pose(id),
        Foreign key(bid) references background(id),
        Foreign key(sid) references style(id),
        Foreign key(eid) references style(id)
            );

        
        Insert into posemap (pid, bid, sid, eid) values (13, 2, 3, 3);
        Insert into posemap (pid, bid, sid, eid) values (13, 3, 3, 3);
        Insert into posemap (pid, bid, sid, eid) values (14, 1, 1, 2);
        Insert into posemap (pid, bid, sid, eid) values (14, 2, 1, 2);
        Insert into posemap (pid, bid, sid, eid) values (14, 3, 1, 2);
        Insert into posemap (pid, bid, sid, eid) values (15, 1, 1, 1);
        Insert into posemap (pid, bid, sid, eid) values (15, 3, 1, 1);
        Insert into posemap (pid, bid, sid, eid) values (16, 2, 3, 0);
        Insert into posemap (pid, bid, sid, eid) values (16, 3, 3, 0);
        Insert into posemap (pid, bid, sid, eid) values (6, 4, 1, 0);
        Insert into posemap (pid, bid, sid, eid) values (7, 1, 2, 0);
        Insert into posemap (pid, bid, sid, eid) values (7, 3, 2, 0);
        Insert into posemap (pid, bid, sid, eid) values (9, 1, 1, 2);
        Insert into posemap (pid, bid, sid, eid) values (9, 2, 1, 2);
        Insert into posemap (pid, bid, sid, eid) values (9, 3, 1, 2);
        Insert into posemap (pid, bid, sid, eid) values (10, 1, 2, 0);
        Insert into posemap (pid, bid, sid, eid) values (11, 1, 3, 0);
        Insert into posemap (pid, bid, sid, eid) values (11, 5, 3, 0);
        Insert into posemap (pid, bid, sid, eid) values (12, 1, 1, 1);
        Insert into posemap (pid, bid, sid, eid) values (12, 1, 1, 3);
        Insert into posemap (pid, bid, sid, eid) values (12, 5, 1, 1);
        Insert into posemap (pid, bid, sid, eid) values (12, 5, 1, 3);


        Insert into posemap (pid, bid, sid, eid) values (0, 1, 1, 0);
        Insert into posemap (pid, bid, sid, eid) values (0, 1, 3, 0);
        Insert into posemap (pid, bid, sid, eid) values (0, 2, 1, 0);
        Insert into posemap (pid, bid, sid, eid) values (0, 2, 3, 0);
        Insert into posemap (pid, bid, sid, eid) values (0, 3, 1, 0);
        Insert into posemap (pid, bid, sid, eid) values (0, 3, 3, 0);

        Insert into posemap (pid, bid, sid, eid) values (1, 2, 1, 0);
        Insert into posemap (pid, bid, sid, eid) values (1, 2, 3, 0);
        Insert into posemap (pid, bid, sid, eid) values (1, 3, 1, 0);
        Insert into posemap (pid, bid, sid, eid) values (1, 3, 3, 0);

        Insert into posemap (pid, bid, sid, eid) values (2, 4, 1, 0);
        Insert into posemap (pid, bid, sid, eid) values (3, 5, 1, 1);
        Insert into posemap (pid, bid, sid, eid) values (4, 3, 3, 0);
        Insert into posemap (pid, bid, sid, eid) values (5, 1, 1, 0);

        """
       
 
        if createSQLiteTable(database: db!, statement: createStatment) {
            print("✅ Success, Create SQLite Table.")
        }
        
        let insertStatment: String = """
        Insert into pose1(id, filename, persons) values (0, \"pose0.png\", 1);
        """
        if insertSQLiteTable(database: db!, statement: insertStatment) {
            print("✅ Success, Insert data into SQLite Table.")
        }
        
         
        let queryStatment: String = "SELECT * FROM Pose;"
        if qeurySQLite(database: db!, statment: queryStatment) {
            print("✅ Success, Query SQLite.")
        }
        
        //let queryStatment: String = "SELECT * FROM posemap;"
        //items = qeurySQLite(database: db! , statment: queryStatment)
         */
 
        
        
        /*
        PoseView.performBatchUpdates({
            let index = 1
            for i in (index..<items.count).reversed() {
                items.remove(at: i)

                PoseView.deleteItems(at: [IndexPath(item: i, section: 0)])
            }
            items.insert("8", at: index)
            PoseView.insertItems(at: [IndexPath(item: index, section: 0)])
        }, completion: nil)
        */

    }
    
    
    // MARK: - Properties
    
    @IBOutlet weak private var cameraButton: UIButton!
    
    @IBOutlet weak private var photoButton: UIButton!
    
    @IBOutlet weak private var resumeButton: UIButton!
    
    @IBOutlet weak private var cameraUnavailableLabel: UILabel!
    
    @IBOutlet weak private var filterLabel: UILabel!
    
    @IBOutlet weak private var previewView: PreviewMetalView!
    
    @IBOutlet weak private var videoFilterButton: UIButton!
    
    private var videoFilterOn: Bool = false
    
    @IBOutlet weak private var depthVisualizationButton: UIButton!
    
    private var depthVisualizationOn: Bool = false
    
    @IBOutlet weak private var depthSmoothingButton: UIButton!
    
    private var depthSmoothingOn: Bool = false
    
    @IBOutlet weak private var mixFactorNameLabel: UILabel!
    
    @IBOutlet weak private var mixFactorValueLabel: UILabel!
    
    @IBOutlet weak private var mixFactorSlider: UISlider!
    
    @IBOutlet weak private var depthDataMaxFrameRateNameLabel: UILabel!
    
    @IBOutlet weak private var depthDataMaxFrameRateValueLabel: UILabel!
    
    @IBOutlet weak private var depthDataMaxFrameRateSlider: UISlider!
    
    private enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }
    
    private var setupResult: SessionSetupResult = .success
    
    //gny 캡처할 카메라
    private let session = AVCaptureSession()
    
    private var isSessionRunning = false
    
    // Communicate with the session and other session objects on this queue.
    private let sessionQueue = DispatchQueue(label: "SessionQueue", attributes: [], autoreleaseFrequency: .workItem)
    
    private var videoInput: AVCaptureDeviceInput!
    
    private let dataOutputQueue = DispatchQueue(label: "VideoDataQueue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    
    private let videoDataOutput = AVCaptureVideoDataOutput()
    
    private let depthDataOutput = AVCaptureDepthDataOutput()
    
    private var outputSynchronizer: AVCaptureDataOutputSynchronizer?
    
    private let photoOutput = AVCapturePhotoOutput()
    
    private let filterRenderers: [FilterRenderer] = [RosyMetalRenderer(), RosyCIRenderer()]
    
    private let photoRenderers: [FilterRenderer] = [RosyMetalRenderer(), RosyCIRenderer()]
    
    private let videoDepthMixer = VideoMixer()
    
    private let photoDepthMixer = VideoMixer()
    
    private var filterIndex: Int = 0
    
    private var videoFilter: FilterRenderer?
    
    private var photoFilter: FilterRenderer?
    
    private let videoDepthConverter = DepthToGrayscaleConverter()
    
    private let photoDepthConverter = DepthToGrayscaleConverter()
    
    private var currentDepthPixelBuffer: CVPixelBuffer?
    
    private var renderingEnabled = true
    
    private var depthVisualizationEnabled = false
    
    private let processingQueue = DispatchQueue(label: "photo processing queue", attributes: [], autoreleaseFrequency: .workItem)
    
    private let videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera,
                                                                                             .builtInWideAngleCamera],
                                                                               mediaType: .video,
                                                                               position: .unspecified)
    
    private var statusBarOrientation: UIInterfaceOrientation = .portrait
    
    //gny
    
    
    // MARK: - View Controller Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //gny
        setupVision()
        setUpBoundingBoxes()
        setUpCoreImage()
        setUpVision2()
        
        //PoseSee()
        videoFilterButton.isHidden = true
        PredictImage.isHidden = true
        
        //PoseView.isHidden = true
        for box in self.boundingBoxes {
            box.addToLayer(self.view.layer)
        }
        
        tagButton.addTarget(self, action: #selector(showTagView), for: .touchUpInside)
        
        
      
        
        // Disable UI. The UI is enabled if and only if the session starts running.
        cameraButton.isEnabled = false
        photoButton.isEnabled = false
        videoFilterOn = false
        videoFilterButton.setImage(#imageLiteral(resourceName: "ColorFilterOff"), for: .normal)
        /*
        depthVisualizationOn = false
        depthVisualizationButton.setImage(#imageLiteral(resourceName: "DepthVisualOff"), for: .normal)
        depthVisualizationButton.isHidden = true
        depthSmoothingOn = false
        depthSmoothingButton.setImage(#imageLiteral(resourceName: "DepthSmoothOff"), for: .normal)
        depthSmoothingButton.isHidden = true
        mixFactorNameLabel.isHidden = true
        mixFactorValueLabel.isHidden = true
        mixFactorSlider.isHidden = true
        depthDataMaxFrameRateValueLabel.isHidden = true
        depthDataMaxFrameRateNameLabel.isHidden = true
        depthDataMaxFrameRateSlider.isHidden = true*/
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(focusAndExposeTap))
        previewView.addGestureRecognizer(tapGesture)
        
        let leftSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(changeFilterSwipe))
        leftSwipeGesture.direction = .left
        previewView.addGestureRecognizer(leftSwipeGesture)
        
        let rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(changeFilterSwipe))
        rightSwipeGesture.direction = .right
        previewView.addGestureRecognizer(rightSwipeGesture)
        
        // Check video authorization status, video access is required
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // The user has previously granted access to the camera
            break
            
        case .notDetermined:
            /*
             The user has not yet been presented with the option to grant video access
             Suspend the SessionQueue to delay session setup until the access request has completed
             */
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                if !granted {
                    self.setupResult = .notAuthorized
                }
                self.sessionQueue.resume()
            })
            
        default:
            // The user has previously denied access
            setupResult = .notAuthorized
        }
        
        /*
         Setup the capture session.
         In general it is not safe to mutate an AVCaptureSession or any of its
         inputs, outputs, or connections from multiple threads at the same time.
         
         Don't do this on the main queue, because AVCaptureSession.startRunning()
         is a blocking call, which can take a long time. Dispatch session setup
         to the sessionQueue so as not to block the main queue, which keeps the UI responsive.
         */
        sessionQueue.async {
            self.configureSession()
        }
    }
    
    //yolo fun start
    
    
    func setUpBoundingBoxes() {
      for _ in 0..<YOLO.maxBoundingBoxes {
        boundingBoxes.append(BoundingBox())
      }

      // Make colors for the bounding boxes. There is one color for each class,
      // 20 classes in total.
      for r: CGFloat in [0.2, 0.4, 0.6, 0.8, 1.0] {
        for g: CGFloat in [0.3, 0.7] {
          for b: CGFloat in [0.4, 0.8] {
            let color = UIColor(red: r, green: g, blue: b, alpha: 1)
            colors.append(color)
          }
        }
      }
    }

    func setUpCoreImage() {
      // Since we might be running several requests in parallel, we also need
      // to do the resizing in different pixel buffers or we might overwrite a
      // pixel buffer that's already in use.
      for _ in 0..<CameraViewController.maxInflightBuffers {
        var resizedPixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(nil, YOLO.inputWidth, YOLO.inputHeight,
                                         kCVPixelFormatType_32BGRA, nil,
                                         &resizedPixelBuffer)

        if status != kCVReturnSuccess {
          print("Error: could not create resized pixel buffer", status)
        }
        resizedPixelBuffers.append(resizedPixelBuffer)
      }
    }
   /*
    func predict(image: UIImage) {
      if let pixelBuffer = image.pixelBuffer(width: YOLO.inputWidth, height: YOLO.inputHeight) {
        predict(pixelBuffer: pixelBuffer, inflightIndex: 0)
      }
    }*/
    
    

    func predict(pixelBuffer: CVPixelBuffer, inflightIndex: Int) {
      // Measure how long it takes to predict a single video frame.
      let startTime = CACurrentMediaTime()

      // This is an alternative way to resize the image (using vImage):
      //if let resizedPixelBuffer = resizePixelBuffer(pixelBuffer,
      //                                              width: YOLO.inputWidth,
      //                                              height: YOLO.inputHeight) {

      // Resize the input with Core Image to 416x416.
      if let resizedPixelBuffer = resizedPixelBuffers[inflightIndex] {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let sx = CGFloat(YOLO.inputWidth) / CGFloat(CVPixelBufferGetWidth(pixelBuffer))
        let sy = CGFloat(YOLO.inputHeight) / CGFloat(CVPixelBufferGetHeight(pixelBuffer))
        let scaleTransform = CGAffineTransform(scaleX: sx, y: sy)
        let scaledImage = ciImage.transformed(by: scaleTransform)
    
        
        let finallmg = scaledImage.oriented(.right)
        //ciContext.render(scaledImage, to: resizedPixelBuffer)
        ciContext.render(finallmg, to: resizedPixelBuffer)
        self.PredictImage.image = UIImage(ciImage: finallmg)
        
        // Give the resized input to our model.
        if let boundingBoxes = yolo.predict(image: resizedPixelBuffer) {
          let elapsed = CACurrentMediaTime() - startTime
          showOnMainThread(boundingBoxes, elapsed)
        } else {
          print("BOGUS")
        }
      }

      self.semaphore.signal()
    }
    
    //yolo fun finish
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let interfaceOrientation = UIApplication.shared.statusBarOrientation
        statusBarOrientation = interfaceOrientation
        
        let initialThermalState = ProcessInfo.processInfo.thermalState
        if initialThermalState == .serious || initialThermalState == .critical {
            showThermalState(state: initialThermalState)
        }
        
        sessionQueue.async {
            switch self.setupResult {
            case .success:
                self.addObservers()
                
                if let photoOrientation = AVCaptureVideoOrientation(interfaceOrientation: interfaceOrientation) {
                    if let unwrappedPhotoOutputConnection = self.photoOutput.connection(with: .video) {
                        unwrappedPhotoOutputConnection.videoOrientation = photoOrientation
                    }
                }
                
                if let unwrappedVideoDataOutputConnection = self.videoDataOutput.connection(with: .video) {
                    let videoDevicePosition = self.videoInput.device.position
                    let rotation = PreviewMetalView.Rotation(with: interfaceOrientation,
                                                             videoOrientation: unwrappedVideoDataOutputConnection.videoOrientation,
                                                             cameraPosition: videoDevicePosition)
                    self.previewView.mirroring = (videoDevicePosition == .front)
                    if let rotation = rotation {
                        self.previewView.rotation = rotation
                    }
                }
                self.dataOutputQueue.async {
                    self.renderingEnabled = true
                }
                
                self.session.startRunning()
                self.isSessionRunning = self.session.isRunning
                
                //DispatchQueue.main.async {
                //    self.updateDepthUIHidden()
                //}
                
            case .notAuthorized:
                DispatchQueue.main.async {
                    let message = NSLocalizedString("AVCamFilter doesn't have permission to use the camera, please change privacy settings",
                                                    comment: "Alert message when the user has denied access to the camera")
                    let actions = [
                        UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"),
                                      style: .cancel,
                                      handler: nil),
                        UIAlertAction(title: NSLocalizedString("Settings", comment: "Alert button to open Settings"),
                                      style: .`default`,
                                      handler: { _ in
                                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!,
                                                                  options: [:],
                                                                  completionHandler: nil)
                        })
                    ]
                    
                    self.alert(title: "AVCamFilter", message: message, actions: actions)
                }
                
            case .configurationFailed:
                DispatchQueue.main.async {
                    
                    let message = NSLocalizedString("Unable to capture media",
                                                    comment: "Alert message when something goes wrong during capture session configuration")
                    
                    self.alert(title: "AVCamFilter",
                               message: message,
                               actions: [UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"),
                                                       style: .cancel,
                                                       handler: nil)])
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        dataOutputQueue.async {
            self.renderingEnabled = false
        }
        sessionQueue.async {
            if self.setupResult == .success {
                self.session.stopRunning()
                self.isSessionRunning = self.session.isRunning
                self.removeObservers()
            }
        }
        
        super.viewWillDisappear(animated)
    }
    
    //gny
    @objc func showTagView(){
        let alert = self.storyboard?.instantiateViewController(withIdentifier: "TagAlertView") as! TagAlertView
            alert.modalPresentationStyle = .overCurrentContext
       
        present(alert, animated: false, completion: nil)
        }
    
    
    @objc
    func didEnterBackground(notification: NSNotification) {
        // Free up resources.
        dataOutputQueue.async {
            self.renderingEnabled = false
            if let videoFilter = self.videoFilter {
                videoFilter.reset()
            }
            self.videoDepthMixer.reset()
            self.currentDepthPixelBuffer = nil
            self.videoDepthConverter.reset()
            self.previewView.pixelBuffer = nil
            self.previewView.flushTextureCache()
            
        }
        processingQueue.async {
            if let photoFilter = self.photoFilter {
                photoFilter.reset()
            }
            self.photoDepthMixer.reset()
            self.photoDepthConverter.reset()
        }
    }
    
    @objc
    func willEnterForground(notification: NSNotification) {
        dataOutputQueue.async {
            self.renderingEnabled = true
        }
    }
    
    // Use this opportunity to take corrective action to help cool the system down.
    @objc
    func thermalStateChanged(notification: NSNotification) {
        if let processInfo = notification.object as? ProcessInfo {
            showThermalState(state: processInfo.thermalState)
        }
    }
    
    func showThermalState(state: ProcessInfo.ThermalState) {
        DispatchQueue.main.async {
            var thermalStateString = "UNKNOWN"
            if state == .nominal {
                thermalStateString = "NOMINAL"
            } else if state == .fair {
                thermalStateString = "FAIR"
            } else if state == .serious {
                thermalStateString = "SERIOUS"
            } else if state == .critical {
                thermalStateString = "CRITICAL"
            }
            
            let message = NSLocalizedString("Thermal state: \(thermalStateString)", comment: "Alert message when thermal state has changed")
            let actions = [
                UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"),
                              style: .cancel,
                              handler: nil)]
            
            self.alert(title: "AVCamFilter", message: message, actions: actions)
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(
            alongsideTransition: { _ in
                let interfaceOrientation = UIApplication.shared.statusBarOrientation
                self.statusBarOrientation = interfaceOrientation
                self.sessionQueue.async {
                    /*
                     The photo orientation is based on the interface orientation. You could also set the orientation of the photo connection based
                     on the device orientation by observing UIDeviceOrientationDidChangeNotification.
                     */
                    if let photoOrientation = AVCaptureVideoOrientation(interfaceOrientation: interfaceOrientation) {
                        if let unwrappedPhotoOutputConnection = self.photoOutput.connection(with: .video) {
                            unwrappedPhotoOutputConnection.videoOrientation = photoOrientation
                        }
                    }
                    
                    if let unwrappedVideoDataOutputConnection = self.videoDataOutput.connection(with: .video) {
                        //DispatchQueue.main.async {
                         //   self.updateDepthUIHidden()
                        //}
                        if let rotation = PreviewMetalView.Rotation(with: interfaceOrientation,
                                                                    videoOrientation: unwrappedVideoDataOutputConnection.videoOrientation,
                                                                    cameraPosition: self.videoInput.device.position) {
                            self.previewView.rotation = rotation
                        }
                    }
                }
        }, completion: nil
        )
    }
    
    // MARK: - KVO and Notifications
    
    private var sessionRunningContext = 0
    
    private func addObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(willEnterForground),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(thermalStateChanged),
                                               name: ProcessInfo.thermalStateDidChangeNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sessionRuntimeError),
                                               name: NSNotification.Name.AVCaptureSessionRuntimeError,
                                               object: session)
        
        session.addObserver(self, forKeyPath: "running", options: NSKeyValueObservingOptions.new, context: &sessionRunningContext)
        
        // A session can run only when the app is full screen. It will be interrupted in a multi-app layout.
        // Add observers to handle these session interruptions and inform the user.
        // See AVCaptureSessionWasInterruptedNotification for other interruption reasons.
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sessionWasInterrupted),
                                               name: NSNotification.Name.AVCaptureSessionWasInterrupted,
                                               object: session)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sessionInterruptionEnded),
                                               name: NSNotification.Name.AVCaptureSessionInterruptionEnded,
                                               object: session)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(subjectAreaDidChange),
                                               name: NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange,
                                               object: videoInput.device)
    }
    
    private func removeObservers() {
        NotificationCenter.default.removeObserver(self)
        session.removeObserver(self, forKeyPath: "running", context: &sessionRunningContext)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if context == &sessionRunningContext {
            let newValue = change?[.newKey] as AnyObject?
            guard let isSessionRunning = newValue?.boolValue else { return }
            DispatchQueue.main.async {
                self.cameraButton.isEnabled = (isSessionRunning && self.videoDeviceDiscoverySession.devices.count > 1)
                self.photoButton.isEnabled = isSessionRunning
                self.videoFilterButton.isEnabled = isSessionRunning
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    // MARK: - Session Management
    
    // Call this on the SessionQueue
    private func configureSession() {
        if setupResult != .success {
            return
        }
        
        let defaultVideoDevice: AVCaptureDevice? = videoDeviceDiscoverySession.devices.first
        
        //gny 장치 설정
        guard let videoDevice = defaultVideoDevice else {
            print("Could not find any video device")
            setupResult = .configurationFailed
            return
        }
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoDevice)
        } catch {
            print("Could not create video device input: \(error)")
            setupResult = .configurationFailed
            return
        }
        
        session.beginConfiguration()
        
        //gny 해상도 설정
        //AVCaptureSession.Preset.photo : 고해상도 사진 품질 출력에 적합한 캡처 설정을 지정
        session.sessionPreset = AVCaptureSession.Preset.photo
        
        
        // Add a video input.
        // gny 카메라를 장치로 추가해 세션에 비디오 입력 추가
        guard session.canAddInput(videoInput) else {
            print("Could not add video device input to the session")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
        session.addInput(videoInput)
        
        // Add a video data output
        // gny 세션에 비디오 출력을 추가하고 픽셀형식 지정
        if session.canAddOutput(videoDataOutput) {
            session.addOutput(videoDataOutput)
            //gny 체크포인트1
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)] //32 비트 BGRA
                //kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
            videoDataOutput.setSampleBufferDelegate(self, queue: dataOutputQueue)
        } else {
            print("Could not add video data output to the session")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
        
        //gny ***********추가부분***********
        let captureConnection = videoDataOutput.connection(with: .video)
        // Always process the frames
        captureConnection?.isEnabled = true
        do {
            try  videoDevice.lockForConfiguration()
            let dimensions = CMVideoFormatDescriptionGetDimensions((videoDevice.activeFormat.formatDescription))
            bufferSize.width = CGFloat(dimensions.width)
            bufferSize.height = CGFloat(dimensions.height)
            videoDevice.unlockForConfiguration()
        } catch {
            print(error)
        }
        //***********추가부분종료***********
        
        // Add photo output
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            
            photoOutput.isHighResolutionCaptureEnabled = true
            
            if depthVisualizationEnabled {
                if photoOutput.isDepthDataDeliverySupported {
                    photoOutput.isDepthDataDeliveryEnabled = true
                } else {
                    depthVisualizationEnabled = false
                }
            }
            
        } else {
            print("Could not add photo output to the session")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
        
        // Add a depth data output
        /*
        if session.canAddOutput(depthDataOutput) {
            session.addOutput(depthDataOutput)
            depthDataOutput.setDelegate(self, callbackQueue: dataOutputQueue)
            depthDataOutput.isFilteringEnabled = false
            if let connection = depthDataOutput.connection(with: .depthData) {
                connection.isEnabled = depthVisualizationEnabled
            } else {
                print("No AVCaptureConnection")
            }
        } else {
            print("Could not add depth data output to the session")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }*/
        
        if depthVisualizationEnabled {
            // Use an AVCaptureDataOutputSynchronizer to synchronize the video data and depth data outputs.
            // The first output in the dataOutputs array, in this case the AVCaptureVideoDataOutput, is the "master" output.
            outputSynchronizer = AVCaptureDataOutputSynchronizer(dataOutputs: [videoDataOutput, depthDataOutput])
            if let unwrappedOutputSynchronizer = outputSynchronizer {
                unwrappedOutputSynchronizer.setDelegate(self, queue: dataOutputQueue)
            }
        } else {
            outputSynchronizer = nil
        }
        
        capFrameRate(videoDevice: videoDevice)
        
        //세션 커밋
        session.commitConfiguration()
        /*
        DispatchQueue.main.async {
            self.depthDataMaxFrameRateValueLabel.text = String(format: "%.1f", self.depthDataMaxFrameRateSlider.value)
            self.mixFactorValueLabel.text = String(format: "%.1f", self.mixFactorSlider.value)
            self.depthDataMaxFrameRateSlider.minimumValue = Float(1) / Float(CMTimeGetSeconds(videoDevice.activeVideoMaxFrameDuration))
            self.depthDataMaxFrameRateSlider.maximumValue = Float(1) / Float(CMTimeGetSeconds(videoDevice.activeVideoMinFrameDuration))
            self.depthDataMaxFrameRateSlider.value = (self.depthDataMaxFrameRateSlider.minimumValue
                + self.depthDataMaxFrameRateSlider.maximumValue) / 2
        }
         */
    }
    
    @objc
    func sessionWasInterrupted(notification: NSNotification) {
        // In iOS 9 and later, the userInfo dictionary contains information on why the session was interrupted.
        if let userInfoValue = notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as AnyObject?,
            let reasonIntegerValue = userInfoValue.integerValue,
            let reason = AVCaptureSession.InterruptionReason(rawValue: reasonIntegerValue) {
            print("Capture session was interrupted with reason \(reason)")
            
            if reason == .videoDeviceInUseByAnotherClient {
                // Simply fade-in a button to enable the user to try to resume the session running.
                resumeButton.isHidden = false
                resumeButton.alpha = 0.0
                UIView.animate(withDuration: 0.25) {
                    self.resumeButton.alpha = 1.0
                }
            } else if reason == .videoDeviceNotAvailableWithMultipleForegroundApps {
                // Simply fade-in a label to inform the user that the camera is unavailable.
                cameraUnavailableLabel.isHidden = false
                cameraUnavailableLabel.alpha = 0.0
                UIView.animate(withDuration: 0.25) {
                    self.cameraUnavailableLabel.alpha = 1.0
                }
            }
        }
    }
    
    @objc
    func sessionInterruptionEnded(notification: NSNotification) {
        if !resumeButton.isHidden {
            UIView.animate(withDuration: 0.25,
                           animations: {
                            self.resumeButton.alpha = 0
            }, completion: { _ in
                self.resumeButton.isHidden = true
            }
            )
        }
        if !cameraUnavailableLabel.isHidden {
            UIView.animate(withDuration: 0.25,
                           animations: {
                            self.cameraUnavailableLabel.alpha = 0
            }, completion: { _ in
                self.cameraUnavailableLabel.isHidden = true
            }
            )
        }
    }
    
    @objc
    func sessionRuntimeError(notification: NSNotification) {
        guard let errorValue = notification.userInfo?[AVCaptureSessionErrorKey] as? NSError else {
            return
        }
        
        let error = AVError(_nsError: errorValue)
        print("Capture session runtime error: \(error)")
        
        /*
         Automatically try to restart the session running if media services were
         reset and the last start running succeeded. Otherwise, enable the user
         to try to resume the session running.
         */
        if error.code == .mediaServicesWereReset {
            sessionQueue.async {
                if self.isSessionRunning {
                    self.session.startRunning()
                    self.isSessionRunning = self.session.isRunning
                } else {
                    DispatchQueue.main.async {
                        self.resumeButton.isHidden = false
                    }
                }
            }
        } else {
            resumeButton.isHidden = false
        }
    }
    
    @IBAction private func resumeInterruptedSession(_ sender: UIButton) {
        sessionQueue.async {
            /*
             The session might fail to start running. A failure to start the session running will be communicated via
             a session runtime error notification. To avoid repeatedly failing to start the session
             running, we only try to restart the session running in the session runtime error handler
             if we aren't trying to resume the session running.
             */
            self.session.startRunning()
            self.isSessionRunning = self.session.isRunning
            if !self.session.isRunning {
                DispatchQueue.main.async {
                    let message = NSLocalizedString("Unable to resume", comment: "Alert message when unable to resume the session running")
                    let actions = [
                        UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"),
                                      style: .cancel,
                                      handler: nil)]
                    self.alert(title: "AVCamFilter", message: message, actions: actions)
                }
            } else {
                DispatchQueue.main.async {
                    self.resumeButton.isHidden = true
                }
            }
        }
    }
    
    // MARK: - IBAction Functions
    
    /*
    /// - Tag: VaryFrameRate
    @IBAction private func changeDepthDataMaxFrameRate(_ sender: UISlider) {
        let depthDataMaxFrameRate = sender.value
        let newMinDuration = Double(1) / Double(depthDataMaxFrameRate)
        let duration = CMTimeMaximum(videoInput.device.activeVideoMinFrameDuration, CMTimeMakeWithSeconds(newMinDuration, preferredTimescale: 1000))
        
        self.depthDataMaxFrameRateValueLabel.text = String(format: "%.1f", depthDataMaxFrameRate)
        
        do {
            try self.videoInput.device.lockForConfiguration()
            self.videoInput.device.activeDepthDataMinFrameDuration = duration
            self.videoInput.device.unlockForConfiguration()
        } catch {
            print("Could not lock device for configuration: \(error)")
        }
    }
    
    /// - Tag: VaryMixFactor
    @IBAction private func changeMixFactor(_ sender: UISlider) {
        let mixFactor = sender.value
        self.mixFactorValueLabel.text = String(format: "%.1f", mixFactor)
        dataOutputQueue.async {
            self.videoDepthMixer.mixFactor = mixFactor
        }
        processingQueue.async {
            self.photoDepthMixer.mixFactor = mixFactor
        }
    }
    */
    @IBAction private func changeFilterSwipe(_ gesture: UISwipeGestureRecognizer) {
        let filteringEnabled = videoFilterOn
        if filteringEnabled {
            if gesture.direction == .left {
                filterIndex = (filterIndex + 1) % filterRenderers.count
            } else if gesture.direction == .right {
                filterIndex = (filterIndex + filterRenderers.count - 1) % filterRenderers.count
            }
            
            let newIndex = filterIndex
            let filterDescription = filterRenderers[newIndex].description
            updateFilterLabel(description: filterDescription)
            
            // Switch renderers
            dataOutputQueue.async {
                if let filter = self.videoFilter {
                    filter.reset()
                }
                self.videoFilter = self.filterRenderers[newIndex]
            }
            
            processingQueue.async {
                if let filter = self.photoFilter {
                    filter.reset()
                }
                self.photoFilter = self.photoRenderers[newIndex]
            }
        }
    }
    
    @IBAction private func focusAndExposeTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: previewView)
        guard let texturePoint = previewView.texturePointForView(point: location) else {
            return
        }
        
        let textureRect = CGRect(origin: texturePoint, size: .zero)
        let deviceRect = videoDataOutput.metadataOutputRectConverted(fromOutputRect: textureRect)
        focus(with: .autoFocus, exposureMode: .autoExpose, at: deviceRect.origin, monitorSubjectAreaChange: true)
    }
    
    @objc
    func subjectAreaDidChange(notification: NSNotification) {
        let devicePoint = CGPoint(x: 0.5, y: 0.5)
        focus(with: .continuousAutoFocus, exposureMode: .continuousAutoExposure, at: devicePoint, monitorSubjectAreaChange: false)
    }
    
    @IBAction private func changeCamera(_ sender: UIButton) {
        cameraButton.isEnabled = false
        photoButton.isEnabled = false
        
        dataOutputQueue.sync {
            renderingEnabled = false
            if let filter = videoFilter {
                filter.reset()
            }
            videoDepthMixer.reset()
            currentDepthPixelBuffer = nil
            videoDepthConverter.reset()
            previewView.pixelBuffer = nil
        }
        
        processingQueue.async {
            if let filter = self.photoFilter {
                filter.reset()
            }
            self.photoDepthMixer.reset()
            self.photoDepthConverter.reset()
        }
        
        let interfaceOrientation = statusBarOrientation
        var depthEnabled = depthVisualizationOn
        
        sessionQueue.async {
            let currentVideoDevice = self.videoInput.device
            var preferredPosition = AVCaptureDevice.Position.unspecified
            switch currentVideoDevice.position {
            case .unspecified, .front:
                preferredPosition = .back
                
            case .back:
                preferredPosition = .front
            @unknown default:
                fatalError("Unknown video device position.")
            }
            
            let devices = self.videoDeviceDiscoverySession.devices
            if let videoDevice = devices.first(where: { $0.position == preferredPosition }) {
                var videoInput: AVCaptureDeviceInput
                do {
                    videoInput = try AVCaptureDeviceInput(device: videoDevice)
                } catch {
                    print("Could not create video device input: \(error)")
                    self.dataOutputQueue.async {
                        self.renderingEnabled = true
                    }
                    return
                }
                self.session.beginConfiguration()
                
                // Remove the existing device input first, since using the front and back camera simultaneously is not supported.
                self.session.removeInput(self.videoInput)
                
                if self.session.canAddInput(videoInput) {
                    NotificationCenter.default.removeObserver(self,
                                                              name: NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange,
                                                              object: currentVideoDevice)
                    NotificationCenter.default.addObserver(self,
                                                           selector: #selector(self.subjectAreaDidChange),
                                                           name: NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange,
                                                           object: videoDevice)
                    
                    self.session.addInput(videoInput)
                    self.videoInput = videoInput
                } else {
                    print("Could not add video device input to the session")
                    self.session.addInput(self.videoInput)
                }
                
                if let unwrappedPhotoOutputConnection = self.photoOutput.connection(with: .video) {
                    self.photoOutput.connection(with: .video)!.videoOrientation = unwrappedPhotoOutputConnection.videoOrientation
                }
                
                if self.photoOutput.isDepthDataDeliverySupported {
                    self.photoOutput.isDepthDataDeliveryEnabled = depthEnabled
                    if let unwrappedDepthDataOutputConnection = self.depthDataOutput.connection(with: .depthData) {
                        unwrappedDepthDataOutputConnection.isEnabled = depthEnabled
                    }
                    if depthEnabled && self.outputSynchronizer == nil {
                        self.outputSynchronizer = AVCaptureDataOutputSynchronizer(dataOutputs: [self.videoDataOutput, self.depthDataOutput])
                        if let unwrappedOutputSynchronizer = self.outputSynchronizer {
                            unwrappedOutputSynchronizer.setDelegate(self, queue: self.dataOutputQueue)
                        }
                    }
                    
                    // Cap the video framerate at the max depth framerate
                    if let frameDuration = videoDevice.activeDepthDataFormat?.videoSupportedFrameRateRanges.first?.minFrameDuration {
                        do {
                            try videoDevice.lockForConfiguration()
                            videoDevice.activeVideoMinFrameDuration = frameDuration
                            videoDevice.unlockForConfiguration()
                        } catch {
                            print("Could not lock device for configuration: \(error)")
                        }
                    }
                } else {
                    self.outputSynchronizer = nil
                    depthEnabled = false
                }
                
                self.session.commitConfiguration()
            }
            
            let videoPosition = self.videoInput.device.position
            
            if let unwrappedVideoDataOutputConnection = self.videoDataOutput.connection(with: .video) {
                let rotation = PreviewMetalView.Rotation(with: interfaceOrientation,
                                                         videoOrientation: unwrappedVideoDataOutputConnection.videoOrientation,
                                                         cameraPosition: videoPosition)
                
                self.previewView.mirroring = (videoPosition == .front)
                if let rotation = rotation {
                    self.previewView.rotation = rotation
                }
            }
            
            self.dataOutputQueue.async {
                self.renderingEnabled = true
                self.depthVisualizationEnabled = depthEnabled
            }
            
            DispatchQueue.main.async {
                //self.updateDepthUIHidden()
                self.cameraButton.isEnabled = true
                self.photoButton.isEnabled = true
            }
        }
    }
    
    /*
    @IBAction private func toggleDepthVisualization() {
        depthVisualizationOn = !depthVisualizationOn
        var depthEnabled = depthVisualizationOn
        
        sessionQueue.async {
            self.session.beginConfiguration()
            
            if self.photoOutput.isDepthDataDeliverySupported {
                self.photoOutput.isDepthDataDeliveryEnabled = depthEnabled
            } else {
                depthEnabled = false
            }
            
            if let unwrappedDepthConnection = self.depthDataOutput.connection(with: .depthData) {
                unwrappedDepthConnection.isEnabled = depthEnabled
            }
            
            if depthEnabled {
                // Use an AVCaptureDataOutputSynchronizer to synchronize the video data and depth data outputs.
                // The first output in the dataOutputs array, in this case the AVCaptureVideoDataOutput, is the "master" output.
                self.outputSynchronizer = AVCaptureDataOutputSynchronizer(dataOutputs: [self.videoDataOutput, self.depthDataOutput])
                
                if let unwrappedOutputSynchronizer = self.outputSynchronizer {
                    unwrappedOutputSynchronizer.setDelegate(self, queue: self.dataOutputQueue)
                }
            } else {
                self.outputSynchronizer = nil
            }
            
            self.session.commitConfiguration()
            
            DispatchQueue.main.async {
                self.updateDepthUIHidden()
            }
            
            self.dataOutputQueue.async {
                if !depthEnabled {
                    self.videoDepthConverter.reset()
                    self.videoDepthMixer.reset()
                    self.currentDepthPixelBuffer = nil
                }
                self.depthVisualizationEnabled = depthEnabled
            }
            
            self.processingQueue.async {
                if !depthEnabled {
                    self.photoDepthMixer.reset()
                    self.photoDepthConverter.reset()
                }
            }
        }
    }
    
    
    /// - Tag: SmoothDepthData
    @IBAction private func toggleDepthSmoothing() {
        
        depthSmoothingOn = !depthSmoothingOn
        let smoothingEnabled = depthSmoothingOn
        
        let stateImage = UIImage(named: smoothingEnabled ? "DepthSmoothOn" : "DepthSmoothOff")
        self.depthSmoothingButton.setImage(stateImage, for: .normal)
        
        sessionQueue.async {
            self.depthDataOutput.isFilteringEnabled = smoothingEnabled
        }
    }
    */
    
    @IBAction private func toggleFiltering() {
        
        videoFilterOn = !videoFilterOn
        let filteringEnabled = videoFilterOn
        
        let stateImage = UIImage(named: filteringEnabled ? "ColorFilterOn" : "ColorFilterOff")
        self.videoFilterButton.setImage(stateImage, for: .normal)
        
        let index = filterIndex
        
        if filteringEnabled {
            let filterDescription = filterRenderers[index].description
            updateFilterLabel(description: filterDescription)
        }
        
        // Enable/disable the video filter.
        dataOutputQueue.async {
            if filteringEnabled {
                self.videoFilter = self.filterRenderers[index]
            } else {
                if let filter = self.videoFilter {
                    filter.reset()
                }
                self.videoFilter = nil
            }
        }
        
        // Enable/disable the photo filter.
        processingQueue.async {
            if filteringEnabled {
                self.photoFilter = self.photoRenderers[index]
            } else {
                if let filter = self.photoFilter {
                    filter.reset()
                }
                self.photoFilter = nil
            }
        }
    }
    
    @IBAction private func capturePhoto(_ photoButton: UIButton) {
        let depthEnabled = depthVisualizationOn
        
        sessionQueue.async {
            let photoSettings = AVCapturePhotoSettings(format: [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)])
            if depthEnabled && self.photoOutput.isDepthDataDeliverySupported {
                photoSettings.isDepthDataDeliveryEnabled = true
                photoSettings.embedsDepthDataInPhoto = false
            } else {
                photoSettings.isDepthDataDeliveryEnabled = depthEnabled
            }
            
            self.photoOutput.capturePhoto(with: photoSettings, delegate: self)
        }
    }
    
    // MARK: - UI Utility Functions
    /*
    func updateDepthUIHidden() {
        self.depthVisualizationButton.isHidden = !self.photoOutput.isDepthDataDeliverySupported
        self.depthVisualizationButton.setImage(UIImage(named: depthVisualizationOn ? "DepthVisualOn" : "DepthVisualOff"),
                                               for: .normal)
        self.depthSmoothingOn = depthVisualizationOn
        self.depthSmoothingButton.isHidden = !self.depthSmoothingOn
        self.depthSmoothingButton.setImage(UIImage(named: depthVisualizationOn ? "DepthSmoothOn" : "DepthSmoothOff"),
                                           for: .normal)
        self.mixFactorNameLabel.isHidden = !depthVisualizationOn
        self.mixFactorValueLabel.isHidden = !depthVisualizationOn
        self.mixFactorSlider.isHidden = !depthVisualizationOn
        self.depthDataMaxFrameRateNameLabel.isHidden = !depthVisualizationOn
        self.depthDataMaxFrameRateValueLabel.isHidden = !depthVisualizationOn
        self.depthDataMaxFrameRateSlider.isHidden = !depthVisualizationOn
    }
    */
    func updateFilterLabel(description: String) {
        filterLabel.text = description
        filterLabel.alpha = 0.0
        filterLabel.isHidden = false
        
        UIView.animate(withDuration: 0.25, animations: {
            self.filterLabel.alpha = 1.0
        }) { _ in
            UIView.animate(withDuration: 0.25, delay: 1.0, options: [], animations: {
                self.filterLabel.alpha = 0.0
            }, completion: { _ in })
        }
    }
    
    //gny ***********************************
    private var requests = [VNRequest]()
    
    @discardableResult
    func setupVision() -> NSError? {
        // Setup Vision parts
        
        let error: NSError! = nil
        
        guard let modelURL = Bundle.main.url(forResource: "bg_model_alpha", withExtension: "mlmodelc") else {
            return NSError(domain: "VisionObjectRecognitionViewController", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model file is missing"])
        }
        do {
            let visionModel = try VNCoreMLModel(for: MLModel(contentsOf: modelURL))
            let objectRecognition = VNCoreMLRequest(model: visionModel, completionHandler: { (rrequest, error) in
                
                guard let results = rrequest.results as? [VNClassificationObservation] else { return }

                /* Results array holds predictions iwth decreasing level of confidence.
                   Thus we choose the first one with highest confidence. */
                guard let firstResult = results.first else { return }
                                                                   
                //var predictionString = ""
                
                DispatchQueue.main.async(execute: {
                    // perform all the UI updates on the main queue
                    
                    self.BackgroundPredictLabel.text = firstResult.identifier
                        //+ "(\(firstResult.confidence))"
                })
            })
            self.requests = [objectRecognition]
        } catch let error as NSError {
            print("Model loading went wrong: \(error)")
        }
        
        
        return error
    }
    
    //yoloyolo
    func setUpVision2() {
      guard let visionModel = try? VNCoreMLModel(for: yolo.model.model) else {
        print("Error: could not create Vision model")
        return
      }

      for _ in 0..<CameraViewController.maxInflightBuffers {
        let request = VNCoreMLRequest(model: visionModel, completionHandler: visionRequestDidComplete)

        // NOTE: If you choose another crop/scale option, then you must also
        // change how the BoundingBox objects get scaled when they are drawn.
        // Currently they assume the full input image is used.
        request.imageCropAndScaleOption = .scaleFill
        requests.append(request)
      }
    }
    
    func visionRequestDidComplete(request: VNRequest, error: Error?) {
      if let observations = request.results as? [VNCoreMLFeatureValueObservation],
         let features = observations.first?.featureValue.multiArrayValue {

        let boundingBoxes = yolo.computeBoundingBoxes(features: features)
        let elapsed = CACurrentMediaTime() //- startTimes.remove(at: 0)
        showOnMainThread(boundingBoxes, elapsed)
      } else {
        print("BOGUS!")
      }

      self.semaphore.signal()
    }
    
    func showOnMainThread(_ boundingBoxes: [YOLO.Prediction], _ elapsed: CFTimeInterval) {
      if drawBoundingBoxes {
        DispatchQueue.main.async {
          // For debugging, to make sure the resized CVPixelBuffer is correct.
          //var debugImage: CGImage?
          //VTCreateCGImageFromCVPixelBuffer(resizedPixelBuffer, nil, &debugImage)
          //self.debugImageView.image = UIImage(cgImage: debugImage!)

          self.show(predictions: boundingBoxes)

          let fps = self.measureFPS()
          //self.timeLabel.text = String(format: "Elapsed %.5f seconds - %.2f FPS", elapsed, fps)
        }
      }
    }
    
    func measureFPS() -> Double {
      // Measure how many frames were actually delivered per second.
      framesDone += 1
      let frameCapturingElapsed = CACurrentMediaTime() - frameCapturingStartTime
      let currentFPSDelivered = Double(framesDone) / frameCapturingElapsed
      if frameCapturingElapsed > 1 {
        framesDone = 0
        frameCapturingStartTime = CACurrentMediaTime()
      }
      return currentFPSDelivered
    }
    
    func show(predictions: [YOLO.Prediction]) {
    //boundingBoxes.count
      for i in 0..<boundingBoxes.count {
        if i < predictions.count {
          pcount = predictions.count
          let prediction = predictions[i]

          // The predicted bounding box is in the coordinate space of the input
          // image, which is a square image of 416x416 pixels. We want to show it
          // on the video preview, which is as wide as the screen and has a 16:9
          // aspect ratio. The video preview also may be letterboxed at the top
          // and bottom.
          let width = view.bounds.width
          let height = width * 4 / 3
          let scaleX = width / CGFloat(YOLO.inputWidth)
          let scaleY = height / CGFloat(YOLO.inputHeight)
          let top = (view.bounds.height - height) / 2

          // Translate and scale the rectangle to our own coordinate system.
          var rect = prediction.rect
          rect.origin.x *= scaleX
          rect.origin.y *= scaleY
          rect.origin.y += top
          rect.size.width *= scaleX
          rect.size.height *= scaleY

          // Show the bounding box.
            
            
          //let label = String(format: "%@ %.1f", labels[prediction.classIndex], prediction.score * 100)
            let label = String(format: "%@", labels[prediction.classIndex])
            //print(label)
            let color = UIColor.white//colors[prediction.classIndex]
          boundingBoxes[i].show(frame: rect, label: label, color: color)
        } else {
          boundingBoxes[i].hide()
        }
      }
    }
    
    ///
    
    public func exifOrientationFromDeviceOrientation() -> CGImagePropertyOrientation {
        let curDeviceOrientation = UIDevice.current.orientation
        let exifOrientation: CGImagePropertyOrientation
        
        switch curDeviceOrientation {
        case UIDeviceOrientation.portraitUpsideDown:  // Device oriented vertically, home button on the top
            exifOrientation = .left
        case UIDeviceOrientation.landscapeLeft:       // Device oriented horizontally, home button on the right
            exifOrientation = .upMirrored
        case UIDeviceOrientation.landscapeRight:      // Device oriented horizontally, home button on the left
            exifOrientation = .down
        case UIDeviceOrientation.portrait:            // Device oriented vertically, home button on the bottom
            exifOrientation = .up
        default:
            exifOrientation = .up
        }
        return exifOrientation
    }
    //***********************************
    
    // MARK: - Video Data Output Delegate
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        processVideo(sampleBuffer: sampleBuffer)
    }
    
    func processVideo(sampleBuffer: CMSampleBuffer) {
        if !renderingEnabled {
            return
        }
        
        guard let videoPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
            let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) else {
                return
        }
        
        //gny******************************************
        
        let ciImage = CIImage(cvPixelBuffer: videoPixelBuffer)

        let srcWidth = CGFloat(ciImage.extent.width)
        let srcHeight = CGFloat(ciImage.extent.height)

        let dstWidth: CGFloat = 144
        let dstHeight: CGFloat = 144

        let scaleX = dstWidth / srcWidth
        let scaleY = dstHeight / srcHeight
        //let scale = min(scaleX, scaleY)

        let transform = CGAffineTransform.init(scaleX: scaleX, y: scaleY)
        let output = ciImage.transformed(by: transform).cropped(to: CGRect(x: 0, y: 0, width: dstWidth, height: dstHeight))

        let exifOrientation = exifOrientationFromDeviceOrientation()
        let finalImage = output.oriented(.right) //회전부분 수정해야됨
        
        let inflightIndex = inflightBuffer
        inflightBuffer += 1
        if inflightBuffer >= CameraViewController.maxInflightBuffers {
          inflightBuffer = 0
        }
        DispatchQueue.main.async(execute: {
            // perform all the UI updates on the main queue
            self.predict(pixelBuffer: videoPixelBuffer, inflightIndex: inflightIndex)
            
            //self.PredictImage.image = UIImage(ciImage: finalImage)
        })
        
        //let finalpixelBuffer = UIImage(ciImage: output)
        
        ////////////
        
        
        
        //let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: videoPixelBuffer, orientation: exifOrientation, options: [:])
        let imageRequestHandler = VNImageRequestHandler(ciImage: finalImage,  options: [:])
        
        do {
            try imageRequestHandler.perform(self.requests)
        } catch {
            print(error)
        }
        
        
        
        //******************************************
        
        var finalVideoPixelBuffer = videoPixelBuffer
        if let filter = videoFilter {
            if !filter.isPrepared {
                /*
                 outputRetainedBufferCountHint is the number of pixel buffers the renderer retains. This value informs the renderer
                 how to size its buffer pool and how many pixel buffers to preallocate. Allow 3 frames of latency to cover the dispatch_async call.
                 */
                filter.prepare(with: formatDescription, outputRetainedBufferCountHint: 3)
            }
            
            // Send the pixel buffer through the filter
            guard let filteredBuffer = filter.render(pixelBuffer: finalVideoPixelBuffer) else {
                print("Unable to filter video buffer")
                return
            }
            
            finalVideoPixelBuffer = filteredBuffer
        }
        
        if depthVisualizationEnabled {
            if !videoDepthMixer.isPrepared {
                videoDepthMixer.prepare(with: formatDescription, outputRetainedBufferCountHint: 3)
            }
            
            if let depthBuffer = currentDepthPixelBuffer {
                
                // Mix the video buffer with the last depth data received.
                guard let mixedBuffer = videoDepthMixer.mix(videoPixelBuffer: finalVideoPixelBuffer, depthPixelBuffer: depthBuffer) else {
                    print("Unable to combine video and depth")
                    return
                }
                
                finalVideoPixelBuffer = mixedBuffer
            }
        }
        
        previewView.pixelBuffer = finalVideoPixelBuffer
    }
    
    // MARK: - Depth Data Output Delegate
    
    /// - Tag: StreamDepthData
    func depthDataOutput(_ depthDataOutput: AVCaptureDepthDataOutput, didOutput depthData: AVDepthData, timestamp: CMTime, connection: AVCaptureConnection) {
        processDepth(depthData: depthData)
    }
    
    func processDepth(depthData: AVDepthData) {
        if !renderingEnabled {
            return
        }
        
        if !depthVisualizationEnabled {
            return
        }
        
        if !videoDepthConverter.isPrepared {
            var depthFormatDescription: CMFormatDescription?
            CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                                         imageBuffer: depthData.depthDataMap,
                                                         formatDescriptionOut: &depthFormatDescription)
            if let unwrappedDepthFormatDescription = depthFormatDescription {
                videoDepthConverter.prepare(with: unwrappedDepthFormatDescription, outputRetainedBufferCountHint: 2)
            }
        }
        
        guard let depthPixelBuffer = videoDepthConverter.render(pixelBuffer: depthData.depthDataMap) else {
            print("Unable to process depth")
            return
        }
        
        currentDepthPixelBuffer = depthPixelBuffer
    }
    
    // MARK: - Video + Depth Output Synchronizer Delegate
    
    func dataOutputSynchronizer(_ synchronizer: AVCaptureDataOutputSynchronizer, didOutput synchronizedDataCollection: AVCaptureSynchronizedDataCollection) {
        
        if let syncedDepthData: AVCaptureSynchronizedDepthData = synchronizedDataCollection.synchronizedData(for: depthDataOutput) as? AVCaptureSynchronizedDepthData {
            if !syncedDepthData.depthDataWasDropped {
                let depthData = syncedDepthData.depthData
                processDepth(depthData: depthData)
            }
        }
        
        if let syncedVideoData: AVCaptureSynchronizedSampleBufferData = synchronizedDataCollection.synchronizedData(for: videoDataOutput) as? AVCaptureSynchronizedSampleBufferData {
            if !syncedVideoData.sampleBufferWasDropped {
                let videoSampleBuffer = syncedVideoData.sampleBuffer
                processVideo(sampleBuffer: videoSampleBuffer)
            }
        }
    }
    
    // MARK: - Photo Output Delegate
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        flashScreen()
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error)")
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let photoPixelBuffer = photo.pixelBuffer else {
            print("Error occurred while capturing photo: Missing pixel buffer (\(String(describing: error)))")
            return
        }
        
        var photoFormatDescription: CMFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                                     imageBuffer: photoPixelBuffer,
                                                     formatDescriptionOut: &photoFormatDescription)
        
        processingQueue.async {
            var finalPixelBuffer = photoPixelBuffer
            if let filter = self.photoFilter {
                if !filter.isPrepared {
                    if let unwrappedPhotoFormatDescription = photoFormatDescription {
                        filter.prepare(with: unwrappedPhotoFormatDescription, outputRetainedBufferCountHint: 2)
                    }
                }
                
                guard let filteredPixelBuffer = filter.render(pixelBuffer: finalPixelBuffer) else {
                    print("Unable to filter photo buffer")
                    return
                }
                finalPixelBuffer = filteredPixelBuffer
            }
            
            if let depthData = photo.depthData {
                let depthPixelBuffer = depthData.depthDataMap
                
                if !self.photoDepthConverter.isPrepared {
                    var depthFormatDescription: CMFormatDescription?
                    CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                                                 imageBuffer: depthPixelBuffer,
                                                                 formatDescriptionOut: &depthFormatDescription)
                    
                    /*
                     outputRetainedBufferCountHint is the number of pixel buffers we expect to hold on to from the renderer.
                     This value informs the renderer how to size its buffer pool and how many pixel buffers to preallocate.
                     Allow 3 frames of latency to cover the dispatch_async call.
                     */
                    if let unwrappedDepthFormatDescription = depthFormatDescription {
                        self.photoDepthConverter.prepare(with: unwrappedDepthFormatDescription, outputRetainedBufferCountHint: 3)
                    }
                }
                
                guard let convertedDepthPixelBuffer = self.photoDepthConverter.render(pixelBuffer: depthPixelBuffer) else {
                    print("Unable to convert depth pixel buffer")
                    return
                }
                
                if !self.photoDepthMixer.isPrepared {
                    if let unwrappedPhotoFormatDescription = photoFormatDescription {
                        self.photoDepthMixer.prepare(with: unwrappedPhotoFormatDescription, outputRetainedBufferCountHint: 2)
                    }
                }
                
                // Combine image and depth map
                guard let mixedPixelBuffer = self.photoDepthMixer.mix(videoPixelBuffer: finalPixelBuffer,
                                                                      depthPixelBuffer: convertedDepthPixelBuffer)
                    else {
                        print("Unable to mix depth and photo buffers")
                        return
                }
                
                finalPixelBuffer = mixedPixelBuffer
            }
            
            let metadataAttachments: CFDictionary = photo.metadata as CFDictionary
            guard let jpegData = CameraViewController.jpegData(withPixelBuffer: finalPixelBuffer, attachments: metadataAttachments) else {
                print("Unable to create JPEG photo")
                return
            }
            
            // Save JPEG to photo library
            PHPhotoLibrary.requestAuthorization { status in
                if status == .authorized {
                    PHPhotoLibrary.shared().performChanges({
                        let creationRequest = PHAssetCreationRequest.forAsset()
                        creationRequest.addResource(with: .photo, data: jpegData, options: nil)
                    }, completionHandler: { _, error in
                        if let error = error {
                            print("Error occurred while saving photo to photo library: \(error)")
                        }
                    })
                }
            }
        }
    }
    
    // MARK: - Utilities
    private func capFrameRate(videoDevice: AVCaptureDevice) {
        if self.photoOutput.isDepthDataDeliverySupported {
            // Cap the video framerate at the max depth framerate.
            if let frameDuration = videoDevice.activeDepthDataFormat?.videoSupportedFrameRateRanges.first?.minFrameDuration {
                do {
                    try videoDevice.lockForConfiguration()
                    videoDevice.activeVideoMinFrameDuration = frameDuration
                    videoDevice.unlockForConfiguration()
                } catch {
                    print("Could not lock device for configuration: \(error)")
                }
            }
        }
    }
    
    private func focus(with focusMode: AVCaptureDevice.FocusMode, exposureMode: AVCaptureDevice.ExposureMode, at devicePoint: CGPoint, monitorSubjectAreaChange: Bool) {
        
        sessionQueue.async {
            let videoDevice = self.videoInput.device
            
            do {
                try videoDevice.lockForConfiguration()
                if videoDevice.isFocusPointOfInterestSupported && videoDevice.isFocusModeSupported(focusMode) {
                    videoDevice.focusPointOfInterest = devicePoint
                    videoDevice.focusMode = focusMode
                }
                
                if videoDevice.isExposurePointOfInterestSupported && videoDevice.isExposureModeSupported(exposureMode) {
                    videoDevice.exposurePointOfInterest = devicePoint
                    videoDevice.exposureMode = exposureMode
                }
                
                videoDevice.isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
                videoDevice.unlockForConfiguration()
            } catch {
                print("Could not lock device for configuration: \(error)")
            }
        }
    }
    
    func alert(title: String, message: String, actions: [UIAlertAction]) {
        let alertController = UIAlertController(title: title,
                                                message: message,
                                                preferredStyle: .alert)
        
        actions.forEach {
            alertController.addAction($0)
        }
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    // Flash the screen to signal that AVCamFilter took a photo.
    func flashScreen() {
        let flashView = UIView(frame: self.previewView.frame)
        self.view.addSubview(flashView)
        flashView.backgroundColor = .black
        flashView.layer.opacity = 1
        UIView.animate(withDuration: 0.25, animations: {
            flashView.layer.opacity = 0
        }, completion: { _ in
            flashView.removeFromSuperview()
        })
    }
    
    private class func jpegData(withPixelBuffer pixelBuffer: CVPixelBuffer, attachments: CFDictionary?) -> Data? {
        let ciContext = CIContext()
        let renderedCIImage = CIImage(cvImageBuffer: pixelBuffer)
        guard let renderedCGImage = ciContext.createCGImage(renderedCIImage, from: renderedCIImage.extent) else {
            print("Failed to create CGImage")
            return nil
        }
        
        guard let data = CFDataCreateMutable(kCFAllocatorDefault, 0) else {
            print("Create CFData error!")
            return nil
        }
        
        guard let cgImageDestination = CGImageDestinationCreateWithData(data, kUTTypeJPEG, 1, nil) else {
            print("Create CGImageDestination error!")
            return nil
        }
        
        CGImageDestinationAddImage(cgImageDestination, renderedCGImage, attachments)
        if CGImageDestinationFinalize(cgImageDestination) {
            return data as Data
        }
        print("Finalizing CGImageDestination error!")
        return nil
    }
}

extension AVCaptureVideoOrientation {
    init?(interfaceOrientation: UIInterfaceOrientation) {
        switch interfaceOrientation {
        case .portrait: self = .portrait
        case .portraitUpsideDown: self = .portraitUpsideDown
        case .landscapeLeft: self = .landscapeLeft
        case .landscapeRight: self = .landscapeRight
        default: return nil
        }
    }
}

extension PreviewMetalView.Rotation {
    init?(with interfaceOrientation: UIInterfaceOrientation, videoOrientation: AVCaptureVideoOrientation, cameraPosition: AVCaptureDevice.Position) {
        /*
         Calculate the rotation between the videoOrientation and the interfaceOrientation.
         The direction of the rotation depends upon the camera position.
         */
        switch videoOrientation {
        case .portrait:
            switch interfaceOrientation {
            case .landscapeRight:
                if cameraPosition == .front {
                    self = .rotate90Degrees
                } else {
                    self = .rotate270Degrees
                }
                
            case .landscapeLeft:
                if cameraPosition == .front {
                    self = .rotate270Degrees
                } else {
                    self = .rotate90Degrees
                }
                
            case .portrait:
                self = .rotate0Degrees
                
            case .portraitUpsideDown:
                self = .rotate180Degrees
                
            default: return nil
            }
        case .portraitUpsideDown:
            switch interfaceOrientation {
            case .landscapeRight:
                if cameraPosition == .front {
                    self = .rotate270Degrees
                } else {
                    self = .rotate90Degrees
                }
                
            case .landscapeLeft:
                if cameraPosition == .front {
                    self = .rotate90Degrees
                } else {
                    self = .rotate270Degrees
                }
                
            case .portrait:
                self = .rotate180Degrees
                
            case .portraitUpsideDown:
                self = .rotate0Degrees
                
            default: return nil
            }
            
        case .landscapeRight:
            switch interfaceOrientation {
            case .landscapeRight:
                self = .rotate0Degrees
                
            case .landscapeLeft:
                self = .rotate180Degrees
                
            case .portrait:
                if cameraPosition == .front {
                    self = .rotate270Degrees
                } else {
                    self = .rotate90Degrees
                }
                
            case .portraitUpsideDown:
                if cameraPosition == .front {
                    self = .rotate90Degrees
                } else {
                    self = .rotate270Degrees
                }
                
            default: return nil
            }
            
        case .landscapeLeft:
            switch interfaceOrientation {
            case .landscapeLeft:
                self = .rotate0Degrees
                
            case .landscapeRight:
                self = .rotate180Degrees
                
            case .portrait:
                if cameraPosition == .front {
                    self = .rotate90Degrees
                } else {
                    self = .rotate270Degrees
                }
                
            case .portraitUpsideDown:
                if cameraPosition == .front {
                    self = .rotate270Degrees
                } else {
                    self = .rotate90Degrees
                }
                
            default: return nil
            }
        @unknown default:
            fatalError("Unknown orientation.")
        }
    }
}

class TagAlertView: UIViewController {
    
    
    let ad = UIApplication.shared.delegate as? AppDelegate

    @IBOutlet weak var PersonsButton: UISegmentedControl!
    
    @IBOutlet weak var BackgroundButton: UISegmentedControl!
    @IBOutlet weak var StyleButton: UISegmentedControl!
    
    @IBOutlet weak var EtcButton: UISegmentedControl!
    
    
    @IBOutlet weak var OkButton: UIButton!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        PersonsButton.selectedSegmentIndex = ad?.persons ?? 0
        BackgroundButton.selectedSegmentIndex = ad?.background ?? 0
        StyleButton.selectedSegmentIndex = ad?.style ?? 0
        EtcButton.selectedSegmentIndex = ad?.etc ?? 0
        
        OkButton.addTarget(self, action: #selector(dismissView), for: .touchUpInside)
        // Do any additional setup after loading the view.
    }
    
    @objc func dismissView(){
        
        ad?.persons = PersonsButton.selectedSegmentIndex
        ad?.background = BackgroundButton.selectedSegmentIndex
        ad?.style = StyleButton.selectedSegmentIndex
        ad?.etc = EtcButton.selectedSegmentIndex
        
        dismiss(animated: false, completion: nil)
    }

}


/// Open SQLite Database
/*
private func openSQLite(path: String) -> OpaquePointer? {
    
    var database: OpaquePointer? = nil
    
    // Many of the SQLite functions return an Int32 result code. Most of these codes are defined as constants in the SQLite library. For example, SQLITE_OK represents the result code 0.
    guard sqlite3_open(path, &database) == SQLITE_OK else {
        print("‼️ Unable to open database.")
        return nil
    }
    
    // Success Open SQLite Database
    print("✅ Successfully opened connection to database at \(path)")
    return database
}

/// Create SQLite Database Table
private func createSQLiteTable(database: OpaquePointer, statement: String) -> Bool {
    
    var createStatement: OpaquePointer? = nil
    
    // You must always call sqlite3_finalize() on your compiled statement to delete it and avoid resource leaks.
    defer { sqlite3_finalize(createStatement) }
        
    guard sqlite3_prepare_v2(database, statement, EOF, &createStatement, nil) == SQLITE_OK else {
        print("‼️ CREATE TABLE statement could not be prepared.")
        return false
    }
    
    // sqlite3_step() runs the compiled statement.
    if sqlite3_step(createStatement) == SQLITE_DONE {
        print("✅ Success, Contact table created.")
    } else {
        print("‼️ Fail, Contact table could not be created.")
    }
    
    return true
}

/// Insert Data into SQLite Database Table
private func insertSQLiteTable(database: OpaquePointer, statement: String) -> Bool {
    
    var insertStatement: OpaquePointer? = nil
    
    // You must always call sqlite3_finalize() on your compiled statement to delete it and avoid resource leaks.
    defer { sqlite3_finalize(insertStatement) }
    
    guard sqlite3_prepare_v2(database, statement, EOF, &insertStatement, nil) == SQLITE_OK else {
        print("‼️ Insert TABLE statement could not be prepared.")
        return false
    }
    
    // Use the sqlite3_step() function to execute the statement and verify that it finished.
    if sqlite3_step(insertStatement) == SQLITE_DONE {
        print("✅ Success, Insert Data.")
    } else {
        print("‼️ Fail, Insert Data.")
        return false
    }
    
    return true
}

/// Implement Query SQLite
private func qeurySQLite(database: OpaquePointer, statment: String) -> Bool{
    
    var plist : [Int] = []
    
    var queryStatment: OpaquePointer? = nil
    
    // You must always call sqlite3_finalize() on your compiled statement to delete it and avoid resource leaks.
    defer { sqlite3_finalize(queryStatment) }
    
    guard sqlite3_prepare_v2(database, statment, EOF, &queryStatment, nil) == SQLITE_OK else {
        print("‼️ Query statement could not be prepared.")
        return false
    }
    
    if sqlite3_step(queryStatment) == SQLITE_ROW {
        
        let id = sqlite3_column_int(queryStatment, 0)
        let name = sqlite3_column_text(queryStatment, 1)
        plist.append(Int(id))
        print("→ \(id) | \(String(describing: name))")
    }
    else {
        print("\nQuery returned no results.")
        return false
    }
    
    return true
}
*/
