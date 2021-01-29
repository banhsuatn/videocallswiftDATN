
import Foundation
import UIKit

class PeerItemCell: UIView {
    
    var user: UserInfoModel?
    var image: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        image = UIImageView(frame: frame)
        addSubview(image)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
