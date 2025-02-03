//
//  StyxApp.swift
//  Styx
//
//  Created by Steve Castellotti on 9/4/24.
//  portions based on work by Kevin Watters
//
// Copyright (c) 2024-2025 Steve Castellotti
// This file is part of styx-godot and is released under the MIT License.
// See LICENSE file in the project root for full license information.

import Darwin
import GodotVision
import RealityKit
import SwiftUI

// Note: visionOS will silently clamp to volume size if set above or below limits
// (min, max) for all dimensions is (0.24, 1.98)
let VOLUME_SIZE = simd_double3(1.62, 0.9, 1.35)

struct WindowGroupIds {
    static let MAIN = "main_window_gv"
    static let IMMERSIVE = "immersive_window_gv"
}

@main
struct StyxApp: App {
    @StateObject private var godotVision = GodotVisionCoordinator()
    @StateObject private var handTracking = HandTracking()
    
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    
    @State private var rootEntityMain: Entity = Entity()
    @State private var rootEntityImmersive: Entity = Entity()

    var body: some SwiftUI.Scene {

        WindowGroup(id: WindowGroupIds.MAIN) {
            ScenesBrowser(debugName: WindowGroupIds.MAIN,
                                 godotVision: godotVision,
                                 enableHandControls: enableHandControls,
                                 rootEntity: rootEntityMain)
                .onAppear(perform: generalSetup)
                .onAppear {
                    print("MAIN appear")
                    godotVision.setupRealityKitScene(rootEntityMain, volumeSize: VOLUME_SIZE)
                    rootEntityMain.position.y -= Float(VOLUME_SIZE.y / 2)  // Offset to match Godot floor
                }
        }
        .windowStyle(.volumetric)
        .defaultSize(width: VOLUME_SIZE.x, height: VOLUME_SIZE.y, depth: VOLUME_SIZE.z, in: .meters)

        ImmersiveSpace(id: WindowGroupIds.IMMERSIVE) {
            ScenesBrowser(debugName: WindowGroupIds.IMMERSIVE,
                                 godotVision: godotVision,
                                 enableHandControls: enableHandControls,
                                 rootEntity: rootEntityImmersive)
                .onAppear {
                    print("IMMERSIVE appear")
                    godotVision.setupRealityKitScene(rootEntityImmersive, volumeSize: VOLUME_SIZE)
                    rootEntityMain.position.y -= Float(VOLUME_SIZE.y / 2)  // Offset to match Godot floor
                }
                .onDisappear {
                    print("IMMERSIVE disappear, opening 'main' window")
                    openWindow(id: WindowGroupIds.MAIN)
                    disableHandControls()
                }
        }
    }
    
    @State private var didSetup = false
    private func generalSetup() {
        if didSetup {
            print("already did setup!")
            return
        }
        
        setenv("GODOT_PLATFORM", "visionOS", 1)
        
        godotVision.perFrameTick = { [weak handTracking] (deltaTime: TimeInterval) in
            if let handTracking {
                handTracking.update(deltaTime: deltaTime)
                sendJoypadInput(.init(handTracking.leftAxis.x, handTracking.leftAxis.z))
            }
        }
    }
    
    func disableHandControls() {
        handTracking.setEnabled(false)
        godotVision.extraOffset = .zero
    }
    
    func enableHandControls() async {
        handTracking.setEnabled(true)
        godotVision.extraOffset = .init(0, 1.38, -1.2)
        await openImmersiveSpace(id: WindowGroupIds.IMMERSIVE)
    }
    
}
