//
//  ProjectTableViewController.swift
//  GetSchwifty
//
//  Created by Marius Landwehr on 19.04.17.
//  Copyright © 2017 Benjamin Herzog. All rights reserved.
//

import UIKit

class ProjectTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ProjectCell")
        title = "Get Schwifty"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(pushPageViewController))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProjectCell", for: indexPath)
        
        cell.textLabel?.text = "Project 1"
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        pushPageViewController()
    }
    
    public func pushPageViewController() {
        
        let pageViewController = PageViewController()
        navigationController?.pushViewController(pageViewController, animated: true)
    }
}
