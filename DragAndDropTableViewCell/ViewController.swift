//
//  ViewController.swift
//  DragAndDropTableViewCell
//
//  Created by Văn Tiến Tú on 9/16/18.
//  Copyright © 2018 Văn Tiến Tú. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var tableView: DragAndDropTableView!
    private var dictHeights: [IndexPath: CGFloat] = [:]
    
    private var items: [[String]] = [["Section 0 cell 00", "Section 0 cell 01", "Section 0 cell 02", "Section 0 cell 03", "Section 0 cell 04", "Section 0 cell 05", "Section 0 cell 07", "Section 0 cell 08", "Section 0 cell 09", "Section 0 cell 10"], ["Section 1 cell 00", "Section 1 cell 01", "Section 1 cell 02", "Section 1 cell 03", "Section 1 cell 04", "Section 1 cell 05", "Section 1 cell 07", "Section 1 cell 08", "Section 1 cell 09", "Section 1 cell 10"]]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.s
        self.tableView.mDelegate = self
        self.tableView.addGestureToView(mainView: self.view)
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //TODO
    }
}

extension ViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let arrs = items[section]
        return arrs.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.dictHeights[indexPath] ?? 150.0
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        self.dictHeights[indexPath] = cell.frame.size.height
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        }
        if let c = cell {
            let arrs = items[indexPath.section]
            c.textLabel?.text = arrs[indexPath.row]
            return c
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        var sourceStrings = items[sourceIndexPath.section]
        let sourceString = sourceStrings[sourceIndexPath.row]
        if sourceIndexPath.section == destinationIndexPath.section {
            // Nếu table view của bạn chỉ có 1 section thì dùng xử lý này là đủ rồi
            // If table view has one section that only need to this hanlde
            sourceStrings.remove(at: sourceIndexPath.row)
            sourceStrings.insert(sourceString, at: destinationIndexPath.row)
            self.items[sourceIndexPath.section] = sourceStrings
        } else {
            // Nếu table view có nhiều sections thì sẽ phải xử lý dữ liệu ở đây thật chính xác nếu không sẽ crash app
            // If table view have multiple sections, you have to handle data correctly
            sourceStrings.remove(at: sourceIndexPath.row)
            var destinationStrings = items[destinationIndexPath.section]
            destinationStrings.insert(sourceString, at: destinationIndexPath.row)
            self.items[sourceIndexPath.section] = sourceStrings
            self.items[destinationIndexPath.section] = destinationStrings
        }
    }
}

extension ViewController: DragAndDropTableViewDelegate {
    func reorderDidEnded() {
        // Kết thúc reorder cells
        // TODO somethings
    }
}

