//
//  FeedbackViewModel.swift
//  CommunityResourceFinder
//
//  Created by Deke Bowman on 8/9/24.
//

import Foundation


class IssueReportViewModel: ObservableObject {
    
    @Published var subject = ""
    @Published var email = ""
    @Published var name = ""
    @Published var description = ""
    
}
