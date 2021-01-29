import UIKit

class CallRequestViewController: UIViewController {

    @IBOutlet weak var lbUsernames: UILabel!
    
    var socket: SignalingSocket!
    var usernames: [String]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        for i in usernames ?? [] {
            if !i.elementsEqual(HomeViewController.user?.userName ?? "") {
                lbUsernames.text = "\(lbUsernames.text ?? "")\n\(i)"
            }
        }
        lbUsernames.text = lbUsernames.text?.trimmingCharacters(in: .newlines)
    }
    
    @IBAction func actionAccept(_ sender: Any) {
        socket.sendMessage(message: VideoCallCommand.SHARE.callResponse(isAccept: true))
        let vc = ViewController.create(storyBoardName: "Main")
        self.navigationController?.pushViewController(vc, animated: true)
    }
    @IBAction func actionReject(_ sender: Any) {
        socket.sendMessage(message: VideoCallCommand.SHARE.callResponse(isAccept: false))
        self.navigationController?.popViewController(animated: true)
    }
}
