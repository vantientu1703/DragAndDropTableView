//
//  DragAndDropTableView.swift
//  DragAndDropTableView
//
//  Created by van.tien.tu on 9/6/18.
//  Copyright © 2018 van.tien.tu. All rights reserved.
//

import UIKit

protocol DragAndDropTableViewDelegate: NSObjectProtocol {
    func reorderDidEnded()
}

class DragAndDropTableView: UITableView {
    
    private var cellSnapshot: UIView?
    private var destinationIndexPath: IndexPath?
    private var sourceIndexPath: IndexPath?
    private var mainView: UIView?
    private var paging : Bool = false
    var autoScrollDisplayLink: CADisplayLink?
    var lastAutoScrollTimeStamp: CFTimeInterval?
    private let autoScrollThreshold: CGFloat = 30
    private let autoScrollMinVelocity: CGFloat = 60
    private let autoScrollMaxVelocity: CGFloat = 280
    private var lastLocation: CGPoint?
    weak var mDelegate: DragAndDropTableViewDelegate?
    
    private func mapValue(_ value: CGFloat, inRangeWithMin minA: CGFloat, max maxA: CGFloat, toRangeWithMin minB: CGFloat, max maxB: CGFloat) -> CGFloat {
        return (value - minA) * (maxB - minB) / (maxA - minA) + minB
    }
    
