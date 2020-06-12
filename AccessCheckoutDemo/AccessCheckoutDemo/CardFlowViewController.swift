import AccessCheckoutSDK
import UIKit

class CardFlowViewController: UIViewController {
    @IBOutlet weak var panView: PANView!
    @IBOutlet weak var expiryDateView: ExpiryDateView!
    @IBOutlet weak var cvvView: CVVView!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var paymentsCvcSessionToggle: UISwitch!
    
    private let unknownBrandImage = UIImage(named: "card_unknown")
    
    @IBAction func submit(_ sender: Any) {
        guard let pan = panView.text,
            let month = expiryDateView.month,
            let year = expiryDateView.year,
            let cvv = cvvView.text else {
            return
        }
        submitCard(pan: pan, month: month, year: year, cvv: cvv)
    }
    
    private func submitCard(pan: PAN, month: ExpiryMonth, year: ExpiryYear, cvv: CVV) {
        guard let expiryMonth = UInt(month), let expiryYear = year.toFourDigitFormat() else {
            return
        }
        
        submitButton.isEnabled = false
        spinner.startAnimating()
        
        let sessionTypes: Set<SessionType> = paymentsCvcSessionToggle.isOn ? [SessionType.verifiedTokens, SessionType.paymentsCvc] : [SessionType.verifiedTokens]
        
        let cardDetails = CardDetailsBuilder().pan(pan)
            .expiryDate(month: expiryMonth.description, year: expiryYear.description)
            .cvv(cvv)
            .build()
        
        let accessBaseUrl = Bundle.main.infoDictionary?["AccessBaseURL"] as! String
        let accessCheckoutClient = try? AccessCheckoutClientBuilder().accessBaseUrl(accessBaseUrl)
            .merchantId(CI.merchantId)
            .build()
        
        try? accessCheckoutClient?.generateSessions(cardDetails: cardDetails, sessionTypes: sessionTypes) { result in
            DispatchQueue.main.async {
                self.spinner.stopAnimating()
                
                switch result {
                case .success(let sessions):
                    var titleToDisplay: String, messageToDisplay: String
                    
                    if sessionTypes.count > 1 {
                        titleToDisplay = "Verified Tokens & Payments CVC Sessions"
                        messageToDisplay = """
                        \(sessions[SessionType.verifiedTokens]!)
                        \(sessions[SessionType.paymentsCvc]!)
                        """
                    } else {
                        titleToDisplay = "Verified Tokens Session"
                        messageToDisplay = "\(sessions[SessionType.verifiedTokens]!)"
                    }
                    
                    AlertView.display(using: self, title: titleToDisplay, message: messageToDisplay, closeHandler: {
                        self.resetCard(preserveContent: false, validationErrors: nil)
                    })
                case .failure(let error):
                    let title = error.localizedDescription
                    var accessCheckoutClientValidationErrors: [AccessCheckoutClientValidationError]?
                    switch error {
                    case .bodyDoesNotMatchSchema(_, let validationErrors):
                        accessCheckoutClientValidationErrors = validationErrors
                    default:
                        break
                    }
                    
                    AlertView.display(using: self, title: title, message: nil, closeHandler: {
                        self.resetCard(preserveContent: true, validationErrors: accessCheckoutClientValidationErrors)
                    })
                }
            }
        }
    }
    
    private func resetCard(preserveContent: Bool, validationErrors: [AccessCheckoutClientValidationError]?) {
        if !preserveContent {
            panView.clear()
            expiryDateView.clear()
            cvvView.clear()
        }
        
        validationErrors?.forEach { error in
            switch error {
            case .panFailedLuhnCheck:
                panView?.isValid(valid: false)
            case .dateHasInvalidFormat(_, let jsonPath):
                switch jsonPath {
                case "$.cardNumber":
                    panView?.isValid(valid: false)
                case "$.cardExpiryDate.month":
                    expiryDateView.isValid(valid: false)
                case "$.cardExpiryDate.year":
                    expiryDateView.isValid(valid: false)
                case "$.cvv":
                    cvvView.isValid(valid: false)
                default:
                    print("Unrecognized jsonPath")
                }
            default:
                break
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        panView.layer.borderWidth = 1
        panView.layer.borderColor = UIColor.lightText.cgColor
        panView.layer.cornerRadius = 8
        
        expiryDateView.layer.borderWidth = 1
        expiryDateView.layer.borderColor = UIColor.lightText.cgColor
        expiryDateView.layer.cornerRadius = 8
        
        cvvView.layer.borderWidth = 1
        cvvView.layer.borderColor = UIColor.lightText.cgColor
        cvvView.layer.cornerRadius = 8
        
        resetCard(preserveContent: false, validationErrors: nil)
        
        let validationConfig = CardValidationConfig(panView: panView,
                                                    expiryDateView: expiryDateView,
                                                    cvvView: cvvView,
                                                    accessBaseUrl: "https://try.access.worldpay.com",
                                                    validationDelegate: self)
        
        AccessCheckoutValidationInitialiser().initialise(validationConfig)
        
        panValidChanged(isValid: false)
        expiryDateValidChanged(isValid: false)
        cvvValidChanged(isValid: false)
        cardBrandChanged(cardBrand: nil)
    }
    
    private func updateCardBrandImage(url: URL) {
        DispatchQueue.global(qos: .userInteractive).async {
            if let data = try? Data(contentsOf: url) {
                DispatchQueue.main.async {
                    self.panView.imageView.image = UIImage(data: data)
                }
            }
        }
    }
}

extension CardFlowViewController: AccessCheckoutCardValidationDelegate {
    func cardBrandChanged(cardBrand: CardBrandClient?) {
        if let imageUrl = cardBrand?.images.filter({ $0.type == "image/png" }).first?.url,
            let url = URL(string: imageUrl) {
            updateCardBrandImage(url: url)
        } else {
            panView.imageView.image = unknownBrandImage
        }
        panView.imageView.accessibilityLabel = NSLocalizedString(cardBrand?.name ?? "unknown_card_brand", comment: "")
    }
    
    func panValidChanged(isValid: Bool) {
        panView.isValid(valid: isValid)
        submitButton.isEnabled = false
    }
    
    func cvvValidChanged(isValid: Bool) {
        cvvView.isValid(valid: isValid)
        submitButton.isEnabled = false
    }
    
    func expiryDateValidChanged(isValid: Bool) {
        expiryDateView.isValid(valid: isValid)
        submitButton.isEnabled = false
    }
    
    func validationSuccess() {
        submitButton.isEnabled = true
    }
}
