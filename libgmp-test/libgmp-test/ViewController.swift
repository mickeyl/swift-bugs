//
//  ViewController.swift
//  libgmp-test
//
//  Created by Dr. Michael Lauer on 17.10.22.
//

import Cocoa

import libgmp

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        var e: mpz_t = .init()
        __gmpz_clear(&e)

        //mpz_c.clear(e)

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

