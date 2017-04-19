//
//  ProjectTableViewController.swift
//  GetSchwifty
//
//  Created by Marius Landwehr on 19.04.17.
//  Copyright © 2017 Benjamin Herzog. All rights reserved.
//

import UIKit

protocol ProjectTableViewControllerDelegate: class {
    func projectTableViewControllerDidSelect(schwifty: Schwifty)
}

class ProjectTableViewController: UITableViewController {
    
    private var projects = [Schwifty]()
    private let dataStore = SchwiftyDataStorage()

    weak var delegate: ProjectTableViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ProjectCell")
        title = "Get Schwifty"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(self.newSchwifty))
        tableView.backgroundColor = UIColor(r: 31, g: 32, b: 41, a: 1)
        tableView.tintColor = UIColor(r: 237, g: 82, b: 63, a: 1)
        tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
        self.projects = dataStore.all()
        self.tableView.reloadData()
    }

    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.projects.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProjectCell", for: indexPath)
        cell.backgroundColor = UIColor(r: 31, g: 32, b: 41, a: 1)
        cell.textLabel?.textColor = UIColor(r: 225, g: 226, b: 231, a: 1)
        let view = UIView(frame: cell.bounds)
        view.backgroundColor = UIColor(r: 36, g: 37, b: 46, a: 1)
        cell.selectedBackgroundView = view
        cell.textLabel?.font = font
        cell.textLabel?.text = projects[indexPath.row].name
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // TODO: Select other file
        self.delegate?.projectTableViewControllerDidSelect(schwifty: self.projects[indexPath.row])
    }
    
    public func newSchwifty() {
        self.delegate?.projectTableViewControllerDidSelect(schwifty: Schwifty(source: ""))
    }
}
