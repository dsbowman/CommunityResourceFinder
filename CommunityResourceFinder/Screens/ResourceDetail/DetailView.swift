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
    
    var body: some View {
        VStack {
            DetailViewHeader(headerData: apiData)
            Spacer().frame(height: 10)
            ContactMenu(phone: apiData.phoneContact, emergency: apiData.emergencyAssistanceNumber, email: apiData.email, street1: apiData.street1, street2: apiData.street2, city: apiData.city, state: apiData.state, url: apiData.url)

        }
        .padding(.bottom, 15)
        
        List {
            
            if let description = apiData.descriptionNotes {
                Section {
                    VStack(alignment: .leading) {
                        Text("Description")
                            .font(.caption)
                            .padding(.bottom, 5)
                        Text(description)
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
                    ContactControl.phone(data: phoneContact) }
                if let phoneContact2 = apiData.phoneContact2 {
                    ContactControl.phone(data: phoneContact2) }
                if let email = apiData.email {
                    ContactControl.email(data: email) }
                if let url = apiData.url {
                    ContactControl.website(url: url) }
            }
            
            Section {
                
                if let street1 = apiData.street1, let city = apiData.city, let state = apiData.state {
                    Section {
                        HStack(alignment: .top) {
                            ZStack {
                                VStack(alignment: .leading, spacing: 0) {
                                    Map(position: $position) {
                                        if let coordinate = apiData.locationCoordinate {
                                            Annotation(apiData.label, coordinate: coordinate) {
                                                Circle()
                                                    .fill(.blue)
                                                    .frame(width: 10, height: 10)
                                            }
                                        }
                                    }
                                    .frame(height: 175)
                                    .onAppear {
                                        if let coordinate = apiData.locationCoordinate {
                                            position = MapCameraPosition.region(MKCoordinateRegion(
                                                center: coordinate,
                                                span: MKCoordinateSpan(latitudeDelta: 0.003125, longitudeDelta: 0.003125)
                                            ))
                                        }
                                    }
                                    
                                    VStack(alignment: .leading) {
                                        Text("Location")
                                            .font(.caption)
                                        Link(destination: URL(string: "http://maps.apple.com/?address=\(street1),\(city),\(state)")!, label: {
                                            HStack() {
                                                Text(street1)
                                                if let street2 = apiData.street2 {
                                                    Text(street2)}
                                                Text("\(city), \(state) \(apiData.zip ?? "")")
                                                Spacer()
                                            }
                                            .font(.subheadline)
                                            
                                        })
                                    }
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                                    .frame(height: 35)
                                    .padding(10)
                                    
                                }
                                .background(.gray)
                                .cornerRadius(20)
                                .textSelection(.enabled)
                                .shadow(radius: 10)
                                
                                
                            }
                            
                        }
 
                    }

                }
            }

            Button(action: {
                viewModel.isShowingIssueForm = true
            }, label: {
                Text("Report an issue")
                    .foregroundStyle(.blue)
            })
            
            .sheet(isPresented: $viewModel.isShowingIssueForm) {
//                IssueReport(issue: $viewModel.isShowingIssueForm)
                WebView(url: URL(string: "https://airtable.com/appG874fGad8U9K7y/pag8d4CoJAscwVHcY/form")!)
                    .ignoresSafeArea()
                    .presentationDragIndicator(.visible)
            }


        }
        .listStyle(.plain)
    }
    
}

#Preview {
    DetailView(apiData: MockData.sampleResource)
}


struct DetailViewHeader: View {
    
    var headerData: Fields
    
    var body: some View {
        VStack(alignment: .center) {
            if let imageUrl = headerData.logo?.first?.url, let _ = URL(string: imageUrl) {
                VStack() {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image.resizable()
                    } placeholder: {
                        ProgressView()
                            .controlSize(.large)
                    }
                    .aspectRatio(contentMode: .fit)
                    .padding(20)
                    .frame(width: 350, height: 150)
                    .background(.white)
                    .cornerRadius(20)
                    
                    HStack {
                        Text(headerData.label)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                            .fontWeight(.semibold)
                        //                            Spacer()
                        //                        Image(systemName: "heart")
                    }
                    .padding(5)
                    
                }
                .frame(width: 350)
            } else {
                VStack(alignment: .center) {
                    Text(headerData.label)
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.primary)
                        .multilineTextAlignment(.center)
                        .padding(20)
                    
                    
                }
            }
        }
    }
}
