//
//  ViewController.swift
//  Ikea
//
//  Created by Ivan Ken Tiu on 25/09/2017.
//  Copyright © 2017 FinalShift Inc. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, ARSCNViewDelegate {

    @IBOutlet weak var planeDetected: UILabel!
    // string matches filename in terms of spelling
    let itemsArray: [String] = ["cup", "vase", "boxing", "table"]
    @IBOutlet weak var itemsCollectionView: UICollectionView!
    @IBOutlet weak var sceneView: ARSCNView!
    
    let configuration = ARWorldTrackingConfiguration()
    var selectedItem: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
        self.sceneView.session.run(configuration)
        self.configuration.planeDetection = .horizontal
        self.itemsCollectionView.dataSource = self
        self.itemsCollectionView.delegate = self
        self.sceneView.delegate = self
        // make sure to register recognizers!
        self.registerGestureRecognizers()
        self.sceneView.autoenablesDefaultLighting = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // from UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return itemsArray.count
    }
    
    // all gestures here!
    func registerGestureRecognizers() {
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinch))
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(rotate))
        longPressGestureRecognizer.minimumPressDuration = 0.1
        self.sceneView.addGestureRecognizer(longPressGestureRecognizer)
        self.sceneView.addGestureRecognizer(pinchGestureRecognizer)
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func rotate(sender: UILongPressGestureRecognizer) {
        let sceneView = sender.view as! ARSCNView
        let holdLocation = sender.location(in: sceneView)
        let hitTest = sceneView.hitTest(holdLocation)
        if !hitTest.isEmpty {
            let result = hitTest.first!
            // start holding with finger
            if sender.state == .began {
                let rotation = SCNAction.rotateBy(x: 0, y: CGFloat(360.degreesToRadians), z: 0, duration: 1)
                let forever = SCNAction.repeatForever(rotation)
                result.node.runAction(forever)
            } else if sender.state == .ended {
                result.node.removeAllActions()
            }
        }
    }
    
    @objc func pinch(sender: UIPinchGestureRecognizer) {
        let sceneView = sender.view as! ARSCNView
        let pinchLocation = sender.location(in: sceneView)
        let hitTest = sceneView.hitTest(pinchLocation)
        
        if !hitTest.isEmpty {
            let results = hitTest.first!
            // the node that you pinched
            let node = results.node
            // scale based on how far you pinched (grow or shrink immediately 0
            let pinchAction = SCNAction.scale(by: sender.scale, duration: 0)
            node.runAction(pinchAction)
            // constant scaling
            sender.scale = 1.0
        }
    }
    
    @objc func tapped(sender: UITapGestureRecognizer) {
        // on horizontal / ARSCNView bec not object like previous jellyfish(SCNView)
        let sceneView = sender.view as! ARSCNView
        let tapLocation = sender.location(in: sceneView)
        let hitTest = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
        
        // if not empty
        if !hitTest.isEmpty {
            self.addItem(hitTestResult: hitTest.first!)
        }
    }
    
    func addItem(hitTestResult: ARHitTestResult) {
        // from didSelect ItemAt (if not nil navigate to scene which has that item)
        if let selectedItem = self.selectedItem {
            // load scene of item we want to place
            let scene = SCNScene(named: "Models.scnassets/\(selectedItem).scn")
            // get the node inside of scn (parenthesis node is optional (unwrap)
            let node = (scene?.rootNode.childNode(withName: selectedItem, recursively: false))!
            let transform = hitTestResult.worldTransform
            let thirdColumn = transform.columns.3
            node.position = SCNVector3(thirdColumn.x, thirdColumn.y, thirdColumn.z)
            if selectedItem == "table" {
                self.centerPivot(for: node)
            }
            self.sceneView.scene.rootNode.addChildNode(node)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "item", for: indexPath) as! itemCell
        cell.itemLabel.text = self.itemsArray[indexPath.row]
        return cell
    }

    // from UICollectionViewDelegate (whenever select a certain cell)
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        // selected items base on name of values in array
        self.selectedItem = itemsArray[indexPath.row]
        cell?.backgroundColor = UIColor.green
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.backgroundColor = UIColor.orange
    }
    
    // get info node added for plane detection label
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARPlaneAnchor else { return }

        DispatchQueue.main.async {
            // reveal the Plane Detected label
            self.planeDetected.isHidden = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                // hide the label after 3 secs
                self.planeDetected.isHidden = true
            }
        }
        
    }
    
    // center pivot point exactly where your node is!
    func centerPivot(for node: SCNNode) {
        let min = node.boundingBox.min
        let max = node.boundingBox.max
        node.pivot = SCNMatrix4MakeTranslation(
            min.x + (max.x - min.x)/2,
            min.y + (max.y - min.y)/2,
            min.z + (max.z - min.z)/2
        )
    }
}

extension Int {
    var degreesToRadians: Double { return Double(self) * .pi/180}
}
