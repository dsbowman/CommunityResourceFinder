//
//  FeedbackView.swift
//  CommunityResourceFinder
//
//  Created by Deke Bowman on 8/9/24.
//

import SwiftUI

struct IssueReport: View {
    
    @StateObject private var viewModel = IssueReportViewModel()
    @Binding var issue: Bool
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Full Name:", text: $viewModel.name)
                TextField("Email:", text: $viewModel.email)
                TextField("Subject:", text: $viewModel.subject)
                TextField("Description:", text: $viewModel.description, axis: .vertical)
                    .multilineTextAlignment(.leading)
                    .frame(minHeight: 100, alignment: .topLeading)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Share Feedback")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button(action: {
                        issue = false
                    }, label: {
                        Text("Submit")
                    })
                }
            }
        }

    }
}

#Preview {
    IssueReport(issue: .constant(true))
}
