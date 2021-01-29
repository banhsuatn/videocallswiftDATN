import UIKit

class FriendItemCell: UITableViewCell {

    @IBOutlet weak var lbUsername: UILabel!
    @IBOutlet weak var imgCheck: UIImageView!
    @IBOutlet weak var lbStatus: UILabel!
    //green 32CD32
    //red DC143C
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
    }
    
    func initView(user: UserInfoModel, isCheck: Bool) {
        lbUsername.text = user.userName
        if user.status == 0 {
            lbStatus.text = "Online"
            lbStatus.textColor = "32CD32".hexStringToUIColor()
            imgCheck.layer.borderWidth = isCheck ? 0 : 1
            imgCheck.backgroundColor = isCheck ? .white : .clear
            imgCheck.isHidden = false
        } else {
            imgCheck.isHidden = true
            lbStatus.text = user.status == 1 ? "Call incomming" : "In call"
            lbStatus.textColor = "DC143C".hexStringToUIColor()
        }
    }
}
