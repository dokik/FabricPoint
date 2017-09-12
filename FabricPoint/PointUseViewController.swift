//
//  PointUseViewController.swift
//  FabricPoint
//
//  Created by doki on 2017/07/24.
//  Copyright © 2017年 RDG. All rights reserved.
//

import UIKit

class PointUseViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var delegate: ViewControllerDelegate!
    
    @IBOutlet weak var usetableview: UITableView!
    
    var useQty: [String] = ["10 pt","20 pt","50 pt","100 pt", "1000 pt"]
    var useStr: [String] = ["-10","-20","-50","-100","-1000"]
    var selectPoint: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return useQty.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.value1, reuseIdentifier: "UseCell")
        
        cell.textLabel?.text = useQty[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectPoint = useStr[indexPath.row]
    }
    
    @IBAction func pushUseButton(_ sender: UIButton) {
        print(selectPoint)
        delegate.getPoint(qrString: selectPoint)
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func pushBackButton(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
}
