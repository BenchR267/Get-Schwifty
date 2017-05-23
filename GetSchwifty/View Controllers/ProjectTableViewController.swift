//
//  ProjectTableViewController.swift
//  GetSchwifty
//
//  Created by Marius Landwehr on 19.04.17.
//  Copyright © 2017 Benjamin Herzog. All rights reserved.
//

import UIKit

protocol ProjectTableViewControllerDelegate: class {
    func projectTableViewControllerDidPressBack()
    func projectTableViewControllerDidSelect(schwifty: Schwifty)
}

class ProjectTableViewController: UITableViewController {

    private var projects: [[Schwifty]] = [[], []]
    private let dataStore = SchwiftyDataStorage()

    weak var delegate: ProjectTableViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ProjectCell")
        title = "Get Schwifty"
        tableView.backgroundColor = UIColor(r: 31, g: 32, b: 41, a: 1)
        tableView.tintColor = UIColor(r: 237, g: 82, b: 63, a: 1)
        tableView.tableFooterView = UIView()

        let backButton = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(back))
        let new = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(self.newSchwifty))
        let info = UIBarButtonItem(image: #imageLiteral(resourceName: "Info"), style: .plain, target: self, action: #selector(showInfo))
        self.navigationItem.rightBarButtonItems = [new, info]
        self.navigationItem.leftBarButtonItem = backButton
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let all = dataStore.all()
        let temporary = all.filter { $0.temporary }
        let solid = all.filter { !$0.temporary }
        self.projects = [temporary, solid]
        self.tableView.reloadData()
    }

    @objc func back() {
        self.delegate?.projectTableViewControllerDidPressBack()
    }

    @objc func showInfo() {
        let info = InfoViewController().wrapInNavigationController()
        self.present(info, animated: true)
    }

    @objc public func newSchwifty() {
        self.delegate?.projectTableViewControllerDidSelect(schwifty: Schwifty(source: ""))
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.projects[section].count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Temporay"
        case 1: return "Saved"
        default: return nil
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProjectCell", for: indexPath)
        cell.backgroundColor = UIColor(r: 31, g: 32, b: 41, a: 1)
        cell.textLabel?.textColor = UIColor(r: 225, g: 226, b: 231, a: 1)
        let view = UIView(frame: cell.bounds)
        view.backgroundColor = UIColor(r: 36, g: 37, b: 46, a: 1)
        cell.selectedBackgroundView = view
        cell.textLabel?.font = font
        cell.textLabel?.text = projects[indexPath.section][indexPath.row].name

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // TODO: Select other file
        self.delegate?.projectTableViewControllerDidSelect(schwifty: self.projects[indexPath.section][indexPath.row])
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else {
            return
        }

        let element = self.projects[indexPath.section].remove(at: indexPath.row)
        self.dataStore.delete(element)
        self.tableView.deleteRows(at: [indexPath], with: .right)
    }
}
