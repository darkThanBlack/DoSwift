//
//  NetworkSessionDelegate.swift
//  DoSwift
//
//  Created by moonShadow on 2026/11/02
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import Foundation

extension DO {

    /// The delegate handed to sessions that were created without one.
    ///
    /// A session built with `delegate: nil` still has to report its body somewhere, and the
    /// completion handler path is not always taken. Standing in as the delegate is the only
    /// way to see those responses. The methods here also serve as the source of the type
    /// encodings used when a real delegate does not implement them itself.
    @objc(DONetworkSessionDelegate)
    final class NetworkSessionDelegate: NSObject, URLSessionDataDelegate {

        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
            DO.NetworkTaskBox.box(for: dataTask)?.append(data)
        }

        func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
            guard let box = DO.NetworkTaskBox.box(for: task) else { return }
            DO.NetworkCapture.shared.commit(box, response: task.response, error: error)
        }
    }
}
