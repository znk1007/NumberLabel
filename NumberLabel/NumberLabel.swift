//
//  NumberLabel.swift
//  NumberLabel
//
//  Created by HuangSam on 2018/10/19.
//  Copyright © 2018年 SunEee. All rights reserved.
//

import UIKit

/// 动画效果
///
/// - flash: 闪动
/// - scroll: 滚动
enum AnimationType {
    case flash
    case scroll
}

class NumberLabel {
    /// 格式化
    var format: String? {
        didSet {
            if let flash = flashLabel {
                flash.format = format
            }
        }
    }
    /// 当前数字
    var currentNumber: Any
    /// 文本颜色
    var textColor: UIColor = .gray {
        didSet {
            if let flash = flashLabel {
                flash.textColor = textColor
            } else if let scroll = scrollLabel {
                scroll.textColor = textColor
            }
        }
    }

    /// 格式化闭包
    var formatClosure: ((Float) -> (String))?
    /// 富文本格式化闭包
    var attributedFormatClosure: ((Float) -> (NSAttributedString))?
    /// 完成回调
    var finishedClosure: (() -> ())?

    /// 动画类型
    private var animType: AnimationType = .flash
    /// 闪动标签
    private var flashLabel: FlashNumberLabel?
    /// 滚动标签
    private var scrollLabel: ScrollNumberLabel?

    /// 目标视图
    var targetView: UIView {
        if let flash = flashLabel {
            return flash
        } else if let scroll = scrollLabel {
            return scroll
        } else {
            return .init()
        }
    }


    init(type: AnimationType = .flash, frame: CGRect = .zero, font: UIFont = .boldSystemFont(ofSize: 20), displayNumber: Any? = nil) {

        if displayNumber != nil && (displayNumber is Float || displayNumber is Int) == false {
            fatalError("displayNumber must be Float or Int type")
        }
        if let display = displayNumber as? Int {
            currentNumber = type == .flash ? Float(display) : display
        } else if let display = displayNumber as? Float {
            currentNumber = type == .flash ? display : Int(display)
        } else {
            currentNumber = type == .flash ? Float(0) : Int(0)
        }
        animType = type
        switch type {
        case .flash:
            if let org = currentNumber as? Float {
                flashLabel = FlashNumberLabel.init(frame: frame)
                flashLabel?.font = font
                flashLabel?.formatClosure = formatClosure
                flashLabel?.attributedFormatClosure = attributedFormatClosure
                flashLabel?.animation(to: org)
            }
        case .scroll:
            if let org = currentNumber as? Int {
                scrollLabel = ScrollNumberLabel.init(originNumber: org, font: font)
                scrollLabel?.frame.origin = frame.origin
                scrollLabel?.textColor = textColor
            }
        }
    }
    /*
     func changeNumber(_ number: Int, interval: TimeInterval = 0, animated: Bool = true)
     func animation(_ from: Float = 0, to endNumber: Float, duration: TimeInterval = 2, options: NumberAnimationOptions = .linear)
     */

    func changeDisplayNumber(_ displayNumber: Any? = nil, to destNumber: Any? = nil, duration: TimeInterval = 2, options: NumberAnimationOptions = .linear, animated: Bool = true) {
        switch animType {
        case .flash:
            guard let flash = flashLabel else { return }
            currentNumber = destNumber ?? 0
            var from: Float = 0
            var target: Float = 0
            if let display = displayNumber as? Int {
                from = Float(display)
            } else if let display = displayNumber as? Float {
                from = display
            } else {
                from = 0
            }
            if let dest = destNumber as? Int {
                target = Float(dest)
            } else if let dest = destNumber as? Float {
                target = dest
            } else {
                target = 0
            }
            flash.animation(from, to: target, duration: duration, options: options)
        case .scroll:
            currentNumber = displayNumber
            if let scroll = scrollLabel, let org = displayNumber as? Int {
                scroll.changeNumber(org, interval: duration, animated: animated)
            }
        }
    }
}

