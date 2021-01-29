
import UIKit
import SVProgressHUD

class FriendsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var socket: SignalingSocket!
    var listFriends: [UserInfoModel]? {
        didSet {
            for i in listFriends ?? [] {
                if listCheck.contains(i.userName ?? "") && i.status != 0 {
                    listCheck.removeAll { (str) -> Bool in
                        return str.elementsEqual(i.userName ?? "")
                    }
                }
            }
            if tableView != nil {
                tableView.reloadData()
            }
            listCheck.removeAll { (str) -> Bool in
                return !(listFriends?.contains(where: { (user) -> Bool in
                    return user.userName?.elementsEqual(str) ?? false
                }) ?? false)
            }
        }
    }
    var isMultipleSelect = false
    var listCheck = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UINib(nibName: "FriendItemCell", bundle: nil), forCellReuseIdentifier: "FriendItemCell")
        tableView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 100, right: 0)
    }
    
    private func initView() {
        
    }
    
    @IBAction func actionDismiss(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    @IBAction func btnOk(_ sender: Any) {
        if listCheck.isEmpty {
            showMessage(msg: "Hãy chọn \(isMultipleSelect ? "ít nhất " : "")một người bạn!", isError: false)
        } else {
            socket.sendMessage(message: VideoCallCommand.SHARE.callRequest(list: listCheck))
            let vc = ViewController.create(storyBoardName: "Main")
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
}

extension FriendsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        listFriends?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FriendItemCell", for: indexPath) as! FriendItemCell
        if let listFriends = listFriends {
            let user = listFriends[indexPath.row]
            cell.initView(user: user, isCheck: listCheck.contains(user.userName ?? ""))
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        68
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let listFriends = listFriends {
            let user = listFriends[indexPath.row]
            if user.status == 0 {
                if isMultipleSelect {
                    if listCheck.contains(user.userName ?? "") {
                        listCheck.removeAll { (str) -> Bool in
                            return user.userName?.elementsEqual(str) ?? false
                        }
                    } else {
                        listCheck.append(user.userName ?? "")
                    }
                } else {
                    if listCheck.contains(user.userName ?? "") {
                        listCheck.removeAll()
                    } else {
                        listCheck.removeAll()
                        listCheck.append(user.userName ?? "")
                    }
                }
                tableView.reloadData()
            }
        }
    }
}
