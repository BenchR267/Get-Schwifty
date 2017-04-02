//
//  PageViewController.swift
//  WWDC
//
//  Created by Benjamin Herzog on 02.04.17.
//  Copyright © 2017 Benjamin Herzog. All rights reserved.
//

import UIKit

class PageViewController: UIPageViewController {
    
    fileprivate let source = SourceViewController()
    fileprivate let log = LogViewController()
    
    fileprivate lazy var controllers: [UIViewController] = {
        return [self.source, self.log]
    }()
    
    init() {
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.source.outStream = self.log.write(_:)
        self.source.clear = self.log.clear
        
        self.source.delegate = self
        self.log.delegate = self
        
        self.dataSource = self
        self.setViewControllers([self.controllers[0]], direction: .forward, animated: false, completion: nil)
        
        // trigger viewDidLoad initially
        self.controllers.forEach { _ = $0.view }
    }

}

extension PageViewController: UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = self.controllers.index(of: viewController) else {
            return nil
        }
        let newIndex = index + 1
        return self.controllers[safe: newIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = self.controllers.index(of: viewController) else {
            return nil
        }
        
        let newIndex = index - 1
        return self.controllers[safe: newIndex]
    }
    
}

extension PageViewController {
    
    fileprivate func setIndex(_ index: Int, direction: UIPageViewControllerNavigationDirection) {
        guard let controller = self.controllers[safe: index] else {
            return
        }
        self.setViewControllers([controller], direction: direction, animated: true, completion: nil)
    }
    
}

extension PageViewController: LogViewControllerDelegate {
    func logViewControllerDidPressBack() {
        self.setIndex(0, direction: .reverse)
    }
}

extension PageViewController: SourceViewControllerDelegate {
    func sourceViewControllerDidEvaluate() {
        self.setIndex(1, direction: .forward)
    }
}

extension UIViewController {
    
    func wrapInNavigationController() -> UINavigationController {
        if let nav = self.navigationController {
            return nav
        }
        return UINavigationController(rootViewController: self)
    }
    
    var headerHeight: CGFloat {
        return (self.navigationController?.navigationBar.bounds.size.height ?? 0) + UIApplication.shared.statusBarFrame.size.height
    }
    
}

extension Array {
    
    subscript(safe index: Index) -> Element? {
        guard count > index, index >= 0 else {
            return nil
        }
        return self[index]
    }
    
}