fileprivate extension String {
    /// 随机字符串
    ///
    /// - Parameter length: 长度
    /// - Returns: 随机字符串
    static func random(_ length: Int = 10) -> String {
        let base = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        var randomString: String = ""

        for _ in 0 ..< length {
            let randomValue = arc4random_uniform(UInt32(base.count))
            randomString += "\(base[base.index(base.startIndex, offsetBy: Int(randomValue))])"
        }

        return randomString
    }
}



/// 动画类型
///
/// - easeInOut: 由慢到快再到慢
/// - easeIn: 由慢到快
/// - easeOut: 由快到慢
/// - linear: 线性
/// - easeInBounce: 由慢到快弹性变化
/// - easeOutBounce: 由慢到快弹性变化
enum NumberAnimationOptions {
    case easeInOut
    case easeIn
    case easeOut
    case linear
    case easeInBounce
    case easeOutBounce
}

/// 滚动方向
///
/// - up: 上
/// - down: 下
fileprivate enum ScrollDirection {
    case up
    case down
}

/// 动画率
fileprivate let numberAnimationRate: Float = 3.0
/// 法向系数
fileprivate let normalModulus: TimeInterval = 0.3
/// 缓冲系数
fileprivate let bufferModulus: TimeInterval = 0.7
/// 计算文本
fileprivate let calculateText = "0\n1\n2\n3\n4\n5\n6\n7\n8\n9\n0"
/// 滚动属性
fileprivate struct ScrollAttr {
    var repeatCount: Int = 0
    var startDuration: TimeInterval
    var endDuration: TimeInterval
    var cycleDuration: TimeInterval
    var displayNumber: Int
    var startDelay: TimeInterval
}
/// 滚动任务
fileprivate struct Task {
    var identifier: String = ""
    var displayNumber: Int = 0
    var changeNumber: Int = 0
    var interval: TimeInterval = 0
}

