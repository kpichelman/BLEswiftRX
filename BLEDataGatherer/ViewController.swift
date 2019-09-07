//
//  ViewController.swift
//  BLEDataGatherer
//
//  Created by Pichelman on 8/19/19.
//  Copyright © 2019 Pichelman. All rights reserved.
//

import UIKit
import RxSwift
import CoreBluetooth

class ViewController: UIViewController {
    
    @IBOutlet weak var LeftButton: UIButton!
    @IBOutlet weak var RightButton: UIButton!
    @IBOutlet weak var MainTextView: UITextView!
    @IBOutlet weak var BLEDiscoveredDevicesTable: UITableViewCell!
    
    var centralManager: CBCentralManager!
    var blePeripheral: CBPeripheral!
    
    var AppBluetoothState = BluetoothState.UNKNOWN
    
    let bag = DisposeBag()
    var publishToMainTextView = PublishSubject<String>()
    
    enum BluetoothState {
        case IDLE
        case SCANNING
        case UNKNOWN
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewDidLoad")
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        MainTextView.text = ""
        
        _ = publishToMainTextView.subscribe(
                onNext:{
                    self.MainTextView.text.append("\n" + $0)
                }).disposed(by: bag)
        
        SetIdle()
    }

    @IBAction func LeftButtonClick(_ sender: Any) {
        switch AppBluetoothState {
        case .IDLE:
            SetScanning()
        case .SCANNING:
            publishToMainTextView.onNext("Stopping Scan")
            SetIdle()
        default:
            SetIdle()
        }
    }
    
    @IBAction func RightButtonClick(_ sender: Any) {

    }
    
    func SetIdle() {
        AppBluetoothState = .IDLE
        LeftButton.setTitle("Start Scanning", for: UIControl.State.normal)
        RightButton.setTitle("No Fuction Yet", for: UIControl.State.normal)
        publishToMainTextView.onNext("App Idle - Let's do something!")
        
        centralManager.stopScan()
    }
    
    func SetScanning() {
        AppBluetoothState = .SCANNING
        LeftButton.setTitle("Stop Scanning", for: UIControl.State.normal)
        RightButton.setTitle("No Fuction Yet", for: UIControl.State.normal)
        publishToMainTextView.onNext("App Scanning for BLE")
        
        centralManager.scanForPeripherals(withServices: nil)
    }
}

extension ViewController: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
            
        case .unknown:
            publishToMainTextView.onNext("central.state is unknown")
        case .resetting:
            publishToMainTextView.onNext("central.state is resetting")
        case .unsupported:
            publishToMainTextView.onNext("central.state is unsupported")
        case .unauthorized:
            publishToMainTextView.onNext("central.state is unauthorized")
        case .poweredOff:
            publishToMainTextView.onNext("central.state is powered off")
        case .poweredOn:
            publishToMainTextView.onNext("central.state is powered on")
        @unknown default:
            publishToMainTextView.onNext("central.state is unknown-default")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        publishToMainTextView.onNext("\nDISCOVERY RSSI: \(RSSI) Desc: " +  peripheral.description)
        let blePeripheral = peripheral
        
        if (blePeripheral.name != nil)
        {
            centralManager.stopScan()
            publishToMainTextView.onNext("Attempting to connect to: " + blePeripheral.name!)
            centralManager.connect(blePeripheral, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        publishToMainTextView.onNext("CONNECTION: " + blePeripheral.description)
        blePeripheral.discoverServices(nil)
    }
}

extension ViewController: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        publishToMainTextView.onNext("SERVICES FOUND: ")
        
        guard let services = peripheral.services else {
            publishToMainTextView.onNext("No service data to report")
            return;
        }
        
        publishToMainTextView.onNext("CHARACTERISTICS FOUND: ")
        for s in services {
            publishToMainTextView.onNext(s.description)
            
            guard let characteristics = s.characteristics else {
                publishToMainTextView.onNext("No characteristics data to report")
                return;
            }
            
            for c in characteristics {
                publishToMainTextView.onNext(c.description)
            }
        }
    }
}
