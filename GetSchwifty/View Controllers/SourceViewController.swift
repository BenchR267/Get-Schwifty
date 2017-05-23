//
//  ViewController.swift
//  WWDC
//
//  Created by Benjamin Herzog on 29.03.17.
//  Copyright © 2017 Benjamin Herzog. All rights reserved.
//

import UIKit

protocol SourceViewControllerDelegate: class {
    func sourceViewControllerWillEvaluate(start: @escaping () -> Void)
    func sourceViewControllerDidEvaluate()
    func sourceViewControllerDidPressShowList()
}

class SourceViewController: UIViewController {

    fileprivate var schwifty: Schwifty {
        didSet {
            self.title = self.schwifty.name
            self.updateText(text: self.schwifty.source)
        }
    }

    init() {
        guard let path = Bundle.main.path(forResource: "start_script", ofType: "txt") else {
            fatalError("Could not open start script!")
        }
        let startContent = (try? String(contentsOfFile: path)) ?? ""

        self.schwifty = Schwifty(source: startContent)
        super.init(nibName: nil, bundle: nil)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate var textView: UITextView!
    private let generator = Generator()

    public var outStream: (String) -> Void = { print($0) }

    private var observer: NSObjectProtocol?

    public weak var delegate: SourceViewControllerDelegate?

    public override func viewDidLoad() {
        super.viewDidLoad()

        self.textView = UITextView(frame: self.view.bounds)
        self.textView.autocapitalizationType = .none
        self.textView.autocorrectionType = .no
        self.textView.alwaysBounceVertical = true
        self.textView.keyboardDismissMode = .interactive
        self.textView.keyboardAppearance = .dark
        self.textView.delegate = self
        self.textView.backgroundColor = UIColor(r: 31, g: 32, b: 41, a: 1)
        self.textView.tintColor = UIColor(r: 237, g: 82, b: 63, a: 1)
        self.view.backgroundColor = self.textView.backgroundColor

        self.textView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.addSubview(self.textView)

        self.load(schwifty: self.schwifty)

        self.observer = NotificationCenter.default.addObserver(forName: .UIKeyboardWillChangeFrame, object: nil, queue: .main) { [weak self] n in
            guard let weakSelf = self else { return }
            guard let endFrame = n.userInfo?[UIKeyboardFrameEndUserInfoKey] as? CGRect else {
                return
            }
            weakSelf.textView.contentInset = UIEdgeInsets(top: weakSelf.headerHeight,
                                                          left: 0,
                                                          bottom: weakSelf.view.bounds.size.height - endFrame.origin.y,
                                                          right: 0)
        }
        let run = UIBarButtonItem(image: #imageLiteral(resourceName: "Play"), style: .plain, target: self, action: #selector(self.evaluateHandler))
        let list = UIBarButtonItem(image: #imageLiteral(resourceName: "List"), style: .plain, target: self, action: #selector(self.showList))
        let save = UIBarButtonItem(image: #imageLiteral(resourceName: "Save"), style: .plain, target: self, action: #selector(self.save))
        self.navigationItem.leftBarButtonItem = run
        self.navigationItem.rightBarButtonItems = [list, save]
    }

    @objc func showList() {
        self.delegate?.sourceViewControllerDidPressShowList()
    }

    @objc func save() {
        self.schwifty.temporary = false
        SchwiftyDataStorage().save(self.schwifty)
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.textView.contentInset = UIEdgeInsets(top: self.headerHeight, left: 0, bottom: 0, right: 0)
    }

    @objc func evaluateHandler() {
        self.evaluate()
    }

    var currentEvaluator: JSEvaluator?
    func stop() {
        self.currentEvaluator?.stop()
        self.currentEvaluator = nil
    }

    func load(schwifty: Schwifty) {
        if self.schwifty.id != schwifty.id {
            SchwiftyDataStorage().save(self.schwifty)
        }
        self.schwifty = schwifty
    }

    private func evaluate() {
        self.textView.resignFirstResponder()
        do {
            let lexer = Lexer(input: self.textView.text)
            let tokens = lexer.start()
            let parser = Parser(tokens: tokens)
            let program = try parser.parseProgram()
            let evaluator = JSEvaluator(controller: self.topParent, outStream: self.outStream)
            self.currentEvaluator = evaluator

            let block: () -> Void = {
                evaluator.run(script: program) {
                    self.delegate?.sourceViewControllerDidEvaluate()
                    self.currentEvaluator = nil
                }
            }

            if let delegate = self.delegate {
                delegate.sourceViewControllerWillEvaluate(start: block)
            } else {
                block()
            }

        } catch let error as Parser.Error {
            let c = UIAlertController(title: "Error", message: "Sorry, there is an error in your sourcecode. Maybe this helps you tracking it down:\n\n\(error.string)", preferredStyle: .alert)
            c.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(c, animated: true)
        } catch {
            let c = UIAlertController(title: "Error", message: "Unexpected error occured.", preferredStyle: .alert)
            c.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(c, animated: true)
        }
    }

}

extension SourceViewController: UITextViewDelegate {

    static let throttle: TimeInterval = 0.05

    public func textViewDidChange(_ textView: UITextView) {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        self.perform(#selector(updateText), with: textView.text, afterDelay: SourceViewController.throttle)
        self.schwifty.source = textView.text
    }

    @objc func updateText(text: String) {
        let lexer = Lexer(input: text)
        let tokens = lexer.start()
        let range = textView.selectedRange
        textView.isScrollEnabled = false
        textView.attributedText = attributedString(tokens: tokens)
        textView.isScrollEnabled = true
        textView.selectedRange = range
    }

}
