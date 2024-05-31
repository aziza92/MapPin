//
//  ContentView.swift
//  MapPin
//
//  Created by KARMANI Aziza on 30/05/2024.
//

import SwiftUI
import MapKit

struct ContentView: View {
    /// Properties
    @State private var camera: MapCameraPosition = .region(.init(center: .namur, span: .initialSpan))
    @State private var coordinate: CLLocationCoordinate2D = .namur
    @State private var mapSpan: MKCoordinateSpan = .initialSpan
    @State private var annotationTitle: String = ""
    ///
    @State private var updateCamera: Bool = false
    @State private var displayTitle: Bool = false
    
    var body: some View {
        /// ios 17 +
        MapReader { proxy in
            Map(position: $camera){
                /// Custom Annotation View
                Annotation(displayTitle ? annotationTitle : "", coordinate: coordinate) {
                    DraggablePin(proxy: proxy, coordinate: $coordinate){ coordinate in
                        findcoordinateName()
                        guard updateCamera else {return }
                        
                        let newRegion = MKCoordinateRegion(center: coordinate,
                                                           span: mapSpan
                        )
                        
                        withAnimation(.smooth){
                            camera = .region(newRegion)
                        }
                        
                    }
                }
            }
            .onMapCameraChange(frequency: .continuous) {  ctx in
                mapSpan = ctx.region.span
            }
            .safeAreaInset(edge: .bottom, content: {
                HStack(spacing: 0){
                    Toggle("Mises à jour", isOn: $updateCamera)
                        .frame(width: 180)
                    
                    Spacer(minLength: 0)
                    
                    Toggle("Afficher", isOn: $displayTitle)
                        .frame(width: 150)
                }
                .textScale(.secondary)
                .padding(12)
                .background(.ultraThinMaterial)
            })
            .onAppear(perform: findcoordinateName)
        }
    }
    
    /// NAme of current Location
    func findcoordinateName(){
        annotationTitle = ""
        Task{
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            let geoDecoder = CLGeocoder()
            if let name =  try? await
                geoDecoder.reverseGeocodeLocation(location).first?.name{
                annotationTitle = name
            }
        }
    }
    
    
}

#Preview {
    ContentView()
}
/// Custom Draggable Pin ::::
struct  DraggablePin: View {
    var tint: Color = .red
    var proxy: MapProxy
    
    @Binding var coordinate: CLLocationCoordinate2D
    var onCoordinateChange: (CLLocationCoordinate2D) -> ()
    @State var  isActive: Bool = false
    @State var translation : CGSize = .zero
    
    var body: some View {
        GeometryReader{
            let frame = $0.frame(in: .global)
            
            Image(systemName: "mappin")
                .font(.title)
                .foregroundStyle(tint.gradient)
                .animation(.snappy, body: { content in
                    content
                    /// Scaling on active
                        .scaleEffect(isActive ? 0.3 : 1, anchor: .bottom)
                    
                })
                .frame(width: frame.width, height: frame.height)
                .onChange(of: isActive, initial:  false){ _, newValue in
                    let position = CGPoint(x: frame.midX, y: frame.midY)
                    /// converting position into location coordinate
                    if let coordinate = proxy.convert(position, from: .global), !newValue {
                        /// Update coordinate based on Translation ::::
                        self.coordinate = coordinate
                        translation = .zero
                        onCoordinateChange(coordinate)
                    }
                }
                
             
        }
        .frame(width: 30, height: 30)
        .contentShape(.rect)
        .offset(translation)
        .gesture(
            LongPressGesture(minimumDuration: 0.15)
                .onEnded{
                    isActive = $0
                }
                .simultaneously(with:
                  DragGesture(minimumDistance: 0)
                    .onChanged{ value in
                        if isActive { translation = value.translation}
                    }
                    .onEnded{ value in
                        if isActive { isActive = false}
                    }
             )
        )
    }
}


/// Sattic Value
extension MKCoordinateSpan {
    static var initialSpan : MKCoordinateSpan {
        return .init(latitudeDelta: 0.5, longitudeDelta: 0.5)
    }
}
extension CLLocationCoordinate2D {
    static var namur: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: 50.4669000, longitude: 4.8674600)
    }
}


