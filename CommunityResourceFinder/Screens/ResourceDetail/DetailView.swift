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
                span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
            )
        )
    
    
    var body: some View {
        
        VStack {
            Spacer().frame(height: 5)
            VStack {
                if let imageUrl = apiData.logo?.first?.url, let _ = URL(string: imageUrl) {
                    VStack {
                        Spacer().frame(height: 10)
                        ResourceRemoteImage(urlString: imageUrl)
                            .aspectRatio(contentMode: .fit)
                            .padding(.horizontal, 15)
                            .frame(width: 350, height: 150)
                            .background(.white)
                            .cornerRadius(20)
                        
                        HStack {
                            Text(apiData.label)
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.leading)
                                .fontWeight(.semibold)
                            Spacer()
//                                Image(systemName: "heart")
                        }
                        .padding(.horizontal, 20)
                        
                    }
                    
                    
                } else {
                    VStack {
                        Text(apiData.label)
                            .font(.title)
                            .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                            .foregroundStyle(Color.primary)
                            .multilineTextAlignment(.center)
                            .padding(15)
                    }
                    
                }
            }
            
            
            HStack {
                if let emergencyAssistanceNumber = apiData.emergencyAssistanceNumber {
                    ContactButton(label: "Emergency", image: "asterisk", imageColor: Color.red, action: "tel:\(emergencyAssistanceNumber)", state: false)
                }
                
                if let phoneContact = apiData.phoneContact {
                    ContactButton(label: "Call", image: "phone.fill", imageColor: Color.blue, action: "tel:\(phoneContact)", state: false)
                }
                
                if let street1 = apiData.street1, let city = apiData.city, let state = apiData.state, let zip = apiData.zip {
                    ContactButton(label: "Directions", image: "map.fill", imageColor: Color.blue, action:"http://maps.apple.com/?address=\(street1),\(city),\(state),\(zip)", state: false)
                }
            }
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
                print("Yahtzee")
                
                
            }, label: {
                Text("Report an issue")
                    .foregroundStyle(.blue)
                   

                
            })
            
            .sheet(isPresented: $viewModel.isShowingIssueForm) {
                IssueReport(issue: $viewModel.isShowingIssueForm)
                    .presentationDragIndicator(.visible)
            }

        }
        .listStyle(.plain)
    }
    
}



struct DetailHeaderView: View {
    
    var apiData: Fields
    
    var body: some View {
        largeTile(label: apiData.label, imageUrl: apiData.logo?.first?.url ?? "")
        HStack {
            if let emergencyAssistanceNumber = apiData.emergencyAssistanceNumber {
                ContactButton(label: "Emergency", image: "asterisk", imageColor: Color.red, action: "tel:\(emergencyAssistanceNumber)", state: false)
            }
            
            if let phoneContact = apiData.phoneContact {
                ContactButton(label: "Call", image: "phone.fill", imageColor: Color.blue, action: "tel:\(phoneContact)", state: false)
            }
            
            if let street1 = apiData.street1, let city = apiData.city, let state = apiData.state {
                ContactButton(label: "Directions", image: "map.fill", imageColor: Color.blue, action:"http://maps.apple.com/?address=\(street1),\(apiData.street2 ?? ""),\(city),\(state),\(apiData.zip ?? "")", state: false)
            }
        }
    }
}


#Preview {
    DetailView(apiData: MockData.sampleResource)
}

