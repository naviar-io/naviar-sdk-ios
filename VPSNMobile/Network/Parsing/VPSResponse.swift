

import Foundation

func parseVPSResponse(from dict: NSDictionary) -> ResponseVPSPhoto? {

    guard let status = dict["status"] as? String else { return nil }
    let statusDescription = dict["status_description"] as? String ?? ""
    var resp = ResponseVPSPhoto(status: status == "done", statusDescription: statusDescription)
    
    let attributes = dict["attributes"] as? NSDictionary
    if let locationId = attributes?["location_id"] as? String {
        resp.locationId = locationId
    }
    if let vpsPose = attributes?["vps_pose"] as? NSDictionary {
        let pitch = parseDouble(vpsPose, key: "rx")
        let yaw = parseDouble(vpsPose, key: "ry")
        let roll = parseDouble(vpsPose, key: "rz")
        let x = parseDouble(vpsPose, key: "x")
        let y = parseDouble(vpsPose, key: "y")
        let z = parseDouble(vpsPose, key: "z")
        resp.vpsPose = ResponseVPSPhoto.VPSPose(posX: Float(x),
                                                posY: Float(y),
                                                posZ: Float(z),
                                                posRoll: Float(roll), //here
                                                posPitch: Float(pitch), //here
                                                posYaw: Float(yaw)) //here
    }
    if let vpsSendPose = attributes?["tracking_pose"] as? NSDictionary {
        let pitch = parseDouble(vpsSendPose, key: "rx")
        let yaw = parseDouble(vpsSendPose, key: "ry")
        let roll = parseDouble(vpsSendPose, key: "rz")
        let x = parseDouble(vpsSendPose, key: "x")
        let y = parseDouble(vpsSendPose, key: "y")
        let z = parseDouble(vpsSendPose, key: "z")
        resp.vpsSendPose = ResponseVPSPhoto.VPSPose(posX: Float(x),
                                                posY: Float(y),
                                                posZ: Float(z),
                                                posRoll: Float(roll), //here
                                                posPitch: Float(pitch), //here
                                                posYaw: Float(yaw)) //here
    }
    
    if let location = attributes?["location"] as? NSDictionary {
        if let gps = location["gps"] as? NSDictionary {
            let lat = parseDouble(gps, key: "latitude")
            let long = parseDouble(gps, key: "longitude")
            resp.gps = ResponseVPSPhoto.GPSResponse(lat: lat, long: long)
        } else {
            print("no gps")
        }
        if let compass = location["compass"] as? NSDictionary {
            let heading = parseDouble(compass, key: "heading")
            resp.compass = ResponseVPSPhoto.CompassResponse(heading: heading)
        }
    }
    return resp
}
