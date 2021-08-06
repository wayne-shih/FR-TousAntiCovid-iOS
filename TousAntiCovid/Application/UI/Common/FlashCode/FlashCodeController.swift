// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  FlashCodeController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 12/04/2020 - for the TousAntiCovid project.
//

import UIKit
import MobileCoreServices
import UniformTypeIdentifiers
import PKHUD

class FlashCodeController: UIViewController {

    @IBOutlet var explanationLabel: UILabel!
    @IBOutlet var bottomButton: UIButton?
    @IBOutlet var bottomGradientImageView: UIImageView?
    @IBOutlet var scanView: QRScannerView!
    
    var deinitBlock: (() -> ())?
    var allowMediaPickers: Bool = false
    
    private var isFirstLoad: Bool = true
    private var didPickMedia: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        scanView.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isFirstLoad {
            isFirstLoad = false
        } else {
            restartScanning()
        }
    }
    
    deinit {
        deinitBlock?()
    }
    
    func initUI() {
        navigationItem.rightBarButtonItem = allowMediaPickers ? UIBarButtonItem(title: "universalQrScanController.rightBarButton.title".localized, style: .plain, target: self, action: #selector(displayActionSheet)) : nil
    }
    
    func restartScanning() {
        #if !targetEnvironment(simulator)
        scanView.startScanning()
        #endif
    }

    func stopScanning() {
        #if !targetEnvironment(simulator)
        scanView.stopScanning()
        #endif
    }
    
    func processScannedQRCode(code: String?) {
       fatalError("Must be overriden")
    }

    @objc func displayActionSheet() {
        let menu: UIAlertController = UIAlertController(title: nil, message: "universalQrScanController.actionSheet.title".localized, preferredStyle: .actionSheet)
        menu.addAction(UIAlertAction(title: "universalQrScanController.actionSheet.imagePicker".localized, style: .default, handler: { [weak self] _ in
            self?.didTouchImportImageButton()
        }))
        menu.addAction(UIAlertAction(title: "universalQrScanController.actionSheet.documentPicker".localized, style: .default, handler: { [weak self] _ in
            self?.didTouchImportDocumentButton()
        }))
        menu.addAction(UIAlertAction(title: "common.cancel".localized, style: .cancel))
        present(menu, animated: true)
    }
    
}

extension FlashCodeController: QRScannerViewDelegate {
    
    func qrScanningDidStop() {}
    func qrScanningDidFail() {}
    
    func qrScanningSucceededWithCode(_ str: String?) {
        processScannedQRCode(code: str)
    }
    
}

extension FlashCodeController: UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIAdaptivePresentationControllerDelegate {

    @objc func didTouchImportImageButton() {
        stopScanning()
        let picker: UIImagePickerController = UIImagePickerController()
        picker.allowsEditing = true
        picker.delegate = self
        picker.presentationController?.delegate = self
        present(picker, animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        restartScanning()
        dismiss(animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard !didPickMedia else { return }
        didPickMedia = true
        HUD.show(.progress)
        DispatchQueue.main.async { [weak self] in
            guard let image: UIImage = info[.editedImage] as? UIImage else {
                self?.didPickMedia = false
                HUD.hide()
                return
            }
            self?.processScannedQRCode(code: image.getQRCodeValue())
            HUD.hide()
            self?.didPickMedia = false
        }
    }
    
}

extension FlashCodeController: UIDocumentPickerDelegate {

    @objc func didTouchImportDocumentButton() {
        stopScanning()
        let types: [String] = [String(kUTTypePDF), String(kUTTypeImage)]
        let documentPickerController: UIDocumentPickerViewController = UIDocumentPickerViewController(documentTypes: types, in: .import)
        documentPickerController.allowsMultipleSelection = false
        documentPickerController.delegate = self
        documentPickerController.presentationController?.delegate = self
        self.present(documentPickerController, animated: true, completion: nil)
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        restartScanning()
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard !didPickMedia else { return }
        didPickMedia = true
        HUD.show(.progress)
        DispatchQueue.main.async { [weak self] in
            guard let url = urls.first else {
                HUD.hide()
                self?.didPickMedia = false
                return
            }
            guard let data = try? Data(contentsOf: url) else {
                self?.processScannedQRCode(code: nil)
                HUD.hide()
                self?.didPickMedia = false
                return
            }
            if let image = UIImage(data: data) {
                self?.processScannedQRCode(code: image.getQRCodeValue())
            } else {
                self?.processScannedQRCode(code: CGPDFDocument.getQrCodesInPdf(at: url).first)
            }
            HUD.hide()
            self?.didPickMedia = false
        }
    }

}

extension FlashCodeController {

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        restartScanning()
    }

}
