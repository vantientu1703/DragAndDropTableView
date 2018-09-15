# DragAndDropTableView

#Implement

#Conform delehate and add gesture to view:

self.tableView.mDelegate = self
//If you have self-resizing table view cell, need to implement

self.tableView.rowHeight = CGFloat #0

self.tableView.addGestureToView(mainView: self.view)

#In UITableViewCell, we implement prepareForReuse():

override func prepareForReuse() {

    self.isHidden = false
}

#Datasource

func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
    
    var sourceStrings = items[sourceIndexPath.section]
    let  sourceString = sourceStrings[sourceIndexPath.row]
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

//If use self-resizing table view cell

func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {

    return self.viewModel.dictHeights[indexPath] ?? 150.0
}

func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {

    self.viewModel.dictHeights[indexPath] = cell.frame.size.height
}

#mDelegate

extension ViewController: DragAndDropTableViewDelegate {
    
    func reoderDidEnded() {
        // Kết thúc reorder cells
        // TODO somethings
    }
}


