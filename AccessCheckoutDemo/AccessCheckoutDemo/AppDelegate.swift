import AccessCheckoutSDK
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
//    var serviceStubs:ServiceStubs?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
//        static let DiscoveryStub = "stubDiscovery"
//        static let VerifiedTokensStub = "stubVerifiedTokens"
//        static let VerifiedTokensSessionStub = "stubVerifiedTokensSession"
//        static let CardConfigurationStub = "stubCardConfiguration"
//        static let SessionsStub = "stubSessions"
//        static let SessionsPaymentsCvcStub = "stubSessionsPaymentsCvc"
//        static let DisableStubs = "disableStubs"
//
//        static func valueOf(_ argumentName:String) -> String? {
//            return UserDefaults.standard.string(forKey: argumentName)
//        }
//
        Configuration.accessBaseUrl = Bundle.main.infoDictionary?["AccessBaseURL"] as! String
        if let enableStubsArgumentValue = UserDefaults.standard.string(forKey: "enableStubs") {
            if (enableStubsArgumentValue as NSString).boolValue {
                Configuration.accessBaseUrl = "http://localhost:8123"
            }
        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
//        serviceStubs?.stop()
//        serviceStubs = nil
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
//        serviceStubs?.start()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(_ application: UIApplication, shouldAllowExtensionPointIdentifier extensionPointIdentifier: UIApplication.ExtensionPointIdentifier) -> Bool {
        return extensionPointIdentifier != UIApplication.ExtensionPointIdentifier.keyboard
    }
}
