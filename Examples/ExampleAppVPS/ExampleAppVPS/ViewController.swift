import ARKit
import VPSNMobile

enum Location {
    case Polytech
    case VDNH_Arch
    case VDNH_Pavilion
    case Artplay
    case Flacon
    case GorkyPark
    case Hlebzavod
}

class ViewController: UIViewController, ARSCNViewDelegate {
    @IBOutlet weak var sceneView: ARSCNView!
    
    @IBOutlet weak var statuslbl: UILabel!
    @IBOutlet weak var starte: UIButton!
    var vps: VPSService?
    var firstLocalize = true
    var firstLoading = 0 {
        didSet {
            if firstLoading == 2 {
                downloadView?.removeFromSuperview()
                downloadView = nil
            }
        }
    }
    var oldGraphics: SCNNode = SCNNode()
    var configuration: ARWorldTrackingConfiguration!
    
    var locationId = ""
    
    let currentLocation: Location = .Polytech
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.scene = SCNScene()
        sceneView.delegate = self
        addloading()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.downloadView?.loading()
            self.downloadView?.addAnimate()
        }
        if let config = VPSBuilder.getDefaultConfiguration() {
            configuration = config
        } else {
            fatalError()
        }
        
        locationId = getLocationId(loc: currentLocation)
        
        let set = Settings(
                locationIds: [locationId],
                recognizeType: .mobile)
        
        VPSBuilder.initializeVPS(arsession: sceneView.session,
                                 settings: set,
                                 gpsUsage: true,
                                 delegate: self) { (serc) in
            self.vps = serc
            self.firstLoading += 1
        } loadingProgress: { (pr) in
            if let prv = self.downloadView {
                prv.downloading()
                prv.progbar.progress = Float(pr)
            } else {
                self.downloadView?.downloading()
            }
        } failure: { (er) in
            print("err",er)
        }
        
        let longgest = UILongPressGestureRecognizer(target: self, action: #selector(longg))
        longgest.minimumPressDuration = 1
        view.addGestureRecognizer(longgest)
        addContent()
    }
    
    func addContent() {
        DispatchQueue.global().async {
            let scene = self.sceneView.scene
            let sten = self.loadOccluder(loc: self.currentLocation)
            sten.renderingOrder = -100
//            sten?.geometry?.firstMaterial?.transparency = 0.5
            sten.geometry?.firstMaterial?.isDoubleSided = true
            sten.renderingOrder = -100
            sten.geometry?.firstMaterial?.colorBufferWriteMask = .alpha
            
            let old = SCNScene(named: self.getContentName(loc: self.currentLocation))!
            old.rootNode.childNodes.forEach { (node) in
                scene.rootNode.addChildNode(node)
                self.setContentPosition(loc: self.currentLocation, content: node)
            }
            self.oldGraphics.name = "oldGraphics"
            scene.rootNode.addChildNode(sten)
            self.sceneView.prepare([scene]) { bol in
                if bol {
                    scene.rootNode.childNodes.forEach({$0.isHidden = true})
                    self.firstLoading += 1
                }
            }
        }
    }
    
    @objc func longg(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            guard var vps = vps else { return  }
            let root = self.sceneView.scene.rootNode
            var geometryChild: SCNNode? = nil
            for child in root.childNodes {
                if child.geometry != nil {
                    geometryChild = child
                }
            }

            guard let model = geometryChild
            else { return }
            let hid = model.geometry!.firstMaterial!.colorBufferWriteMask != .alpha
            let vc = DebugPopVC(autoFocusOn: configuration.isAutoFocusEnabled,
                                showModels: hid,
                                gpsOn: vps.gpsUsage)
            self.present(vc, animated: true, completion: nil)
            vc.closeHandler = {
                vc.dismiss(animated: true, completion: nil)
            }
            vc.focusHandler = { (en) in
                self.configuration.isAutoFocusEnabled = en
                self.sceneView.session.run(self.configuration)
            }
            vc.modelHandler = {(en) in
                model.geometry?.firstMaterial!.colorBufferWriteMask = en ? .all : .alpha
            }
            vc.gpsHandler = { (en) in
                vps.gpsUsage = en
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sceneView.session.run(configuration)
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    @IBAction func start(_ sender: UIButton) {
        statuslbl.isHidden = false
        if sender.titleLabel?.text == "Start" {
            vps?.start()
            sender.backgroundColor = .red
            sender.setTitle("stop", for: .normal)
        } else {
            vps?.stop()
            sender.backgroundColor = .green
            sender.setTitle("Start", for: .normal)
        }
    }
   
    func sessionWasInterrupted(_ session: ARSession) {
        vps?.stop()
        starte.isHidden = false
        starte.backgroundColor = .green
        starte.setTitle("start", for: .normal)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        vps?.frameUpdated()
    }
    
    var downloadView: DownLaunchAR?
    func addloading() {
        downloadView = DownLaunchAR()
        downloadView?.loading()
        downloadView?.closeHandler = {
            self.downloadView?.removeFromSuperview()
            self.downloadView = nil
        }
        downloadView?.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(downloadView!)
        self.view.addConstraints([
            downloadView!.topAnchor.constraint(equalTo: self.view.topAnchor),
            downloadView!.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            downloadView!.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            downloadView!.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        ])
    }
    
    func loadOccluder(loc: Location) -> SCNNode {
        switch(loc) {
        case .Polytech:
            let roomscene = SCNScene(named: "PolytechOccluder.dae")!
            return roomscene.rootNode.childNodes[0]
        case .VDNH_Arch:
            let roomscene = SCNScene(named: "VDNH_Arch.dae")!
            return roomscene.rootNode.childNodes[0]
        case .VDNH_Pavilion:
            let roomscene = SCNScene(named: "VDNH_Pavilion.dae")!
            return roomscene.rootNode.childNodes[0]
        case .Artplay:
            let roomscene = SCNScene(named: "ArtplayOccluder.dae")!
            return roomscene.rootNode.childNodes[0]
        case .Flacon:
            let roomscene = SCNScene(named: "FlaconOccluder.dae")!
            return roomscene.rootNode.childNodes[0]
        case .GorkyPark:
            let roomscene = SCNScene(named: "GorkyOccluder.dae")!
            return roomscene.rootNode.childNodes[0]
        case .Hlebzavod:
            let roomscene = SCNScene(named: "Khlebzavod.dae")!
            return roomscene.rootNode.childNodes[0]
        }
    }
    
    func getLocationId(loc: Location) -> String {
        switch(loc) {
        case .Polytech:
            return "polytech"
        case .VDNH_Arch:
            return "vdnh_arka"
        case .VDNH_Pavilion:
            return "vdnh_pavilion"
        case .Artplay:
            return "artplay"
        case .Flacon:
            return "flacon"
        case .GorkyPark:
            return "gorky_park"
        case .Hlebzavod:
            return "hlebozavod9"
        }
    }
    
    func setContentPosition(loc: Location, content: SCNNode) {
        switch(loc) {
        case .Polytech:
            content.position = SCNVector3(53, 31.2, -35)
            content.eulerAngles = SCNVector3(0, 0, 0)
        case .VDNH_Arch:
            content.position = SCNVector3(-28.6, 28.1, -5.8)
            content.eulerAngles = SCNVector3(0, 40, 0)
        case .VDNH_Pavilion:
            content.position = SCNVector3(21.2, 16.6, -31.9)
            content.eulerAngles = SCNVector3(0, 222, 0)
        case .Artplay:
            break
        case .Flacon:
            content.position = SCNVector3(-26.3, 12.1, -15)
            content.eulerAngles = SCNVector3(0, 0, 0)
            content.scale = SCNVector3(0.5, 0.5, 0.5)
        case .GorkyPark:
            content.position = SCNVector3(-27, 20, 34)
            content.eulerAngles = SCNVector3(0, 29.2, 0)
        case .Hlebzavod:
            content.position = SCNVector3(20.8, 14.7, 49.2)
            content.eulerAngles = SCNVector3(0, 0, 0)
        }
    }
    
    func getContentName(loc: Location) -> String {
        if loc == .Artplay {
            return "RobotsArtplay.scn"
        }
        else {
            return "DemoRobot.dae"
        }
    }
}

extension ViewController: VPSServiceDelegate {
    func correctMotionAngle(correct: Bool) {
        print("Angle is \(correct ? "correct" : "incorrect")")
    }

    func sending() {
        statuslbl.backgroundColor = .cyan
        statuslbl.text = "Send"
    }

    func error(err: NSError) {
        print("err", err)
        statuslbl.backgroundColor = .red
        statuslbl.text = "Error"
    }

    func positionVPS(pos: ResponseVPSPhoto) {
        print("delegate", pos)
        if !pos.status {
            statuslbl.backgroundColor = .yellow
            statuslbl.text = "Fail"
        } else {
            statuslbl.backgroundColor = .green
            statuslbl.text = "Success"
            if firstLocalize {
                firstLocalize = false
                sceneView.scene.rootNode.childNodes.forEach { (node) in
                    node.isHidden = false
                }
            }
        }
    }
}
