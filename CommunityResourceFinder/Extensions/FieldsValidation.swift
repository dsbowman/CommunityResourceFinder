//
//  FieldsValidation.swift
//  CommunityResourceFinder
//
//  Created by Deke Bowman on 12/30/24.
//
//
//import Foundation
//
//extension Record {
//    func validateResource() -> [ValidationError] {
//        return fields.validate()
//    }
//}
//
//extension CommunityResourceModel {
//    func validateAllResources() -> [String: [ValidationError]] {
//        var validationResults: [String: [ValidationError]] = [:]
//        
//        for record in records {
//            let errors = record.validateResource()
//            if !errors.isEmpty {
//                validationResults[record.id] = errors
//            }
//        }
//        
//        return validationResults
//    }
//}
