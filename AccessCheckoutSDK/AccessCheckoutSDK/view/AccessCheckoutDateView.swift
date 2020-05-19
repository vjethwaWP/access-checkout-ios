/// A view representing a date field
public protocol AccessCheckoutDateView: AccessCheckoutView {
    
    /// The date's month
    var month: String? { get }
    
    /// The date's year
    var year: String? { get }
}
