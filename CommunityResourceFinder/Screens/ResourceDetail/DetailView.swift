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
    var apiData: Fields
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
        GeometryReader { geometry in
            VStack {
                // Collapsible Header
                DetailViewHeader(headerData: apiData)
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

                // Main List content
                List {
                    if let description = apiData.descriptionNotes {
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
                    if let hoursOfOperation = apiData.hoursOfOperation {
                        Section {
                            VStack(alignment: .leading) {
                                Text("Hours of Operation")
                                    .padding(.bottom, 5)
                                    .font(.caption)
                                Text(hoursOfOperation)
                                    .textSelection(.enabled)
                            }
                        }
                    }

                    Section {
                        if let emergencyAssistanceNumber = apiData.emergencyAssistanceNumber {
                            ContactControl.emergerncy(data: emergencyAssistanceNumber)
                        }
                        if let phoneContact = apiData.phoneContact {
                            ContactControl.phone(data: phoneContact)
                        }
                        if let phoneContact2 = apiData.phoneContact2 {
                            ContactControl.phone(data: phoneContact2)
                        }
                        if let email = apiData.email {
                            ContactControl.email(data: email)
                        }
                        if let url = apiData.url {
                            ContactControl.website(url: url)
                        }
                        MapDetailControl(resourceData: apiData)
                    }

                    Button(action: {
                        viewModel.isShowingIssueForm = true
                    }, label: {
                        Text("Report an issue")
                            .foregroundStyle(.blue)
                    })
                    .sheet(isPresented: $viewModel.isShowingIssueForm) {
                        WebView(url: URL(string: "https://airtable.com/appG874fGad8U9K7y/pag8d4CoJAscwVHcY/form")!)
                            .ignoresSafeArea()
                            .presentationDragIndicator(.visible)
                    }
                }
                .listStyle(.inset)
            }
        }
        .ignoresSafeArea(edges: .top) // Ignore safe area to allow the header to collapse smoothly
    }
}

#Preview {
    DetailView(apiData: MockData.sampleResource)
}
