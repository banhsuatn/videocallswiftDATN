
import UIKit

class HomeViewController: UIViewController {

    @IBOutlet weak var tfUsername: UITextField!
    @IBOutlet weak var viewUsername: UIView!
    @IBOutlet weak var btnLogin: UIButton!
    @IBOutlet weak var viewCallFriend: UIView!
    @IBOutlet weak var viewCallGroup: UIView!
    @IBOutlet weak var loadingView: UIActivityIndicatorView!
    
    @IBOutlet weak var lbSocketStatus: UILabel!
    @IBOutlet weak var lbLoginStatus: UILabel!
    
    var socket: SignalingSocket!
    static var user: UserInfoModel?
    var listFriends: [UserInfoModel]? {
        didSet {
            listFriends?.removeAll(where: { (user) -> Bool in
                return user.userName?.elementsEqual(tfUsername.text ?? "") ?? false
            })
        }
    }
    
    var isLoginSuccess = false {
        didSet {
            if isLoginSuccess {
                loadingView.stopAnimating()
                btnLogin.setImage(UIImage(named: "ic_btn_rename"), for: .normal)
                UIView.animate(withDuration: 0.5) {
                    self.viewUsername.backgroundColor = UIColor.white.withAlphaComponent(0.24)
                    self.viewUsername.layer.borderColor = UIColor.white.withAlphaComponent(0).cgColor
                    self.view.layoutIfNeeded()
                }
            } else {
                HomeViewController.user = nil
                loadingView.stopAnimating()
                btnLogin.setImage(UIImage(named: "ic_btn_login"), for: .normal)
                UIView.animate(withDuration: 0.5) {
                    self.viewUsername.backgroundColor = UIColor.white.withAlphaComponent(0)
                    self.viewUsername.layer.borderColor = UIColor.white.cgColor
                    self.view.layoutIfNeeded()
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //init socket
        socket = SignalingSocket(delegate: self)
    
        initView()
    }
    
    private func initView() {
        let tapCallF = UITapGestureRecognizer(target: self, action: #selector(tapViewCallFriend))
        let tapCallG = UITapGestureRecognizer(target: self, action: #selector(tapViewCallGroup))
    
        viewCallFriend.addGestureRecognizer(tapCallF)
        viewCallGroup.addGestureRecognizer(tapCallG)
    }
    
    private func changeStateView() {
        
    }
    
    @objc func tapViewCallFriend() {
        if socket.connection != nil {
            let vc = FriendsViewController.create(storyBoardName: "Main")
            vc.isMultipleSelect = false
            vc.listFriends = listFriends
            vc.socket = socket
            navigationController?.pushViewController(vc, animated: true)
        } else {
            showMessage(msg: "Bạn chưa đăng nhập vào hệ thống!")
        }
    }
    
    @objc func tapViewCallGroup() {
        if socket.connection != nil {
            let vc = FriendsViewController.create(storyBoardName: "Main")
            vc.isMultipleSelect = true
            vc.listFriends = listFriends
            vc.socket = socket
            navigationController?.pushViewController(vc, animated: true)
        } else {
            showMessage(msg: "Bạn chưa đăng nhập vào hệ thống!")
        }
    }
    
    @IBAction func actionLogin(_ sender: Any) {
        if socket.connection == nil {
            if tfUsername.text?.isEmpty ?? true {
                showMessage(msg: "Tên người dùng không được để rỗng!")
            } else {
                view.endEditing(false)
                loadingView.startAnimating()
                socket.startSocket()
            }
        } else {
            socket.connection?.cancel()
            socket.connection = nil
            tfUsername.becomeFirstResponder()
        }
    }
}

extension HomeViewController: SignalingSocketDelegate {
    func didSendMessage(isSuccess: Bool) {
        DispatchQueue.main.async {
            
        }
    }
    
    func didReciveMessage(response: ResponseModel) {
        DispatchQueue.main.async {
            switch response.signalKey {
            case "LOGIN_RES":
                guard let res = try? JSONDecoder().decode(ResponseInfoModel<String>.self, from: response.data) else { return }
                if res.data?.isEmpty ?? false {
                    self.isLoginSuccess = true

                    self.lbLoginStatus.alpha = 1
                    self.lbLoginStatus.text = "Login success"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        UIView.animate(withDuration: 1) {
                            self.lbLoginStatus.alpha = 0
                            self.view.layoutIfNeeded()
                        }
                    }
                } else {
                    self.showMessage(msg: res.data ?? "Some thing error!")
                    self.isLoginSuccess = false
                }
                break
            case "LIST_USER":
                guard let res = try? JSONDecoder().decode(ResponseInfoModel<[UserInfoModel]>.self, from: response.data) else { return }
                self.listFriends = res.data
                if let vc = self.navigationController?.viewControllers.first(where: { (vc) -> Bool in
                    return vc is FriendsViewController
                }) as? FriendsViewController {
                    vc.listFriends = self.listFriends
                }
                if let user = res.data?.first(where: { (info) -> Bool in
                    return info.userName?.elementsEqual(HomeViewController.user?.userName ?? "") ?? false
                }) {
                    HomeViewController.user = user
                }
                if let vc = self.navigationController?.viewControllers.first(where: { (vc) -> Bool in
                    return vc is ViewController
                }) as? ViewController {
                    vc.reloadVideo(listFriends: self.listFriends ?? [])
                }
                break
            case "CALL_REQUEST":
                guard let res = try? JSONDecoder().decode(ResponseInfoModel<[String]>.self, from: response.data) else { return }
                let vc = CallRequestViewController.create(storyBoardName: "Main")
                vc.socket = self.socket
                vc.usernames = res.data
                self.navigationController?.pushViewController(vc, animated: true)
                break
            default:
                break
            }
        }
    }
    
    func socketConnected() {
        DispatchQueue.main.async {
            HomeViewController.user = UserInfoModel(userName: self.tfUsername.text ?? "", os: "IOS", isWifi: true, status: 0)
            self.socket.sendMessage(message: VideoCallCommand.SHARE.login(user: HomeViewController.user!))
            self.lbSocketStatus.alpha = 1
            self.lbSocketStatus.text = "Socket connected"
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            UIView.animate(withDuration: 1) {
                self.lbSocketStatus.alpha = 0
                self.view.layoutIfNeeded()
            }
        }
    }
    
    func socketDisconnected(with error: String?) {
        DispatchQueue.main.async {
            self.lbSocketStatus.alpha = 1
            self.lbSocketStatus.text = "Socket disconnected"
            self.isLoginSuccess = false
            if !(error?.isEmpty ?? false) {
                self.showMessage(msg: error ?? "Some thing error!")
            }
            self.navigationController?.popToRootViewController(animated: true)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            UIView.animate(withDuration: 1) {
                self.lbSocketStatus.alpha = 0
                self.view.layoutIfNeeded()
            }
        }
    }
}
