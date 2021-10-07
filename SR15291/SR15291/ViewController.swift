//
//  ViewController.swift
//  SR555
//
//  Created by Dr. Michael Lauer on 07.10.21.
//

import UIKit

class ViewController: UIViewController {

    static let MyNotification: Notification.Name = .init("MyNotification")

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(onNotification), name: Self.MyNotification, object: nil)

        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
            NotificationCenter.default.post(name: Self.MyNotification, object: self)
        }
    }


}


extension ViewController {

    @objc func onNotification() async {
        print("I did receive the notification!")
    }

}
