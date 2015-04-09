//
//  MIDIManager.swift
//  MIDISpew
//
//  Created by Gene De Lisa on 12/29/14.
//  Copyright (c) 2014 Gene De Lisa. All rights reserved.
//

import Foundation

import CoreMIDI
import AudioToolbox
import UIKit

private let MIDIManagerInstance = MIDIManager()

public class MIDIManager : NSObject {
    
    public class var sharedInstance:MIDIManager {
        return MIDIManagerInstance
    }
    
    public var midiClient:MIDIClientRef?
    public var outputPort:MIDIPortRef?
    public var inputPort: MIDIPortRef?
    
    /**
    This will initialize the midiClient, outputPort, and inputPort variables.
    */
    override init()    {
        super.init()
        var status = OSStatus(noErr)
        var s:CFString = "MyClient"
        
        println("creating client")
        var client = MIDIClientRef()
        
        // kee-rash
        status = MIDIClientCreate(s,
            self.midiNotifyProc,
            nil,
            &client)

        // This will run, but with no notify proc of course
//        status = MIDIClientCreate(s,
//            nil,
//            nil,
//            &client)

        
        midiClient = client
        
        if status == OSStatus(noErr) {
            println("created client")
        } else {
            println("error creating client : \(status)")
            showError(status)
        }
        
        if status == OSStatus(noErr) {
            
            println("creating input port ")
            var portString:CFString = "MyClient In"
            var ip: MIDIPortRef = MIDIPortRef()
            status = MIDIInputPortCreate(midiClient!,
                portString,
                midiReadFP,
                nil,
                &ip)
            inputPort = ip
            if status == OSStatus(noErr) {
                println("created input port")
            } else {
                println("error creating input port : \(status)")
                showError(status)
            }
            
            println("creating output port")
            var oportString:CFString = "MyClient Output port"
            var op: MIDIPortRef = MIDIPortRef()
            status = MIDIOutputPortCreate(midiClient!,
                oportString,
                &op)
            outputPort = op
            if status == OSStatus(noErr) {
                println("created output port \(op)")
            } else {
                println("error creating output port : \(status)")
                showError(status)
            }
        }
    }
    
    
    public class func isMIDIAvailable() -> Bool {
        switch UIDevice.currentDevice().systemVersion.compare("4.2", options: NSStringCompareOptions.NumericSearch) {
        case .OrderedSame, .OrderedDescending:
            println("midi capable")
            return true
        case .OrderedAscending:
            println("not midi capable")
            return false
        }
    }
    
    public func enableNetwork() {
        var session = MIDINetworkSession.defaultSession()
        session.enabled = true
        session.connectionPolicy = MIDINetworkConnectionPolicy_Anyone
        println("net session enabled \(MIDINetworkSession.defaultSession().enabled)")
    }
    
    public func connect() {
        var status = OSStatus(noErr)
        var sourceCount = MIDIGetNumberOfSources()
        println("source count \(sourceCount)")
        listSources()
        
        for srcIndex in 0 ..< sourceCount {
            let mep = MIDIGetSource(srcIndex)
            
            let midiEndPoint = MIDIGetSource(srcIndex)
            status = MIDIPortConnectSource(inputPort!,
                midiEndPoint,
                nil)
            if status == OSStatus(noErr) {
                println("yay connected endpoint to inputPort!")
            } else {
                println("oh crap!")
            }
        }
    }
    
    func showError(status:OSStatus) {
        
        switch status {
            
        case OSStatus(kMIDIInvalidClient):
            println("invalid client")
            break
        case OSStatus(kMIDIInvalidPort):
            println("invalid port")
            break
        case OSStatus(kMIDIWrongEndpointType):
            println("invalid endpoint type")
            break
        case OSStatus(kMIDINoConnection):
            println("no connection")
            break
        case OSStatus(kMIDIUnknownEndpoint):
            println("unknown endpoint")
            break
            
        case OSStatus(kMIDIUnknownProperty):
            println("unknown property")
            break
        case OSStatus(kMIDIWrongPropertyType):
            println("wrong property type")
            break
        case OSStatus(kMIDINoCurrentSetup):
            println("no current setup")
            break
        case OSStatus(kMIDIMessageSendErr):
            println("message send")
            break
        case OSStatus(kMIDIServerStartErr):
            println("server start")
            break
        case OSStatus(kMIDISetupFormatErr):
            println("setup format")
            break
        case OSStatus(kMIDIWrongThread):
            println("wrong thread")
            break
        case OSStatus(kMIDIObjectNotFound):
            println("object not found")
            break
            
        case OSStatus(kMIDIIDNotUnique):
            println("not unique")
            break
            
        case OSStatus(kMIDINotPermitted):
            println("not permitted")
            break
            
        default:
            println("dunno \(status)")
        }
    }
    

    func listSources() {
        let numSrcs = MIDIGetNumberOfSources()
        println("number of MIDI sources: \(numSrcs)")
        for srcIndex in 0 ..< numSrcs {
            #if arch(arm64) || arch(x86_64)
                let midiEndPoint = MIDIGetSource(srcIndex)
                #else
                let midiEndPoint = unsafeBitCast(MIDIGetSource(srcIndex), MIDIObjectRef.self)
            #endif
            var property : Unmanaged<CFString>?
            let err = MIDIObjectGetStringProperty(midiEndPoint, kMIDIPropertyDisplayName, &property)
            if err == noErr {
                let displayName = property!.takeRetainedValue() as String
                println("\(srcIndex): \(displayName)")
            } else {
                println("\(srcIndex): error \(err)")
            }
        }
    }
    
