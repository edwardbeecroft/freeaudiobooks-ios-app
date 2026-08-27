//
//  CLLocation+Extensions.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 28/05/2019.
//  Copyright © 2020 Radically Better Ltd All rights reserved.
//

import Foundation
import CoreLocation

extension CLLocation {
	func geocode(completion: @escaping (_ placemark: [CLPlacemark]?, _ error: Error?) -> Void)  {
		CLGeocoder().reverseGeocodeLocation(self, completionHandler: completion)
	}
}
