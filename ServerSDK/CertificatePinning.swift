// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  Certificates.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 12/05/2020 - for the TousAntiCovid project.
//


import Foundation

public final class CertificatePinning {

    public static func validateChallenge(_ challenge: URLAuthenticationChallenge, certificateFiles: [Data], completion: @escaping (_ validated: Bool, _ credential: URLCredential?) -> ()) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust else {
            completion(false, nil)
            return
        }
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            completion(false, nil)
            return
        }

        let base64CertificatesToCheck: [String] = certificateFiles.compactMap { fileBase64Content($0) }
        let base64CertificatesReceived: [String] = (0..<SecTrustGetCertificateCount(serverTrust)).compactMap {
            guard let certificate = SecTrustGetCertificateAtIndex(serverTrust, $0) else { return nil }
            let certificateData: CFData = SecCertificateCopyData(certificate)
            let data: UnsafePointer<UInt8> = CFDataGetBytePtr(certificateData)
            let size: CFIndex = CFDataGetLength(certificateData)
            let certBase64: String = Data(bytes: data, count: size).base64EncodedString()
            return certBase64
        }

        let certificateIsValid: Bool = base64CertificatesToCheck.allSatisfy { base64CertificatesReceived.contains($0) }
        
        completion(certificateIsValid, URLCredential(trust: serverTrust))
    }
    
    private static func fileBase64Content(_ certificateFile: Data) -> String? {
        return String(data: certificateFile, encoding: .utf8)?.svCleaningPEMStrings()
    }

}