    public func getSources() -> [String:MIDIEndpointRef] {
        var dict = [String:MIDIEndpointRef]()
        let numSrcs = MIDIGetNumberOfSources()
        println("number of MIDI sources: \(numSrcs)")
        for srcIndex in 0 ..< numSrcs {
            let midiEndPoint = MIDIGetSource(srcIndex)
            var property : Unmanaged<CFString>?
            let end = unsafeBitCast(midiEndPoint, MIDIObjectRef.self)
            let err = MIDIObjectGetStringProperty(end, kMIDIPropertyDisplayName, &property)
            if err == noErr {
                let displayName = property!.takeRetainedValue() as String
                println("\(srcIndex): \(displayName)")
                dict[displayName] = midiEndPoint
            } else {
                println("\(srcIndex): error \(err)")
            }
        }
        
        println("returning source dictionary \(dict)")
        return dict
    }
    
    public func getDestinations() -> [String:MIDIEndpointRef] {
        var dict = [String:MIDIEndpointRef]()
        let num = MIDIGetNumberOfDestinations()
        println("number of MIDI destinations: \(num)")
        for index in 0 ..< num {
            let midiEndPoint = MIDIGetDestination(index)
            var property : Unmanaged<CFString>?
            let end = unsafeBitCast(midiEndPoint, MIDIObjectRef.self)
            let err = MIDIObjectGetStringProperty(end, kMIDIPropertyDisplayName, &property)
            if err == noErr {
                let displayName = property!.takeRetainedValue() as String
                println("\(index): \(displayName)")
                dict[displayName] = midiEndPoint
            } else {
                println("\(index): error \(err)")
            }
        }
        println("returning destination dictionary \(dict)")
        return dict
    }

    public func getDisplayName(object:MIDIObjectRef) -> String {
        var name : Unmanaged<CFString>?
        var status = MIDIObjectGetStringProperty(object, kMIDIPropertyDisplayName, &name)
        if status == OSStatus(noErr) {
            let displayName = name!.takeRetainedValue() as String
            return displayName
        } else {
            showError(status)
            return "error \(status)"
        }
    }
    
   
    func sendPacketList(status:Int, note: Int, value:Int) {
        var packetList = UnsafeMutablePointer<MIDIPacketList>.alloc(1)
        let midiDataToSend:[UInt8] = [UInt8(status), UInt8(note), UInt8(value)]
        var packet = UnsafeMutablePointer<MIDIPacket>.alloc(1)
        packet = MIDIPacketListInit(packetList)
        packet = MIDIPacketListAdd(packetList, 1024, packet, MIDITimeStamp(0), midiDataToSend.count, midiDataToSend)
        
        var destCount = MIDIGetNumberOfDestinations()
        for i in 0 ..< destCount {
            var endpoint = MIDIGetDestination(i)
            var status = MIDISend(outputPort!, endpoint, packetList)
        }
        packet.destroy()
        packetList.destroy()
    }

    public func noteOn(channel: Int, note: Int, velocity:Int) {
        sendPacketList((0x90+channel), note: note, value: velocity)
    }
    
    public func noteOff(channel: Int, note: Int) {
        sendPacketList((0x90+channel), note: note, value: 0 )
    }
    
    public func polyAfter(channel: Int, note: Int, value:Int) {
        sendPacketList((0xA0+channel), note: note, value: value)
    }
    
    /// FIXME: function pointers still messed up
    var midiNotifyProc:MIDINotifyProc {
        get {
            let ump = UnsafeMutablePointer<((UnsafePointer<MIDINotification>, UnsafeMutablePointer<Void>) -> Void)>.alloc(1)
//            ump.initialize(MyMIDINotifyProc)
            ump.initialize(globalMIDINotifyProc)
            let cp = COpaquePointer(ump)
            let fp = CFunctionPointer<((UnsafePointer<MIDINotification>, UnsafeMutablePointer<Void>) -> Void)>(cp)
            return fp
        }
    }
    
    
    public func MyMIDINotifyProc (np:UnsafePointer<MIDINotification>, refCon:UnsafeMutablePointer<Void>) {
        println("midi notify proc")
    }
    

    var midiReadFP:MIDIReadProc {
        get {
            let ump = UnsafeMutablePointer<((UnsafePointer<MIDIPacketList>, UnsafeMutablePointer<Void>, UnsafeMutablePointer<Void>) -> Void)>.alloc(1)
            //            ump.initialize(MyMIDIReadProc)
            ump.initialize(globalMIDIReadProc)
            let cp = COpaquePointer(ump)
            let fp = CFunctionPointer<((UnsafePointer<MIDIPacketList>, UnsafeMutablePointer<Void>, UnsafeMutablePointer<Void>) -> Void)>(cp)
            return fp
        }
    }
    
    func MyMIDIReadProc(packetList: UnsafePointer<MIDIPacketList>, readProcRefCon: UnsafeMutablePointer<Void>, srcConnRefCon: UnsafeMutablePointer<Void>) -> Void {
        println("read proc")
    }
    
}

public func globalMIDINotifyProc (np:UnsafePointer<MIDINotification>, refCon:UnsafeMutablePointer<Void>) {
    println("global midi notify proc")
}

public func globalMIDIReadProc(packetList: UnsafePointer<MIDIPacketList>, readProcRefCon: UnsafeMutablePointer<Void>, srcConnRefCon: UnsafeMutablePointer<Void>) -> Void {
    println("read proc")
}
