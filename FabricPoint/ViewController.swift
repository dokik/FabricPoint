//
//  ViewController.swift
//  FabricPoint
//
//  Created by doki on 2017/07/13.
//  Copyright © 2017年 RDG. All rights reserved.
//

import UIKit

protocol ViewControllerDelegate {
    func getPoint(qrString: String)
}

class ViewController: UIViewController, ViewControllerDelegate, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var userNameField: UITextField!
    @IBOutlet weak var passField: UITextField!
    
    @IBOutlet weak var loginUserLbl: UILabel!
    @IBOutlet weak var loginStatusLbl: UILabel!
    @IBOutlet weak var pointLbl: UILabel!
    @IBOutlet weak var getPointLbl: UILabel!
    
    @IBOutlet weak var getPointButton: UIButton!
    @IBOutlet weak var usePointButton: UIButton!
    @IBOutlet weak var refreshButton: UIButton!
    
    @IBOutlet weak var tableScale: UIButton!
    
    @IBOutlet weak var tableonview: UIView!
    @IBOutlet weak var tableview: UITableView!
    
    
    var url: String = ""
    //    let url_host: String = "http://localhost:5000/"
//    let url_host: String = "http://172.16.16.22:5000/"
    let url_host: String = "http://172.22.68.165:5000/"
    var ccId: String = ""
    
    var login_user: String = ""
    
    let user_name: String = "test_user0"
    let password: String = "MS9qrN8hFjlE"
    
    var pointInfo = NSDictionary()
    
    var tableFrame = CGRect()
    var tableviewFrame = CGRect()
    
    var logflg: Bool = false
    var logstart: Bool = true
    
    var blockNum: Int = 1
    var chainHeight: Int = 0
    
    var logArray = [NSDictionary]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        logflg = false
        tableFrame = tableonview.frame
        tableviewFrame = tableview.frame
        
        loginUserLbl.text = ""
        loginStatusLbl.isHidden = true
        getPointLbl.text = ""
        
        getPointButton.isEnabled = false
        usePointButton.isEnabled = false
        
        initLogin()
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if login_user != "" {
            if segue.identifier == "gocamera" {
                let destination = segue.destination as! CameraViewController
                destination.delegate = self
            } else if segue.identifier == "gousepoint" {
                let destination = segue.destination as! PointUseViewController
                destination.delegate = self
            }
        } else {
            return
        }
    }
    
    func initLogin() {
        url = url_host + "registrar"
        
        let JSONdata = [
            "enrollId": user_name,
            "enrollSecret": password
        ]
        
        var dataJson = Data()
        
        do {
            dataJson = try JSONSerialization.data(withJSONObject: JSONdata, options: [])
        } catch {
            print("Error!: \(error)")
            self.login_user = ""
        }
        
        executeJsonRpc(url_exec: url, JSONdata: dataJson) {
            (data, response, error) in
            if error != nil {
                print("login error")
            } else {
                print("login success")
                self.initDeploy()
            }
        }
    }
    
    func initDeploy() {
//        url = url_host + "chaincode";
//        let JSONdata = createJSONdataForPointApp(method: "deploy", functionName: "init", args: [], id: 1)
        
        url = url_host + "chaincode";
        let JSONdata = createJSONdataForPointApp(method: "deploy", functionName: "get_all", args: ["dd8f70b11c9a216344acbe681936ee3eec586d11180ed7e26663dccd6da3d395883503298a27bd5406d7570c6a1ea3ab9789b37da9674c1cb00ad0da5433b2e4"], id: 1)
        
        executeJsonRpc(url_exec: url, JSONdata: JSONdata) {
            (data, response, error) in
            if error != nil {
                print("deploy error")
            } else {
                do {
                    let resjson = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
                    let result = resjson?["result"] as? [String: Any]
                    self.ccId = result?["message"] as! String
                } catch {
                    print("json error")
                    return
                }
                print(self.ccId)
                print("deploy success!")
            }
        }
    }
    
    func getInfo() {
        url = url_host + "chaincode"
        let userName: String = userNameField.text!
        let userPass: String = passField.text!
        let JSONData = createJSONdataForPointApp(method: "query", functionName: "refresh", args: [userName, userPass], id: 5)
        executeJsonRpc(url_exec: url, JSONdata: JSONData) {
            (data, response, error) in
            if error != nil {
                print("refresh error")
                self.login_user = ""
            } else {
                do {
                    let resjson = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
                    if resjson?["error"] != nil {
                        DispatchQueue.main.async {
                            self.dispAlert(title: "ログインエラー", message: "ユーザー名、もしくはパスワードが間違っています。")
                            self.getPointButton.isEnabled = false
                        }
                        self.login_user = ""
                    } else {
                        let result = resjson?["result"] as? [String: Any]
                        let resmessage = result?["message"] as! String
                        let jsonData = resmessage.data(using: String.Encoding.utf8)
                        self.pointInfo = try JSONSerialization.jsonObject(with: jsonData!, options: []) as! NSDictionary
                        DispatchQueue.main.async {
                            self.pointLbl.text = String(describing: self.pointInfo["Point"]!)
                            self.getPointButton.isEnabled = true
                            self.usePointButton.isEnabled = true
                            self.login_user = userName
                            self.loginUserLbl.text = userName
                            self.loginStatusLbl.isHidden = false
                        }
                    }
                } catch {
                    print("json error")
                    self.login_user = ""
                    return
                }
            }
        }
    }
    
    func checkUser() {
        url = url_host + "chaincode"
        let checkName: String = userNameField.text!
        let checkPass: String = passField.text!
        let JSONData = createJSONdataForPointApp(method: "query", functionName: "refresh", args: [checkName, checkPass], id: 5)
        executeJsonRpc(url_exec: url, JSONdata: JSONData) {
            (data, response, error) in
            if error != nil {
                print("check error")
            } else {
                do {
                    let resjson = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
                    if resjson?["error"] != nil {
                        if String(describing: resjson?["error"]!).contains("Pass error") {
                            DispatchQueue.main.async {
                                self.dispAlert(title: "登録エラー", message: "同名のユーザーが既に存在します。")
                                return
                            }
                        }
                        self.addUser(userName: checkName, userPass: checkPass)
                    } else {
                        DispatchQueue.main.async {
                            self.dispAlert(title: "登録エラー", message: "同名のユーザーが既に存在します。")
                            return
                        }
                    }
                } catch {
                    print("json error")
                    return
                }
            }
        }
    }
    
    func addUser(userName: String, userPass: String) {
        url = url_host + "chaincode"
        let JSONData = createJSONdataForPointApp(method: "invoke", functionName: "add", args: [userName, userPass], id: 6)
        executeJsonRpc(url_exec: url, JSONdata: JSONData) {
            (data, response, error) in
            if error != nil {
                print("add error")
                self.login_user = ""
            } else {
                do {
                    let resjson = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
                    if resjson?["error"] != nil {
                        DispatchQueue.main.async {
                            self.dispAlert(title: "登録エラー", message: "同名のユーザーが既に存在します。")
                            self.getPointButton.isEnabled = false
                        }
                        self.login_user = ""
                    } else {
                        print("add success!")
                        self.login_user = userName
                        self.getInfo()
                    }
                } catch {
                    print("json error")
                    self.login_user = ""
                    return
                }
            }
        }
    }
    
    func getPoint(qrString: String) {
        print(qrString)
        url = url_host + "chaincode"
        if login_user != "" {
            let JSONdata = createJSONdataForPointApp(method: "invoke", functionName: "pointUp", args: [login_user, qrString], id: 3)
            executeJsonRpc(url_exec: url, JSONdata: JSONdata) {
                (data, responce, error) in
                if error != nil {
                    print("pointup error")
                } else {
                    print("pointup success!")
                    DispatchQueue.main.async {
                        if Int(qrString)! >= 0 {
                            self.getPointLbl.text = "+\(qrString) pt"
                        } else {
                            self.getPointLbl.text = "\(qrString) pt"
                        }
                    }
                    self.getInfo()
                }
            }
        } else {
            print("error")
        }
    }
    
    func createJSONdataForPointApp(method: String, functionName: String, args: [String], id: Int) -> Data {
        var jsonObj = Dictionary<String, Any>()
        jsonObj["jsonrpc"] = "2.0"
        jsonObj["method"] = method
        jsonObj["id"] = id
        
        var ctorData = Dictionary<String,Any>()
        ctorData["function"] = functionName
        ctorData["args"] = args
        
        var paramsData = Dictionary<String,Any>()
        paramsData["type"] = 1
        paramsData["ctorMsg"] = ctorData
        paramsData["secureContext"] = user_name
        
        var ccIdData = Dictionary<String,Any>()
        
        if functionName == "init" || functionName == "get_all" {
            ccIdData["path"] = "github.com/hyperledger/fabric/examples/chaincode/go/lib_userpoint"
        } else {
            ccIdData["name"] = ccId
        }
        
        paramsData["chaincodeID"] = ccIdData
        jsonObj["params"] = paramsData
        
        var dataJson: Data = Data()
        
        do {
            dataJson = try JSONSerialization.data(withJSONObject: jsonObj, options: [])
        } catch {
            print("Error!: \(error)")
            self.login_user = ""
        }
        
        return dataJson
    }
    
    func executeJsonRpc(url_exec: String, JSONdata: Data, callback: @escaping (Data?, URLResponse?, Error?) -> Void) {
        let requrl = URL(string: url_exec)
        var request = URLRequest(url: requrl!)
        request.httpMethod = "POST"
        request.httpBody = JSONdata
        request.addValue("application/JSON", forHTTPHeaderField: "Content-Type")
        request.addValue("dataType", forHTTPHeaderField: "JSON")
        request.addValue("scriptCharset", forHTTPHeaderField: "utf-8")
        
        let task = URLSession.shared.dataTask(with: request) {
            (data, response, error) in
            callback(data, response, error)
        }
        task.resume()
    }
    
    func getChainInfo(callback: @escaping (Data?, URLResponse?, Error?) -> Void) {
        let url_ccInfo = url_host + "chain"
        let requrl = URL(string: url_ccInfo)
        var request = URLRequest(url: requrl!)
        request.httpMethod = "GET"
        request.addValue("application/JSON", forHTTPHeaderField: "Content-Type")
        request.addValue("dataType", forHTTPHeaderField: "JSON")
        request.addValue("scriptCharset", forHTTPHeaderField: "utf-8")
        
        let task = URLSession.shared.dataTask(with: request) {
            (data, response, error) in
            callback(data, response, error)
        }
        task.resume()
    }
    
    func getBlockInfo() {
        executeJsonGetRpc() {
            (data, response, error) in
            if error != nil {
                print("getlog error")
            } else {
                print("getlog success! \(self.blockNum)")
                do {
                    let resjson = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
                    
                    if resjson?["error"] != nil {
                        DispatchQueue.main.async {
                            self.dispAlert(title: "取得エラー", message: "ブロックがない、もしくは取得に失敗しました。")
                            self.getPointButton.isEnabled = false
                        }
                        //                                                self.login_user = ""
                    } else {
                        let restran = resjson?["transactions"] as? [[String: Any]]
                        let restime = restran?[0]["timestamp"] as? [String: Int]
                        
//                        let resPay = restran?[0]["payload"] as? String
//                        let dataPay = Data(base64Encoded: resPay!)
//                        print(dataPay)
//                        let dicPay = String(data: dataPay!, encoding: .utf8)
//                        print(dicPay)
                        
                        
                        let dicBlockNum = self.blockNum
                        //                            let dicTimeStamp = Date(timeIntervalSince1970: TimeInterval(Double((restime?["seconds"])!) * 1000))
                        let dicTimeStamp = Date(timeIntervalSince1970: TimeInterval(Double((restime?["seconds"])!)))
                        let dicPreBlockHash = resjson?["previousBlockHash"] as! String
                        let dicNonce = restran?[0]["nonce"] as! String
                        
                        let logList: NSDictionary = ["blocknum": dicBlockNum, "timestamp": dicTimeStamp, "previousblockhash": dicPreBlockHash, "nonce": dicNonce]
//                        let logList: NSDictionary = ["blocknum": dicBlockNum, "timestamp": dicTimeStamp, "payload": dicPay, "nonce": "non"]
                        
//                        self.logArray.append(logList)
                        self.logArray.insert(logList, at: 0)
                        self.blockNum = self.blockNum + 1
                        
                        if self.chainHeight != self.blockNum {
                            self.getBlockInfo()
                        } else {
                            DispatchQueue.main.async {
                                self.tableview.reloadData()
                                self.refreshButton.isEnabled = true
                            }
                            return
                        }
                    }
                } catch {
                    print("json error")
                    //                    self.login_user = ""
                    return
                }
                
            }
        }
    }
    
    func executeJsonGetRpc(callback: @escaping (Data?, URLResponse?, Error?) -> Void) {
        let url_prefix = url_host + "chain/blocks/"
        let requrl = URL(string: url_prefix + String(describing: blockNum))
        var request = URLRequest(url: requrl!)
        request.httpMethod = "GET"
        request.addValue("application/JSON", forHTTPHeaderField: "Content-Type")
        request.addValue("dataType", forHTTPHeaderField: "JSON")
        request.addValue("scriptCharset", forHTTPHeaderField: "utf-8")
        
        let task = URLSession.shared.dataTask(with: request) {
            (data, response, error) in
            callback(data, response, error)
        }
        task.resume()
    }
    
    // ボタンを押下した時にアラートを表示するメソッド
    func dispAlert(title: String, message: String) {
        
        // ① UIAlertControllerクラスのインスタンスを生成
        // タイトル, メッセージ, Alertのスタイルを指定する
        // 第3引数のpreferredStyleでアラートの表示スタイルを指定する
        let alert: UIAlertController = UIAlertController(title: title, message: message, preferredStyle:  UIAlertControllerStyle.alert)
        
        // ② Actionの設定
        // Action初期化時にタイトル, スタイル, 押された時に実行されるハンドラを指定する
        // 第3引数のUIAlertActionStyleでボタンのスタイルを指定する
        // OKボタン
        let defaultAction: UIAlertAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler:{
            // ボタンが押された時の処理を書く（クロージャ実装）
            (action: UIAlertAction!) -> Void in
            print("OK")
        })
        // キャンセルボタン
        //        let cancelAction: UIAlertAction = UIAlertAction(title: "キャンセル", style: UIAlertActionStyle.cancel, handler:{
        //            // ボタンが押された時の処理を書く（クロージャ実装）
        //            (action: UIAlertAction!) -> Void in
        //            print("Cancel")
        //        })
        
        // ③ UIAlertControllerにActionを追加
        //        alert.addAction(cancelAction)
        alert.addAction(defaultAction)
        
        // ④ Alertを表示
        present(alert, animated: true, completion: nil)
    }
    
    
    @IBAction func pushLogin(_ sender: UIButton) {
        getPointLbl.text = ""
        getInfo()
    }
    
    @IBAction func pushNewAccount(_ sender: UIButton) {
        getPointLbl.text = ""
//        addUser()
        checkUser()
    }
    
    //    @IBAction func pushGetPoint(_ sender: UIButton) {
    //        url = url_host + "chaincode"
    //        if userNameField.text != nil {
    //            let JSONdata = createJSONdataForPointApp(method: "invoke", functionName: "pointUp", args: [userNameField.text!], id: 3)
    //            executeJsonRpc(url_exec: url, JSONdata: JSONdata) {
    //                (data, responce, error) in
    //                if error != nil {
    //                    print("pointup error")
    //                } else {
    //                    print("pointup success!")
    //                }
    //            }
    //        }
    //    }
    
    @IBAction func tapView(_ sender: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
    
    
    @IBAction func tableWide(_ sender: UIButton) {
        if logflg == false {
            UIView.animate(withDuration: 0.5, animations: {
                () in
                let statusBarHeight = UIApplication.shared.statusBarFrame.size.height
                self.tableonview.frame = CGRect(origin: CGPoint(x: 0, y: statusBarHeight), size: CGSize(width: self.view.frame.size.width, height:self.view.frame.size.height-statusBarHeight))
                self.tableview.frame = CGRect(origin: CGPoint(x: 0, y: self.tableviewFrame.origin.y), size: CGSize(width: self.tableonview.frame.size.width, height:self.tableonview.frame.size.height-self.tableviewFrame.origin.y))
            })
            tableScale.setTitle("縮小", for: .normal)
            logflg = true
        } else {
            UIView.animate(withDuration: 0.5, animations: {
                () in
                self.tableonview.frame = self.tableFrame
                self.tableview.frame = self.tableviewFrame
            })
            tableScale.setTitle("展開", for: .normal)
            logflg = false
        }
    }
    
    @IBAction func startLog(_ sender: UIButton) {
        logstart = false
        refreshButton.isEnabled = false
        getChainInfo() {
            (data, response, error) in
            if error != nil {
                print("getchain error")
            } else {
                print("getchain success!")
                do {
                    let resjson = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
                    if resjson?["error"] != nil {
                        DispatchQueue.main.async {
                            self.dispAlert(title: "取得エラー", message: "チェーンがない、もしくは取得に失敗しました。")
                        }
                        self.chainHeight = 0
                    } else {
                        self.chainHeight = resjson?["height"] as! Int
                        
                        if self.chainHeight - 50 > 0 {
                            self.blockNum = self.chainHeight - 50
                        }
                        //                        for _ in 0...self.chainHeight {
                        if self.chainHeight != self.blockNum {
                            self.getBlockInfo()
                        }
                    }
                } catch {
                    print("json error")
                    //                    self.login_user = ""
                    return
                }
            }
            DispatchQueue.main.async {
                self.refreshButton.isEnabled = true
            }
        }
        
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return logArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.subtitle, reuseIdentifier: "Cell")
        cell.textLabel?.text = "\(String(describing: logArray[indexPath.row]["blocknum"]!)), \(String(describing: logArray[indexPath.row]["previousblockhash"]!))"
        cell.detailTextLabel?.text = "\(String(describing: logArray[indexPath.row]["timestamp"]!)), \(String(describing: logArray[indexPath.row]["nonce"]!))"
        return cell
    }
    
}

