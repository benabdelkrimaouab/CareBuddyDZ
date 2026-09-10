//
//  AppModel.swift
//  CareBuddyDZ
//
//  Created by MAC on 31/5/2026.
//

import Foundation
import SwiftUI
import CoreLocation
import Combine

class AppModel: ObservableObject {

    @Published var userRole: UserRole = .patient

    @Published var userLocation: CLLocationCoordinate2D? = nil

    @Published var selectedDoctor: Doctor? = nil

    @Published var currentAppointment: Appointment? = nil

    @Published var isLoading: Bool = false

    @Published var errorMessage: String? = nil
}
