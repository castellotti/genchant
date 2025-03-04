//  Created by Kevin Watters on 12/27/23.

import GodotVision
import RealityKit
import SwiftGodot
import SwiftUI

typealias Environment = SwiftUI.Environment

/// The path to the folder containing the "project.godot" you wish Godot to load.
fileprivate let pathToGodotProject = "Godot_Project"

fileprivate let visualizationScenes: [(label: String, systemImageName: String, resourcePath: String)] = [
    ("Main",   "chart.bar.fill", "res://scenes/main.tscn"),
    ("Cone",   "cone.fill",      "res://scenes/cone/cone.tscn"),
    ("Cube",   "cube.fill",      "res://scenes/cube/cube.tscn"),
    ("Sphere", "circle.fill",    "res://scenes/sphere/sphere.tscn"),
    ("Torus",  "torus",          "res://scenes/torus/torus.tscn"),
]

struct ScenesBrowser: View {
    @Environment(\.dismiss) private var dismiss
    let debugName: String
    let godotVision: GodotVisionCoordinator
    let enableHandControls: () async -> Void
    let rootEntity: Entity
    @State private var selectedScene: String = visualizationScenes[0].resourcePath
    @State private var showSettings: Bool = false
    
    @State private var godotEntity: Entity = Entity()
    @State private var eventSubscription: EventSubscription? = nil
    
    @State private var tickCount = 0
    
    @Environment(\.scenePhase) private var environmentScenePhase
    @State private var localScenePhase: ScenePhase = .background
    
    private func perFrameTick(_ event: SceneEvents.Update) {
        if localScenePhase == .active {
            godotVision.realityKitPerFrameTick(event)
        }
    }

    var body: some View {
        GeometryReader3D { (geometry: GeometryProxy3D) in
            if environmentScenePhase == .active {
                RealityView { content, attachments in
                    print("$$$$$ RealityView init")
                    content.add(rootEntity)
                    eventSubscription = content.subscribe(to: SceneEvents.Update.self, perFrameTick)
                    if let uiPanel = attachments.entity(for: UI_PANEL_ATTACHMENT_NAME) {
                        content.add(uiPanel)
                        uiPanel.position = uiPanelPosition(volumeSize: VOLUME_SIZE)
                    }
                } update: { content, attachments in
                    // update called when SwiftUI @State in this ContentView changes. See docs for RealityView.
                    // user can change the volume size from the default by selecting a different zoom level.
                    // we watch for changes via the GeometryReader and scale the godot root accordingly
                    let frame = content.convert(geometry.frame(in: .local), from: .local, to: .scene)
                    let volumeSize = simd_double3(frame.max - frame.min)
                    godotVision.changeScaleIfVolumeSizeChanged(volumeSize)
                    if let uiPanel = attachments.entity(for: UI_PANEL_ATTACHMENT_NAME) {
                        // swiftui attachment also needs to be repositioned
                        uiPanel.position = uiPanelPosition(volumeSize: volumeSize)
                    }
                } attachments: {
                    Attachment(id: "ui_panel") {
                        HStack {
                            Button { godotVision.reloadScene() } label: {
                                Label("Reload", systemImage: "arrow.clockwise.circle")
                            }
                            Button {
                                Task {
                                    await enableHandControls()
                                    dismiss()
                                }
                            } label: {
                                Label("Hand Controls", systemImage: "hand.raised.fill")
                            }
                            Button { withAnimation { showSettings.toggle() } } label: {
                                Label(showSettings ? "Settings" : "", systemImage: "gear")
                            }.transition(.scale)
                            
                            if showSettings {
                                GodotVisionSettingsView(godotVision: godotVision)
                                    .transition(.slide)
                            }
                        }.padding().glassBackgroundEffect()
                    }
                }
            }
        }
        .modifier(GodotVisionRealityViewModifier(coordinator: godotVision))
        .onChange(of: environmentScenePhase, initial: true, {
            localScenePhase = environmentScenePhase
        })
        .onChange(of: selectedScene) { _, sceneResourcePath in
            godotVision.changeSceneToFile(atResourcePath: sceneResourcePath)
        }
        .onDisappear {
            eventSubscription?.cancel()
            eventSubscription = nil
        }
        .background {
            TabView(selection: $selectedScene) { // Show a tab bar on the left allowing the user to select example scenes.
                ForEach(visualizationScenes, id: \.resourcePath) { (label, systemImage, resourcePath) in
                    Tab(label, systemImage: systemImage, value: resourcePath) { /* empty tab content; we load the scene in .onChange(of: selectedScene) */ }
                }
            }
        }
    }
    
    private func uiPanelPosition(volumeSize: simd_double3) -> simd_float3 {
        .init(0, Float(volumeSize.y / 2 - 0.1), Float(volumeSize.z / 2 - 0.01)) // Top
    }
}

fileprivate let UI_PANEL_ATTACHMENT_NAME = "ui_panel"
