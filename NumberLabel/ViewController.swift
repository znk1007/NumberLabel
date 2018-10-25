//
//  ViewController.swift
//  NumberLabel
//
//  Created by HuangSam on 2018/10/19.
//  Copyright © 2018年 SunEee. All rights reserved.
//

import UIKit


class ViewController: UIViewController {

    lazy var scrollLabel: NumberLabel = {
        $0.targetView.backgroundColor = .red
        return $0
    }(NumberLabel.init(type: .scroll))

    lazy var txtView: UITextView = {
        $0.keyboardType = .numberPad
        $0.backgroundColor = .lightGray
        return $0
    }(UITextView.init())

    lazy var changeBtn: UIButton = {
        $0.setTitle("更改", for: .normal)
        $0.setTitleColor(.blue, for: .normal)
        $0.tag = 0
        $0.addTarget(self, action: #selector(btnAction(_:)), for: .touchUpInside)
        return $0
    }(UIButton.init(type: .custom))

    lazy var add1Btn: UIButton = {
        $0.setTitle("+1", for: .normal)
        $0.setTitleColor(.blue, for: .normal)
        $0.tag = 1
        $0.addTarget(self, action: #selector(btnAction(_:)), for: .touchUpInside)
        return $0
    }(UIButton.init(type: .custom))

    lazy var add5Btn: UIButton = {
        $0.setTitle("+5", for: .normal)
        $0.setTitleColor(.blue, for: .normal)
        $0.tag = 2
        $0.addTarget(self, action: #selector(btnAction(_:)), for: .touchUpInside)
        return $0
    }(UIButton.init(type: .custom))

    lazy var add100Btn: UIButton = {
        $0.setTitle("+100", for: .normal)
        $0.setTitleColor(.blue, for: .normal)
        $0.tag = 3
        $0.addTarget(self, action: #selector(btnAction(_:)), for: .touchUpInside)
        return $0
    }(UIButton.init(type: .custom))

    lazy var add500Btn: UIButton = {
        $0.setTitle("+500", for: .normal)
        $0.setTitleColor(.blue, for: .normal)
        $0.tag = 4
        $0.addTarget(self, action: #selector(btnAction(_:)), for: .touchUpInside)
        return $0
    }(UIButton.init(type: .custom))

    lazy var reduce1Btn: UIButton = {
        $0.setTitle("-1", for: .normal)
        $0.setTitleColor(.blue, for: .normal)
        $0.tag = 5
        $0.addTarget(self, action: #selector(btnAction(_:)), for: .touchUpInside)
        return $0
    }(UIButton.init(type: .custom))

    lazy var reduce5Btn: UIButton = {
        $0.setTitle("-5", for: .normal)
        $0.setTitleColor(.blue, for: .normal)
        $0.tag = 6
        $0.addTarget(self, action: #selector(btnAction(_:)), for: .touchUpInside)
        return $0
    }(UIButton.init(type: .custom))

    lazy var reduce100Btn: UIButton = {
        $0.setTitle("-100", for: .normal)
        $0.setTitleColor(.blue, for: .normal)
        $0.tag = 7
        $0.addTarget(self, action: #selector(btnAction(_:)), for: .touchUpInside)
        return $0
    }(UIButton.init(type: .custom))

    lazy var reduce500Btn: UIButton = {
        $0.setTitle("-500", for: .normal)
        $0.setTitleColor(.blue, for: .normal)
        $0.tag = 8
        $0.addTarget(self, action: #selector(btnAction(_:)), for: .touchUpInside)
        return $0
    }(UIButton.init(type: .custom))

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let label = NumberLabel.init(frame: CGRect.init(origin: CGPoint.init(x: 10, y: 50), size: CGSize.init(width: 80, height: 40)), displayNumber: 100)
        label.format = "%d"
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            label.changeDisplayNumber(to: 10000)
        }
        view.addSubview(label.targetView)

        let label1 = NumberLabel.init(frame: CGRect.init(origin: CGPoint.init(x: 100, y: 50), size: CGSize.init(width: 200, height: 40)), displayNumber: 1000000)
        let formatter = NumberFormatter.init()
        formatter.numberStyle = .decimal
        label1.formatClosure = { [weak self] (value) -> String in
            let formatted = formatter.string(from: NSNumber.init(value: value))
            return String.init(format: "Score: %@", (formatted ?? ""))
        }
        view.addSubview(label1.targetView)

        scrollLabel.targetView.frame = CGRect.init(origin: CGPoint.init(x: 10, y: 120), size: scrollLabel.targetView.frame.size)

        txtView.frame = CGRect.init(origin: CGPoint.init(x: scrollLabel.targetView.frame.minX, y: scrollLabel.targetView.frame.maxY + 10), size: CGSize.init(width: 200, height: 40))

        let btnSize = CGSize.init(width: 50, height: 40)
        changeBtn.frame = CGRect.init(origin: CGPoint.init(x: txtView.frame.maxX + 10, y: txtView.frame.minY), size: btnSize)

        add1Btn.frame = CGRect.init(origin: CGPoint.init(x: txtView.frame.minX, y: txtView.frame.maxY + 10), size: btnSize)
        add5Btn.frame = CGRect.init(origin: CGPoint.init(x: add1Btn.frame.minX, y: add1Btn.frame.maxY + 10), size: btnSize)
        add100Btn.frame = CGRect.init(origin: CGPoint.init(x: add1Btn.frame.minX, y: add5Btn.frame.maxY + 10), size: btnSize)
        add500Btn.frame = CGRect.init(origin: CGPoint.init(x: add1Btn.frame.minX, y: add100Btn.frame.maxY + 10), size: btnSize)

        reduce1Btn.frame = CGRect.init(origin: CGPoint.init(x: changeBtn.frame.minX, y: changeBtn.frame.maxY + 10), size: btnSize)
        reduce5Btn.frame = CGRect.init(origin: CGPoint.init(x: reduce1Btn.frame.minX, y: reduce1Btn.frame.maxY + 10), size: btnSize)
        reduce100Btn.frame = CGRect.init(origin: CGPoint.init(x: reduce1Btn.frame.minX, y: reduce5Btn.frame.maxY + 10), size: btnSize)
        reduce500Btn.frame = CGRect.init(origin: CGPoint.init(x: reduce1Btn.frame.minX, y: reduce100Btn.frame.maxY + 10), size: btnSize)

        view.addSubview(scrollLabel.targetView)
        view.addSubview(txtView)
        view.addSubview(changeBtn)
        view.addSubview(add1Btn)
        view.addSubview(add5Btn)
        view.addSubview(add100Btn)
        view.addSubview(add500Btn)
        view.addSubview(reduce1Btn)
        view.addSubview(reduce5Btn)
        view.addSubview(reduce100Btn)
        view.addSubview(reduce500Btn)
    }

    @objc func btnAction(_ btn: UIButton) {
        guard let tmp = scrollLabel.currentNumber as? Int else {
            return
        }
        switch btn.tag {
        case 0:
            if let num = Int(txtView.text) {
                scrollLabel.changeDisplayNumber(num)
            }
        case 1:
            scrollLabel.changeDisplayNumber(tmp + 1)
        case 2:
            scrollLabel.changeDisplayNumber(tmp + 5)
        case 3:
            scrollLabel.changeDisplayNumber(tmp + 100)
        case 4:
            scrollLabel.changeDisplayNumber(tmp + 500)
        case 5:
            scrollLabel.changeDisplayNumber(tmp - 1)
        case 6:
            scrollLabel.changeDisplayNumber(tmp - 5)
        case 7:
            scrollLabel.changeDisplayNumber(tmp - 100)
        case 8:
            scrollLabel.changeDisplayNumber(tmp - 500)
        default:
            break
        }

    }

}

