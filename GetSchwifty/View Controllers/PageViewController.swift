//
//  PageViewController.swift
//  WWDC
//
//  Created by Benjamin Herzog on 02.04.17.
//  Copyright © 2017 Benjamin Herzog. All rights reserved.
//

import UIKit

public class PageViewController: UIPageViewController {
    
    fileprivate let browser = ProjectTableViewController()
    fileprivate let source = SourceViewController()
    fileprivate let log = LogViewController()
    
    fileprivate lazy var controllers: [UIViewController] = {
        return [self.browser, self.source, self.log].map {
            $0.wrapInNavigationController()
        }
    }()
    
    init() {
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.source.outStream = self.log.write(_:)
        
        self.browser.delegate = self
        self.source.delegate = self
        self.log.delegate = self
        
        self.dataSource = self
        self.setViewControllers([self.controllers[1]], direction: .forward, animated: false, completion: nil)
        
        // trigger viewDidLoad initially
        _ = self.browser.view
        _ = self.source.view
        _ = self.log.view
    }

}

extension PageViewController: UIPageViewControllerDataSource {
    
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = self.controllers.index(of: viewController) else {
            return nil
        }
        let newIndex = index + 1
        return self.controllers[safe: newIndex]
    }
    
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = self.controllers.index(of: viewController) else {
            return nil
        }
        
        let newIndex = index - 1
        return self.controllers[safe: newIndex]
    }
    
}

extension PageViewController {
    
    fileprivate func setIndex(_ index: Int, direction: UIPageViewControllerNavigationDirection, completion: @escaping (Bool) -> Void = {_ in}) {
        guard let controller = self.controllers[safe: index] else {
            return
        }
        self.setViewControllers([controller], direction: direction, animated: true, completion: completion)
    }
    
}

extension PageViewController: LogViewControllerDelegate {
    public func logViewControllerDidPressBack() {
        self.setIndex(1, direction: .reverse)
    }
    
    public func logViewControllerDidPressStop() {
        self.source.stop()
    }
}

extension PageViewController: SourceViewControllerDelegate {
    
    public func sourceViewControllerWillEvaluate(start: @escaping () -> Void) {
        self.setIndex(2, direction: .forward) { [weak self] _ in
            self?.log.didStart()
            start()
        }
    }
    
    public func sourceViewControllerDidEvaluate() {
        self.log.didStop()
    }
}

extension PageViewController: ProjectTableViewControllerDelegate {
    
    func projectTableViewControllerDidSelect(schwifty: Schwifty) {
        self.source.load(schwifty: schwifty)
        self.setIndex(1, direction: .forward)
    }
    
}

extension UIViewController {
    
    public func wrapInNavigationController() -> UINavigationController {
        if let nav = self.navigationController {
            return nav
        }
        return UINavigationController(rootViewController: self)
    }
    
    public var headerHeight: CGFloat {
        return (self.navigationController?.navigationBar.bounds.size.height ?? 0) + UIApplication.shared.statusBarFrame.size.height
    }
    
    public var topParent: UIViewController {
        var top = self
        while let p = top.parent {
            top = p
        }
        return top
    }
    
}

extension Array {
    
    public subscript(safe index: Index) -> Element? {
        guard count > index, index >= 0 else {
            return nil
        }
        return self[index]
    }
    
}
