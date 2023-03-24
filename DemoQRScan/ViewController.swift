import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    @IBOutlet weak var scanBtn: UIButton!
    
    @IBOutlet weak var createBtn: UIButton!
    
    @IBOutlet weak var textfield: UITextField!
    
    @IBOutlet weak var qrRendered: UIImageView!
    
    @IBOutlet weak var saveBtn: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        saveBtn.isHidden = true
    }
    
    @IBAction func createQR(_ sender: Any) {
        saveBtn.isHidden = true
        guard let content = self.textfield.text else {return}
        guard let qrURLImage = URL(string: content)?.qrImage(using: .black, logo: UIImage(named: "haha")) else {return}
        qrRendered.image = qrURLImage
        saveBtn.isHidden = false
    }
    
    func genQRCode(from input: String) -> UIImage? {

        let data = input.data(using: String.Encoding.ascii)

        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 1, y: 1)

            if let output = filter.outputImage?.transformed(by: transform) {
                return UIImage(ciImage: output)
            }
            
        }
        
        return nil
    }
    
    @IBAction func saveQR(_ sender: Any) {
        takeScreenshot()
    }
    
    open func takeScreenshot(_ shouldSave: Bool = true) {
        var screenshotImage: UIImage?
        let layer = qrRendered.layer
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(layer.frame.size, false, scale);
        guard let context = UIGraphicsGetCurrentContext() else {return}
        layer.render(in:context)
        screenshotImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        if let image = screenshotImage, shouldSave {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        }
//        return screenshotImage
    }
    
    @IBAction func scanQR(_ sender: Any) {
        checkPermission()
        let scanVC = QRScanViewController()
        self.navigationController?.pushViewController(scanVC, animated: false)
    }
    
    func checkPermission() {
        //Camera
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { response in
            if response {
                //access granted
            } else {
                
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.textfield.endEditing(true)
    }
}

extension URL {

   /// Creates a QR code for the current URL in the given color.
   func qrImage(using color: UIColor, logo: UIImage? = nil) -> UIImage? {
       logo
      guard let tintedQRImage = qrImage?.tinted(using: color) else {
         return nil
      }
    
      guard let logo = logo?.cgImage else {
         return UIImage(ciImage: tintedQRImage)
      }
    
      guard let final = tintedQRImage.combined(with: CIImage(cgImage: logo)) else {
        return UIImage(ciImage: tintedQRImage)
      }
    
    return UIImage(ciImage: final)
  }

  /// Returns a black and white QR code for this URL.
  var qrImage: CIImage? {
    guard let qrFilter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
    let qrData = absoluteString.data(using: String.Encoding.ascii)
    qrFilter.setValue(qrData, forKey: "inputMessage")
    
    let qrTransform = CGAffineTransform(scaleX: 12, y: 12)
      
    return qrFilter.outputImage?.transformed(by: qrTransform)
  }
}

extension CIImage {
  /// Inverts the colors and creates a transparent image by converting the mask to alpha.
  /// Input image should be black and white.
  var transparent: CIImage? {
     return inverted?.blackTransparent
  }

  /// Inverts the colors.
  var inverted: CIImage? {
      guard let invertedColorFilter = CIFilter(name: "CIColorInvert") else { return nil }
    
    invertedColorFilter.setValue(self, forKey: "inputImage")
    return invertedColorFilter.outputImage
  }

  /// Converts all black to transparent.
  var blackTransparent: CIImage? {
      guard let blackTransparentFilter = CIFilter(name: "CIMaskToAlpha") else { return nil }
    blackTransparentFilter.setValue(self, forKey: "inputImage")
    return blackTransparentFilter.outputImage
  }

  /// Applies the given color as a tint color.
  func tinted(using color: UIColor) -> CIImage? {
     guard
        let transparentQRImage = transparent,
        let filter = CIFilter(name: "CIMultiplyCompositing"),
        let colorFilter = CIFilter(name: "CIConstantColorGenerator") else { return nil }
    
    let ciColor = CIColor(color: color)
    colorFilter.setValue(ciColor, forKey: kCIInputColorKey)
    let colorImage = colorFilter.outputImage
    
    filter.setValue(colorImage, forKey: kCIInputImageKey)
    filter.setValue(transparentQRImage, forKey: kCIInputBackgroundImageKey)
    
    return filter.outputImage!
  }
}

extension CIImage {
  /// Combines the current image with the given image centered.
  func combined(with image: CIImage) -> CIImage? {
    guard let combinedFilter = CIFilter(name: "CISourceOverCompositing") else { return nil }
      
    let centerTransform = CGAffineTransform(translationX: extent.midX - (image.extent.size.width / 2), y: extent.midY - (image.extent.size.height / 2))
      
    combinedFilter.setValue(image.transformed(by: centerTransform), forKey: "inputImage")
    combinedFilter.setValue(self, forKey: "inputBackgroundImage")
      
    return combinedFilter.outputImage!
  }
}