    override init(frame: CGRect, style: UITableViewStyle) {
        super.init(frame: frame, style: style)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func addGestureToView(mainView: UIView?) {
        let longpress = UILongPressGestureRecognizer(target: self, action: #selector(longPressGestureRecognized(gestureRecognizer:)))
        longpress.minimumPressDuration = 0.3
        mainView?.addGestureRecognizer(longpress)
        self.mainView = mainView
    }
    
    @objc private func longPressGestureRecognized(gestureRecognizer: UILongPressGestureRecognizer) {
        let state = gestureRecognizer.state
        let locationInView = gestureRecognizer.location(in: self.mainView)
        switch state {
        case .began:
            self.startMovingCell(at: locationInView)
            break
        case .changed:
            self.movingCell(at: locationInView)
            break
        case .ended:
            self.endedMovingCell(at: locationInView)
            break
        default:
            break
        }
    }
    
    private func startMovingCell(at position: CGPoint) {
        guard let visibleCell = self.visibleCell(at: position) else { return }
        guard let indexPath = self.indexPath(for: visibleCell) else { return }
        let canMove = self.dataSource?.tableView?(self, canMoveRowAt: indexPath)
        self.refreshCell(at: indexPath)
        if canMove == true {
            self.destinationIndexPath = indexPath
            self.sourceIndexPath = indexPath
            self.cellSnapshot  = snapshopOfCell(inputView: visibleCell)
            self.cellSnapshot?.alpha = 0.0
            if let cellSnapshot = self.cellSnapshot {
                self.mainView?.addSubview(cellSnapshot)
            }
            self.activateAutoScrollDisplayLink()
            UIView.animate(withDuration: 0.3, animations: { () -> Void in
                let scale = CGAffineTransform.identity.scaledBy(x: 1.05, y: 1.05)
                let rotate = CGAffineTransform.identity.rotated(by: .pi / 36)
                self.cellSnapshot?.transform = scale.concatenating(rotate)
                self.cellSnapshot?.alpha = 0.8
                visibleCell.alpha = 0.0
                
            }, completion: { (finished) -> Void in
                if finished {
                    visibleCell.isHidden = true
                }
            })
        }
    }
    
    private func movingCell(at position: CGPoint) {
        if let cellSnapShot = self.cellSnapshot {
            var center = cellSnapShot.center
            center.y += self.translationY(position)
            self.lastLocation = position
            cellSnapShot.center = center
        }
        guard let visibleCell = self.visibleCell(at: position) else { return }
        guard let indexPath = self.indexPath(for: visibleCell) else { return }
        let canMove = self.dataSource?.tableView?(self, canMoveRowAt: indexPath)
        if canMove == true {
            if let destinationIndexPath = self.destinationIndexPath, indexPath != destinationIndexPath {
                let cell = self.cellForRow(at: destinationIndexPath)
                cell?.isHidden = true
                self.dataSource?.tableView?(self, moveRowAt: destinationIndexPath, to: indexPath)
                if destinationIndexPath.section != indexPath.section {
                    self.beginUpdates()
                    self.deleteRows(at: [destinationIndexPath], with: .none)
                    self.insertRows(at: [indexPath], with: .top)
                    self.endUpdates()
                } else {
                    self.moveRow(at: destinationIndexPath, to: indexPath)
                }
                self.destinationIndexPath = indexPath
            }
        }
    }
    
    private func endedMovingCell(at position: CGPoint) {
        self.lastLocation = nil
        self.mDelegate?.reorderDidEnded()
        guard let destinationIndexPath = self.destinationIndexPath else {
            self.removeData()
            return
        }
        guard let cell = self.cellForRow(at: destinationIndexPath) else {
            self.removeData()
            return
        }
        cell.alpha = 0.0
        cell.isHidden = false
        UIView.animate(withDuration: 0.4, animations: { () -> Void in
            var center = self.cellSnapshot?.center
            let rect = cell.convert(cell.bounds, to: self.mainView)
            center?.y = rect.origin.y + rect.height / 2
            if let ct = center {
                self.cellSnapshot?.center = ct
            }
            self.cellSnapshot?.transform = CGAffineTransform.identity
            self.clearAutoScrollDisplayLink()
        }, completion: { (finished) -> Void in
            if finished {
                self.reloadData()
                cell.alpha = 1.0
                self.cellSnapshot?.alpha = 0.0
                self.removeData()
            }
        })
    }
    
    private func translationY(_ location: CGPoint) -> CGFloat {
        if let lastLocation = self.lastLocation {
            return location.y - lastLocation.y
        } else {
            return 0
        }
    }
    
    private func visibleCell(at position: CGPoint) -> UITableViewCell? {
        for cell in self.visibleCells {
            let standardFrame = cell.convert(cell.bounds, to: self.mainView)
            if standardFrame.contains(position) == true {
                return cell
            }
        }
        return nil
    }
    
    private func removeData() {
        self.destinationIndexPath = nil
        self.sourceIndexPath = nil
        self.cellSnapshot?.removeFromSuperview()
        self.cellSnapshot = nil
    }
    
    private func refreshCell(at indexPath: IndexPath?) {
        for cell in self.visibleCells {
            cell.isSelected = false
        }
        if let indexPath = indexPath {
            let selectedCell = self.cellForRow(at: indexPath)
            selectedCell?.isSelected = true
        }
    }
    
    private func snapshopOfCell(inputView: UIView) -> UIView {
        UIGraphicsBeginImageContextWithOptions(inputView.bounds.size, false, 0)
        inputView.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        let cellSnapshot : UIView = UIImageView(image: image)
        cellSnapshot.layer.masksToBounds = false
        cellSnapshot.layer.cornerRadius = 8.0
        cellSnapshot.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        cellSnapshot.layer.shadowRadius = 2.0
        cellSnapshot.layer.shadowOpacity = 0.3
        cellSnapshot.layer.shadowColor = UIColor.gray.cgColor
        cellSnapshot.frame = inputView.convert(inputView.bounds, to: self.mainView)
        
        return cellSnapshot
    }
    
    // auto scroll
    func autoScrollVelocity() -> CGFloat {
        guard let snapshotView = self.cellSnapshot else { return 0 }
        
        let safeAreaFrame: CGRect
        if #available(iOS 11, *) {
            safeAreaFrame = UIEdgeInsetsInsetRect(self.frame, self.safeAreaInsets)
        } else {
            safeAreaFrame = UIEdgeInsetsInsetRect(self.frame, self.scrollIndicatorInsets)
        }
        
        let distanceToTop = max(snapshotView.frame.minY - safeAreaFrame.minY, 0)
        let distanceToBottom = max(safeAreaFrame.maxY - snapshotView.frame.maxY, 0)
        
        if distanceToTop < autoScrollThreshold {
            return mapValue(distanceToTop, inRangeWithMin: autoScrollThreshold, max: 0, toRangeWithMin: -autoScrollMinVelocity, max: -autoScrollMaxVelocity)
        }
        if distanceToBottom < autoScrollThreshold {
            return mapValue(distanceToBottom, inRangeWithMin: autoScrollThreshold, max: 0, toRangeWithMin: autoScrollMinVelocity, max: autoScrollMaxVelocity)
        }
        return 0
    }
    
    func activateAutoScrollDisplayLink() {
        autoScrollDisplayLink = CADisplayLink(target: self, selector: #selector(handleDisplayLinkUpdate))
        autoScrollDisplayLink?.add(to: RunLoop.main, forMode: RunLoopMode.defaultRunLoopMode)
        lastAutoScrollTimeStamp = nil
    }
    
    func clearAutoScrollDisplayLink() {
        autoScrollDisplayLink?.invalidate()
        autoScrollDisplayLink = nil
        lastAutoScrollTimeStamp = nil
    }
    
    @objc func handleDisplayLinkUpdate(_ displayLink: CADisplayLink) {
        
        if let lastAutoScrollTimeStamp = lastAutoScrollTimeStamp {
            let scrollVelocity = autoScrollVelocity()
            
            if scrollVelocity != 0 {
                let elapsedTime = displayLink.timestamp - lastAutoScrollTimeStamp
                let scrollDelta = CGFloat(elapsedTime) * scrollVelocity * 2
                let contentOffset = self.contentOffset
                var newOffsetY = contentOffset.y + CGFloat(scrollDelta)
                if newOffsetY <= 0 {
                    newOffsetY = 0
                }
                if newOffsetY >= self.contentSize.height - self.bounds.size.height {
                    newOffsetY = self.contentSize.height - self.bounds.size.height
                }
                self.contentOffset = CGPoint(x: contentOffset.x, y: newOffsetY)
            }
            let contentInset: UIEdgeInsets
            if #available(iOS 11, *) {
                contentInset = self.adjustedContentInset
            } else {
                contentInset = self.contentInset
            }
            
            let minContentOffset = -contentInset.top
            let maxContentOffset = self.contentSize.height - self.bounds.height + contentInset.bottom
            
            self.contentOffset.y = min(self.contentOffset.y, maxContentOffset)
            self.contentOffset.y = max(self.contentOffset.y, minContentOffset)
        }
        lastAutoScrollTimeStamp = displayLink.timestamp
    }
}
