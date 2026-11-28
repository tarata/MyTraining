import SwiftUI
import WebKit
import UniformTypeIdentifiers
import UserNotifications
@main struct RUOSSApp: App {
 var body: some Scene { WindowGroup { TrainingView().ignoresSafeArea(.keyboard, edges: .bottom) } }
}
struct TrainingView: UIViewControllerRepresentable {
 func makeUIViewController(context: Context) -> TrainingController { TrainingController() }
 func updateUIViewController(_ uiViewController: TrainingController, context: Context) {}
}
final class TrainingController: UIViewController, WKScriptMessageHandler, UIDocumentPickerDelegate {
 var web: WKWebView!
 override func viewDidLoad() {
  super.viewDidLoad()
  let config = WKWebViewConfiguration()
  config.userContentController.add(self, name: "native")
  web = WKWebView(frame: .zero, configuration: config)
  web.translatesAutoresizingMaskIntoConstraints = false
  view.addSubview(web)
  NSLayoutConstraint.activate([web.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),web.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),web.leadingAnchor.constraint(equalTo: view.leadingAnchor),web.trailingAnchor.constraint(equalTo: view.trailingAnchor)])
  if let url = Bundle.main.url(forResource:"index",withExtension:"html") { web.loadFileURL(url, allowingReadAccessTo:url.deletingLastPathComponent()) }
  UNUserNotificationCenter.current().requestAuthorization(options:[.alert,.sound,.badge]) { _,_ in }
 }
 func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
  guard let m = message.body as? [String:Any], let action = m["action"] as? String else { return }
  switch action {
  case "donate": if let url = URL(string:"https://www.paypal.com/donate/?hosted_button_id=2HFNF4PJNC7DG") { UIApplication.shared.open(url) }
  case "cancel": UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers:["rest"])
  case "rest":
   UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers:["rest"])
   let content = UNMutableNotificationContent(); content.title = "RUOSS"; content.body = "Recupero terminato: " + (m["name"] as? String ?? ""); content.sound = .default
   let delay = max(1,(m["end"] as? Double ?? 0)/1000-Date().timeIntervalSince1970)
   UNUserNotificationCenter.current().add(UNNotificationRequest(identifier:"rest",content:content,trigger:UNTimeIntervalNotificationTrigger(timeInterval:delay,repeats:false)))
  case "pick":
   let picker = UIDocumentPickerViewController(forOpeningContentTypes:[.json],asCopy:true); picker.delegate = self; present(picker,animated:true)
  case "save","share":
   guard let name = m["name"] as? String, let data = m["data"] as? String else { return }
   let url = FileManager.default.temporaryDirectory.appendingPathComponent(URL(fileURLWithPath:name).lastPathComponent)
   do { try data.write(to:url,atomically:true,encoding:.utf8)
    if action == "save" { present(UIDocumentPickerViewController(forExporting:[url],asCopy:true),animated:true) }
    else { let share = UIActivityViewController(activityItems:[url],applicationActivities:nil); share.popoverPresentationController?.sourceView = view; share.popoverPresentationController?.sourceRect = CGRect(x:view.bounds.midX,y:view.bounds.midY,width:1,height:1); present(share,animated:true) }
   } catch { let alert = UIAlertController(title:"RUOSS",message:error.localizedDescription,preferredStyle:.alert); alert.addAction(UIAlertAction(title:"OK",style:.default)); present(alert,animated:true) }
  default: break
  }
 }
 func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls:[URL]) {
  guard let url = urls.first, let data = try? Data(contentsOf:url), data.count < 1000000, let raw = String(data:data,encoding:.utf8), let encoded = try? JSONEncoder().encode(raw), let literal = String(data:encoded,encoding:.utf8) else { return }
  web.evaluateJavaScript("importPlan("+literal+")")
 }
}