fileprivate class ScrollNumberLabel: UIView {
    /// 当前显示数字
    var displayNumber: Int = 0
    /// 标签数组
    private var labels: [UILabel] = []
    /// 行数
    private var rowNumber: Int = 0
    /// 任务数组
    private var tasks: [Task] = []
    /// 是否动画
    private var isAnimation: Bool = false
    /// 单元大小
    private var labelSize: CGSize = .zero
    /// 字体
    private var font: UIFont = UIFont.boldSystemFont(ofSize: 30)
    /// 文本颜色
    fileprivate var textColor: UIColor = .gray {
        didSet {
            for label in labels {
                label.textColor = textColor
            }
        }
    }
    /// 已完成动画数
    private var finishedAnimationCount: Int = 0
    /// 最大行数
    private var maxRowNumber: Int = 0

    convenience init() {
        self.init(originNumber: 0)
    }

    init(originNumber: Int, font: UIFont? = nil, textColor: UIColor? = nil, rowNumber: Int = 0, attri: [AnyHashable: Any]? = nil) {
        super.init(frame: .zero)
        self.displayNumber = originNumber
        if let f =  font {
            self.font = f
        }
        if let t = textColor {
            self.textColor = t
        }
        self.isAnimation = false
        self.finishedAnimationCount = 0
        self.rowNumber = (rowNumber > 0 && rowNumber <= 8) ? rowNumber : 0
        self.maxRowNumber = (self.rowNumber == 0) ? 8 : rowNumber
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func changeNumber(_ number: Int, interval: TimeInterval = 0, animated: Bool = true) {
        if number < 0 {
            return
        }
        if calculateRowNumber(number) > maxRowNumber {
            return
        }
        if number == displayNumber {
            return
        }
        if isAnimation {
            let task = Task.init(identifier: String.random(), displayNumber: number, changeNumber: (number - displayNumber), interval: interval)
            tasks.append(task)
        } else {
            if animated {
                playAnimation(with: (number - displayNumber), displayNumber: number, time: interval)
                isAnimation = true
            } else {
                let displayNumbers = labelDisplayNumber(number)
                for i in 0 ..< displayNumbers.count {
                    scroll(labels[i], to: displayNumbers[i])
                }
            }
        }
        displayNumber = number
    }
}

fileprivate extension ScrollNumberLabel {

    /// 初始化
    func commonInit() {
        initLabel()
        initParent()
    }

    /// 父级初始化
    func initParent() {
        self.bounds = CGRect.init(origin: .zero, size: CGSize.init(width: CGFloat(rowNumber) * labelSize.width, height: labelSize.height / 11.0))
        backgroundColor = .clear
        layer.masksToBounds = true
        layoutCell(with: rowNumber, animated: true)
    }

    /// 初始化单元
    func initLabel() {
        if rowNumber == 0 {
            rowNumber = calculateRowNumber(displayNumber)
        }
        labels = []
        let rect = NSString.init(string: calculateText).boundingRect(with: .zero, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [.font: self.font], context: nil)
        labelSize = rect.size

        let numbers = labelDisplayNumber(displayNumber)
        for i in 0 ..< rowNumber {
            let label = initScrollLabel()
            label.frame = CGRect.init(origin: CGPoint.init(x: CGFloat(rowNumber - 1 - i) * labelSize.width, y: 0), size: labelSize)
            label.text = calculateText
            let currentNumber = numbers[i]
            scroll(label, to: currentNumber)
            labels.append(label)
        }
    }

    /// 重新初始化标签
    ///
    /// - Parameter rowNumber: 行数
    func reInitLabel(with rowNumber: Int) {
        if rowNumber > self.rowNumber {
            for i in self.rowNumber ..< rowNumber {
                let label = initScrollLabel()
                label.frame = CGRect.init(origin: CGPoint.init(x: CGFloat(self.rowNumber - 1 - i) * labelSize.width, y: 0), size: labelSize)
                label.text = calculateText
                labels.append(label)
            }
        } else {
            for _ in rowNumber ..< self.rowNumber {
                labels.removeLast()
            }
        }
    }

    /// 视图布局
    ///
    /// - Parameters:
    ///   - rowNumber: 行数
    ///   - animated: 是否动画
    func layoutCell(with rowNumber: Int, animated: Bool) {
        for view in self.subviews {
            view.removeFromSuperview()
        }
        for label in labels {
            addSubview(label)
        }
        if rowNumber == self.rowNumber {
            return
        }
        func layout() {
            for i in 0 ..< rowNumber {
                let label = self.labels[i]
                label.frame = CGRect.init(origin: CGPoint.init(x: CGFloat(rowNumber - 1 - i) * self.labelSize.width, y: label.frame.minY), size: self.labelSize)
            }
            self.frame = CGRect.init(origin: self.frame.origin, size: CGSize.init(width: CGFloat(rowNumber) * self.labelSize.width, height: self.labelSize.height / 11.0))
        }
        if animated {
            UIView.animate(withDuration: 0.2 * TimeInterval(rowNumber - self.rowNumber)) {
                layout()
            }
        } else {
            layout()
        }
    }

    /// 执行动画
    ///
    /// - Parameters:
    ///   - changeNumber: 变化数字
    ///   - displayNumber: 当前数字
    ///   - interval: 时长
    func playAnimation(with changeNumber: Int, displayNumber: Int, time: TimeInterval) {
        let nextRowNumber = calculateRowNumber(displayNumber)
        if nextRowNumber > self.rowNumber {
            reInitLabel(with: nextRowNumber)
            layoutCell(with: nextRowNumber, animated: true)
            self.rowNumber = nextRowNumber
        }
        let repeats = repeatCount(with: changeNumber, displayNumber: displayNumber)
        let willDisplayNumbers = labelDisplayNumber(displayNumber)
        var newInterval = time
        if newInterval == 0 {
            newInterval = getInterval(with: displayNumber - changeNumber, displayNumber: displayNumber)
        }
        let direction: ScrollDirection = changeNumber > 0 ? .up : .down
        var delay: TimeInterval = 0
        if repeats.count != 0 {
            for i in 0 ..< repeats.count {
                let repeatCount = repeats[i]
                let willDisplayNum = willDisplayNumbers[i]
                let label = labels[i]
                var startDuration: TimeInterval = 0
                if repeatCount == 0 {
                    singleAnimation(for: label, duration: newInterval, delay: delay, animationCount: repeats.count, displayNumber: willDisplayNum)
                } else {
                    if direction == .up {
                        startDuration = newInterval * TimeInterval((10 - getDisplayNumber(width: label))) / ceil(fabs(Double(changeNumber) / pow(10, Double(i))))
                        var cycleDuration = newInterval * 10 / fabs(Double(changeNumber) / pow(10, Double(i)))
                        if repeatCount == 1 {
                            cycleDuration = 0
                        }
                        let endDuration = bufferModulus * pow(Double(willDisplayNum), 0.3) / TimeInterval(i + 1)
                        let attr = ScrollAttr.init(repeatCount: (repeatCount - 1), startDuration: startDuration, endDuration: endDuration, cycleDuration: cycleDuration, displayNumber: willDisplayNum, startDelay: delay)
                        multiAnimation(withLabel: label, direction: direction, animationCount: repeats.count, attri: attr)
                    } else if direction == .down {
                        startDuration = newInterval * (TimeInterval(getDisplayNumber(width: label) - 0) / ceil(fabs(Double(changeNumber) / pow(10, Double(i)))))
                        var cycleDuration = newInterval * 10 / fabs(Double(changeNumber) / pow(10, Double(i)))

                        if repeatCount == 1 {
                             cycleDuration = 0;
                        }
                        let endDuration = bufferModulus * pow(Double(10 - willDisplayNum), 0.3) / Double(i + 1)
                        let attr = ScrollAttr.init(repeatCount: (repeatCount - 1), startDuration: startDuration, endDuration: endDuration, cycleDuration: cycleDuration, displayNumber: willDisplayNum, startDelay: delay)
                        multiAnimation(withLabel: label, direction: direction, animationCount: repeats.count, attri: attr)
                    }
                }
                delay += startDuration
            }
        }
    }
    /// 每个单元动画
    ///
    /// - Parameters:
    ///   - label: 单元
    ///   - direction: 方向
    ///   - animationCount: 重复次数
    ///   - attr: 属性
    func multiAnimation(withLabel label: UILabel, direction: ScrollDirection, animationCount count: Int, attri: ScrollAttr) {
        UIView.animate(withDuration: attri.startDuration, delay: attri.startDelay, options: UIView.AnimationOptions.curveEaseIn, animations: {
            self.scroll(label, to: (direction == .up) ? 10 : 0)
        }) { (finished) in
            self.scroll(label, to: (direction == .up) ? 0 : 10)
            if attri.cycleDuration == 0 {
                UIView.animate(withDuration: attri.endDuration, delay: 0, options: .curveEaseOut, animations: {
                    self.scroll(label, to: attri.displayNumber)
                }, completion: { (finished) in
                    self.checkTasks(withCount: count)
                })
            } else {
                UIView.animate(withDuration: attri.cycleDuration, delay: 0, options: [.curveLinear, .repeat], animations: {
                    UIView.setAnimationRepeatCount(Float(attri.repeatCount))
                    switch direction {
                    case .up:
                        self.scroll(label, to: 10)
                    case .down:
                        self.scroll(label, to: 0)
                    }
                }, completion: { (finished) in
                    self.scroll(label, to: (direction == .up) ? 0 : 10)
                    UIView.animate(withDuration: attri.endDuration, delay: 0, options: .curveEaseOut, animations: {
                        self.scroll(label, to: attri.displayNumber)
                    }, completion: { (finished) in
                        self.checkTasks(withCount: count)
                    })
                })
            }
        }
    }

    /// 单个数组动画效果
    ///
    /// - Parameters:
    ///   - label: 标签
    ///   - duration: 时长
    ///   - delay: 延时
    ///   - count: 重复次数
    ///   - displayNumber: 当前师资
    func singleAnimation(for label: UILabel, duration: TimeInterval, delay: TimeInterval, animationCount count: Int, displayNumber: Int) {
        UIView.animate(withDuration: duration, delay: delay, options: UIView.AnimationOptions.curveEaseOut, animations: {
            self.scroll(label, to: displayNumber)
        }) { (finished) in
            self.checkTasks(withCount: count)
        }
    }

    /// 检查执行任务
    ///
    /// - Parameter count: 已完成次数
    func checkTasks(withCount count: Int) {
        finishedAnimationCount += 1
        if finishedAnimationCount == count {
            finishedAnimationCount = 0
            if tasks.count != 0 {
                let task = tasks[0]
                if let index = tasks.index(where: {task.identifier == $0.identifier}) {
                    tasks.remove(at: index)
                }
                playAnimation(with: task.changeNumber, displayNumber: task.displayNumber, time: task.interval)
            } else {
                isAnimation = false
            }
        }
    }

    /// 根据数字获取单元显示数字数组
    ///
    /// - Parameter number: 数字
    /// - Returns: 数字数组
    func labelDisplayNumber(_ number: Int) -> [Int] {
        var labelNumbers: [Int] = []
        var tmpNumber = 0
        var newNumber = number
        for _ in 0 ..< rowNumber {
            tmpNumber = newNumber % 10
            labelNumbers.append(tmpNumber)
            newNumber = newNumber / 10
        }
        return labelNumbers
    }

    /// 根据标签获取显示对应的数字
    ///
    /// - Parameter label: 标签
    func getDisplayNumber(width label: UILabel) -> Int {
        let y = label.frame.minY
        let tmpNumber = -(y * 11 / labelSize.height)
        return Int.init(round(Double.init(tmpNumber)))
    }

    /// 根据数字计算动画时长
    ///
    /// - Parameter changeNumber: 变化数字
    /// - Returns: 时长
    func calculateInterval(with changeNumber: Int) -> TimeInterval {
        let changeRow = calculateRowNumber(changeNumber)
        return fabs(normalModulus * (Double(changeNumber) / pow(10, Double(changeRow - 1))))
    }

    /// 根据原始和当前数字获取动画时长
    ///
    /// - Parameters:
    ///   - orgNumber: 原始数字
    ///   - displayNumber: 当前数字
    /// - Returns: 时长
    func getInterval(with orgNumber: Int, displayNumber: Int) -> TimeInterval {
        let repeats = repeatCount(with: displayNumber - orgNumber, displayNumber: displayNumber)
        let count = repeats.count
        let temp1 = displayNumber / Int(pow(10, Double(count - 1)))
        let temp2 = orgNumber / Int(pow(10, Double(count - 1)))
        let maxChangeNumber = labs(temp1 % 10 - temp2 % 10)
        return normalModulus * TimeInterval(count * maxChangeNumber)
    }

    /// 重复次数
    ///
    /// - Parameters:
    ///   - changeNumber: 变化数字
    ///   - displayNumber: 当前数字
    /// - Returns: 次数数组
    func repeatCount(with changeNumber: Int, displayNumber: Int) -> [Int] {
        var repeats: [Int] = []
        var newNumber = displayNumber
        var orgNumber = newNumber - changeNumber
        if changeNumber > 0 {
            repeat {
                newNumber = (newNumber / 10) * 10
                orgNumber = (orgNumber / 10) * 10
                let repeatNumber = (newNumber - orgNumber) / 10
                repeats.append(repeatNumber)
                newNumber = newNumber / 10
                orgNumber = orgNumber / 10
            } while (newNumber - orgNumber) != 0
        } else {
            repeat {
                newNumber = (newNumber / 10) * 10
                orgNumber = (orgNumber / 10) * 10
                let repeatNumber = (orgNumber - newNumber) / 10
                repeats.append(repeatNumber)
                newNumber = newNumber / 10
                orgNumber = orgNumber / 10
            } while (orgNumber - newNumber) != 0
        }
        return repeats
    }


    /// 根据数字计算行数
    ///
    /// - Parameter number: 数字
    func calculateRowNumber(_ number: Int) -> Int {
        var row = 1
        var newNumber = number
        newNumber = newNumber / 10
        while newNumber != 0 {
            newNumber = newNumber / 10
            row += 1
        }
        return row
    }

    /// 指定的单元滚动至指定数字
    ///
    /// - Parameter number: 数字
    func scroll(_ label: UILabel, to number: Int) {
        let originX = label.frame.minX
        let floatNumber = CGFloat(number)
        let y = -(floatNumber / 11.0) * labelSize.height
        label.frame = CGRect.init(origin: CGPoint.init(x: originX, y: y), size: labelSize)
    }

    /// 实例化单元标签
    func initScrollLabel() -> UILabel {
        let label = UILabel.init()
        label.font = font
        label.numberOfLines = 11
        label.textColor = textColor
        return label
    }
}

/// 闪动数字标签
fileprivate class FlashNumberLabel: UILabel {
    /// 格式化
    var format: String? {
        didSet {
            setTextValue(currentValue)
        }
    }
    /// 当前值
    var currentValue: Float {
        if progress >= totalTime {
            return endValue
        }
        let percent = Float.init(progress / totalTime)
        let updatedValue = delegate?.updateValue(percent) ?? 0
        return startingValue + (updatedValue * (endValue - startingValue))
    }
    /// 格式化闭包
    var formatClosure: ((Float) -> (String))?
    /// 富文本格式化闭包
    var attributedFormatClosure: ((Float) -> (NSAttributedString))?
    /// 完成回调
    var finishedClosure: (() -> ())?

    /// 开始值
    private var startingValue: Float = 0
    /// 结束值
    private var endValue: Float = 0
    /// 进度
    private var progress: TimeInterval = 0
    /// 上传更新
    private var lastUpdate: TimeInterval = 0
    /// 总时间
    private var totalTime: TimeInterval = 0
    /// 延伸比率
    private var easingRate: Float = 0
    /// 代理
    private var delegate: NumberAnimationOptionsDelegate?
    /// 动画频率
    private var displayLink: CADisplayLink?

    /// 数字动画
    ///
    /// - Parameters:
    ///   - from: 开始值
    ///   - endNumber: 结束值
    ///   - duration: 动画时长
    func animation(_ from: Float = 0, to endNumber: Float, duration: TimeInterval = 3, options: NumberAnimationOptions = .linear) {
        startingValue = from
        endValue = endNumber
        if displayLink != nil {
            displayLink?.invalidate()
            displayLink = nil
        }
        if format == nil {
            format = "%f"
        }

        if duration == 0 {
            setTextValue(endValue)
            execFinishedClosure()
            return
        }
        easingRate = 3.0
        progress = 0
        totalTime = duration
        lastUpdate = Date.timeIntervalSinceReferenceDate
        switch options {
        case .linear:
            delegate = NumberAnimationOptionsLinear.init()
        case .easeIn:
            delegate = NumberAnimationOptionsEaseIn.init()
        case .easeOut:
            delegate = NumberAnimationOptionsEaseOut.init()
        case .easeInOut:
            delegate = NumberAnimationOptionsEaseInOut.init()
        case .easeInBounce:
            delegate = NumberAnimationOptionseaseInBounce.init()
        case .easeOutBounce:
            delegate = NumberAnimationOptionsEaseOutBounce.init()
        }
        if displayLink != nil {
            displayLink?.invalidate()
            displayLink = nil
        }
        displayLink = CADisplayLink.init(target: self, selector: #selector(updateValue(_:)))

        displayLink?.add(to: .main, forMode: .default)
        displayLink?.add(to: .main, forMode: .tracking)

    }


}

// MARK: - 私有
fileprivate extension FlashNumberLabel {

    @objc func updateValue(_ link: CADisplayLink) {
        let now = Date.timeIntervalSinceReferenceDate
        progress += (now - lastUpdate)
        lastUpdate = now
        if progress >= totalTime {
            displayLink?.invalidate()
            displayLink = nil
            progress = totalTime
        }

        setTextValue(currentValue)
        if progress == totalTime {
            execFinishedClosure()
        }
    }
    /// 设置文本
    ///
    /// - Parameter value: 数值
    private func setTextValue(_ value: Float) {
        if let attrClosure = attributedFormatClosure {
            attributedText = attrClosure(value)
        } else if let closure = formatClosure {
            text = closure(value)
        } else if let fmt = format {
            if fmt.range(of: "%(.*)d", options: String.CompareOptions.regularExpression) != nil || fmt.range(of: "%(.*)i", options: String.CompareOptions.regularExpression) != nil {
                text = String.init(format: fmt, Int.init(value))
            } else {
                text = String.init(format: fmt, value)
            }
        }
    }

    /// 执行完成回调
    private func execFinishedClosure() {
        if let handler = finishedClosure {
            handler()
            finishedClosure = nil
        }
    }
}

fileprivate protocol NumberAnimationOptionsDelegate {
    /// 更新数值
    func updateValue(_ value: Float) -> Float
}

fileprivate class NumberAnimationOptionsEaseInOut: NumberAnimationOptionsDelegate {
    func updateValue(_ value: Float) -> Float {
        let newValue = value * 2
        if newValue < 1 {
            return 0.5 * powf(newValue, numberAnimationRate)
        } else {
            return 0.5 * (2.0 - powf((2.0 - newValue), numberAnimationRate))
        }
    }
}

fileprivate class NumberAnimationOptionsEaseIn: NumberAnimationOptionsDelegate {
    func updateValue(_ value: Float) -> Float {
        return powf(value, numberAnimationRate)
    }
}



fileprivate class NumberAnimationOptionsEaseOut: NumberAnimationOptionsDelegate {
    func updateValue(_ value: Float) -> Float {
        return 1.0 - powf((1.0 - value), numberAnimationRate)
    }
}

fileprivate class NumberAnimationOptionsLinear: NumberAnimationOptionsDelegate {
    func updateValue(_ value: Float) -> Float {
        return value
    }
}

fileprivate class NumberAnimationOptionseaseInBounce: NumberAnimationOptionsDelegate {
    func updateValue(_ value: Float) -> Float {
        if value < (4.0 / 11.0) {
            return 1.0 - (powf(11.0 / 4.0, 2) * powf(value, 2)) - value
        } else if value < (8.0 / 11.0) {
            return 1.0 - (3.0 / 4.0 + powf(11.0 / 4.0, 2) * powf(value - 6.0 / 11.0, 2)) - value
        } else if value < (10.0 / 11.0) {
            return 1.0 - (15.0 / 16.0 + powf(11.0 / 4.0, 2) * powf(value - 9.0 / 11.0, 2)) - value
        } else {
            return 1.0 - (63.0 / 64.0 + powf(11.0 / 4.0, 2) * powf(value - 21.0 / 22.0, 2)) - value
        }
    }
}

fileprivate class NumberAnimationOptionsEaseOutBounce: NumberAnimationOptionsDelegate {
    func updateValue(_ value: Float) -> Float {
        if value < (4.0 / 11.0) {
            return (powf(11.0 / 4.0, 2) * powf(value, 2))
        } else if value < (8.0 / 11.0) {
            return (3.0 / 4.0 + powf(11.0 / 4.0, 2) * powf(value - 6.0 / 11.0, 2))
        } else if value < (10.0 / 11.0) {
            return (15.0 / 16.0 + powf(11.0 / 4.0, 2) * powf(value - 9.0 / 11.0, 2))
        } else {
            return (63.0 / 64.0 + powf(11.0 / 4.0, 2) * powf(value - 21.0 / 22.0, 2))
        }
    }
}
