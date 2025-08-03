//
//  EditJobView.swift
//  Aure
//
//  Created by Abdussalam Adesina on 7/9/25.
//

import SwiftUI

struct EditJobView: View {
    @Environment(\.dismiss) private var dismiss
    let job: Job
    
    var body: some View {
        SimpleJobCreationView(editJob: job)
    }
}