//
//  Alert.swift
//  CommunityResourceFinder
//
//  Created by Deke Bowman on 8/9/24.
//

import SwiftUI

struct AlertItem: Identifiable {
    let id = UUID()
    let title: Text
    let message: Text
    let dismissButton: Alert.Button
}

struct AlertContext {
    
    //Mark: Network Alerts
    static let invalidData = AlertItem(title: Text("Server Error"),
                                   message: Text("The data received from teh server was invalid. Please contact support."),
                                   dismissButton: .default(Text("Ok")))
    
    static let invalidResponse = AlertItem(title: Text("Server Error"),
                                      message: Text("Invalid response from the server. Please try again later or contact support."),
                                      dismissButton: .default(Text("Ok")))
    
    static let invalidURL = AlertItem(title: Text("Server Error"),
                                  message: Text("There was an issue connecting to the server. If this persists, please contact support."),
                                  dismissButton: .default(Text("Ok")))
    
    static let unableToComplete = AlertItem(title: Text("Server Error"),
                                       message: Text("Unable to complete your request at this time. Please chck your internet connection. "),
                                       dismissButton: .default(Text("Ok")))
    
    //Mark: Account Alerts
    static let invalidEmail = AlertItem(title: Text("Invalid Email"),
                                    message: Text("Please verify your email is a valid email address."),
                                    dismissButton: .default(Text("Ok")))
    
    static let invalidForm = AlertItem(title: Text("Invalid Form"),
                                           message: Text("One or more required fields are blank, please ensure all required fields have been completed"),
                                           dismissButton: .default(Text("Ok")))
    
    static let userSaveSuccess = AlertItem(title: Text("Profile Saved"),
                                           message: Text("Your profile information was successfully saved"),
                                           dismissButton: .default(Text("Ok")))
    
    static let invalidUserData = AlertItem(title: Text("Profile Error"),
                                           message: Text("There was an error saving or retrieving your profile."),
                                           dismissButton: .default(Text("Ok")))
}
