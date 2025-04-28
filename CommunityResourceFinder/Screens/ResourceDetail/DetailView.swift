//
//  DetailView.swift
//  CommunityResourceFinder
//
//  Created by Deke Bowman on 8/9/24.
//

import SwiftUI
import MapKit
import WebKit

struct DetailView: View {
    var resource: Resource
    @StateObject private var viewModel = DetailViewModel()
    @State private var position = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 39.9526, longitude: -75.1652),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    )
    
    @State var showWebView = false
    @State private var headerHeight: CGFloat = 250 // Initial height of the header
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack {
                    // Collapsible Header
                    DetailViewHeader(resource: resource)
                        .frame(height: headerHeight)
                        .offset(y: geometry.frame(in: .global).minY < 0
                                ? -geometry.frame(in: .global).minY
                                : 0)
                        .onChange(of: geometry.frame(in: .global).minY) { newValue, _ in
                            if newValue < 0 {
                                let newHeight = max(100, 250 + newValue) // Min height limit
                                headerHeight = newHeight
                            } else {
                                headerHeight = 250 // Default height
                            }
                        }
                        .padding(.top, 10)
                    
                    // Main List content
                    List {
                        if let description = resource.description, !description.isEmpty {
                            Section {
                                VStack(alignment: .leading) {
                                    Text("Description")
                                        .font(.caption)
                                        .padding(.bottom, 5)
                                    Text(description)
                                        .multilineTextAlignment(.leading)
                                        .textSelection(.enabled)
                                }
                            }
                        }
                        //                    if let location = resource.primaryLocation, let hours = location.hoursOfOperation?.first {
                        //                        Section {
                        //                            VStack(alignment: .leading) {
                        //                                Text("Hours of Operation")
                        //                                    .padding(.bottom, 5)
                        //                                    .font(.caption)
                        //
                        //                                ForEach(hours.days) { day in
                        //                                    HStack {
                        //                                        Text(day.day.rawValue.capitalized)
                        //                                            .frame(width: 100, alignment: .leading)
                        //
                        //                                        if let open = day.open, let close = day.close {
                        //                                            Text("\(open) - \(close)")
                        //                                        } else {
                        //                                            Text("Closed")
                        //                                        }
                        //                                    }
                        //                                }
                        //                                .textSelection(.enabled)
                        //                            }
                        //                        }
                        //                    }
                        
                        Section {
                            if let emergencyPhone = resource.emergencyPhone, !emergencyPhone.isEmpty {
                                ContactControl.emergency(data: emergencyPhone)
                            }
                            if let mainPhone = resource.mainPhone, !mainPhone.isEmpty {
                                ContactControl.phone(data: mainPhone)
                            }
                            if let contact = resource.contacts?.first(where: {$0.role == "secondary"}) {
                                if let phone = contact.phone, !phone.isEmpty {
                                    ContactControl.phone(data: phone)
                                }
                            }
                            if let email = resource.generalEmail, !email.isEmpty {
                                ContactControl.email(data: email)
                            }
                            if let url = resource.url, !url.isEmpty {
                                ContactControl.website(url: url)
                            }
                            if let location = resource.primaryLocation,
                               let coordinate = location.coordinate {
                                MapDetailControl(
                                    latitude: coordinate.latitude,
                                    longitude: coordinate.longitude,
                                    label: resource.label,
                                    street1: location.street1,
                                    street2: location.street2,
                                    city: location.city,
                                    state: location.state,
                                    zip: location.zip
                                )
                            }
                            //                        if let location = resource.primaryLocation,
                            //                            let coordinate = location.coordinate {
                            //                            Button {
                            //                                viewModel.upadateLocation(resourceID: resource.id!, lat: coordinate.latitude, lon: coordinate.longitude)
                            //                            } label: {
                            //                                Text("Update Location")
                            //                            }
                            //
                            //                            }
                        }
                        
                        
                        
                        
                        
                        
                        Button(action: {
                            viewModel.isShowingIssueForm = true
                        }, label: {
                            Text("Report an issue")
                                .foregroundStyle(.blue)
                        })
                        //                    .sheet(isPresented: $viewModel.isShowingIssueForm) {
                        //                        WebView(url: URL(string: "https://airtable.com/appG874fGad8U9K7y/pag8d4CoJAscwVHcY/form")!)
                        //                            .ignoresSafeArea()
                        //                            .presentationDragIndicator(.visible)
                        //                    }
                    }
                    .listStyle(.inset)
                    
                }
                .toolbar {
                    ToolbarItem {
                        ShareLink(
                            item: viewModel.createVCard(resource: resource),
                            subject: Text("Contact information for \(resource.label)"),
                            message: Text("Here's a resource that might be helpful"),
                            preview: SharePreview(
                                resource.label,
                                image: FirebaseImage(path: resource.imagePath)
                            )
                        ) {
                            Label("Share", systemImage: "square.and.arrow.up")
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        
                    }
                }
            }
            .ignoresSafeArea(edges: .top) // Ignore safe area to allow the header to collapse smoothly
        }
    }
    
    
}

//#Preview {
//    DetailView(resource: <#Resource#>)
//}
