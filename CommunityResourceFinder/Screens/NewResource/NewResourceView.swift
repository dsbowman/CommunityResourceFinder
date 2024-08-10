//
//  NewResourceView.swift
//  CommunityResourceFinder
//
//  Created by Deke Bowman on 8/9/24.
//

import SwiftUI

struct NewResourceView: View {
    @StateObject var viewModel = NewResourceViewModel()
    @Binding var newResource: Bool
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("About")) {
                    TextField("Label", text: $viewModel.newResource.label)
                    TextField("Description", text: $viewModel.newResource.descriptionNotes)
                    TextField("Hours of Operation", text: $viewModel.newResource.hoursOfOperation)
                    
                }
                
                Section(header: Text("Contact")) {
                    TextField("Emergency Assistance Contact", text: $viewModel.newResource.emergencyAssistanceNumber)
                    TextField("Phone 1", text: $viewModel.newResource.phoneContact)
                    TextField("Phone 2", text: $viewModel.newResource.phoneContact2)
                    TextField("Email", text: $viewModel.newResource.email)
                    TextField("Website", text: $viewModel.newResource.url)
                }
                
                Section(header: Text("Street Address")) {
                    TextField("Street", text: $viewModel.newResource.street1)
                    TextField("Street", text: $viewModel.newResource.street2)
                    TextField("City", text: $viewModel.newResource.city)
                    HStack {
                        TextField("State", text: $viewModel.newResource.state)
                        Divider()
                        TextField("Zip", text: $viewModel.newResource.zip)
                    }
                    
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("New Resource")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button(action: {
                        newResource = false
                    }, label: {
                        Text("Save")
                    })
                }
                ToolbarItemGroup(placement: .topBarLeading) {
                    Button(action: {
                        newResource = false
                    }, label: {
                        Text("Cancel")
                    })
                }
                
            }
        }
    }
}

#Preview {
    NewResourceView(newResource: .constant(true))
}
