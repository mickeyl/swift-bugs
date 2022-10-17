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

        // this is what works
        __gmpz_clear(&e)

        //this is what I would have expected
        //mpz_clear(e)
    }

    override var representedObject: Any? {
        didSet {
        }
    }


}

