// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  PlayerView.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 06/10/2021 - for the TousAntiCovid project.
//

import UIKit
import AVFoundation

final class PlayerView: UIView {

    override class var layerClass: AnyClass { AVPlayerLayer.self }

    
    // Keep the reference and use it to observe the loading status.
    private var statusObserver: NSKeyValueObservation?
    private var sizeObserver: NSKeyValueObservation?
    private var playerItem: AVPlayerItem?
    private lazy var indicator: UIActivityIndicatorView = {
        if #available(iOS 13.0, *) {
            return UIActivityIndicatorView(style: .medium)
        } else {
            return UIActivityIndicatorView(style: .gray)
        }
    }()
    private lazy var errorLabel: UILabel = {
        let errorLabel: UILabel = UILabel()
        errorLabel.numberOfLines = 0
        errorLabel.font = Appearance.Cell.Text.accessoryFont
        errorLabel.textAlignment = .center
        return errorLabel
    }()

    private let player: AVPlayer = AVPlayer()
    private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    private var videoRatioChangeBlock: ((_ ratio: CGFloat) -> ())?
    
    deinit {
        removePlayerObservers()
        NotificationCenter.default.removeObserver(self)
    }
    
    func play(with url: URL, videoRatioChangeBlock: @escaping (_ ratio: CGFloat) -> ()) {
        self.videoRatioChangeBlock = videoRatioChangeBlock
        showLoading()
        initPlayer(url: url)
        addNotifications()
        addPlayerObservers()
    }
}

// MARK: - private functions -
private extension PlayerView {
    func showLoading() {
        hideError()
        indicator.startAnimating()
        superview?.addCenteredSubview(indicator)
    }
    
    func hideLoading() {
        indicator.removeFromSuperview()
        indicator.stopAnimating()
    }
    
    func showError(text: String) {
        errorLabel.text = text
        addCenteredSubview(errorLabel, size: bounds.size)
    }

    func hideError() {
        errorLabel.removeFromSuperview()
    }

    func initPlayer(url: URL) {
        guard url.absoluteString != (playerItem?.asset as? AVURLAsset)?.url.absoluteString else { return }
        let urlAsset: AVURLAsset = AVURLAsset(url: url)
        playerItem = AVPlayerItem(asset: urlAsset)
        playerLayer.videoGravity = .resizeAspect
        playerLayer.player = player
        player.replaceCurrentItem(with: playerItem)
        player.isMuted = true
    }

    func addNotifications() {
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: nil) { [weak self] _ in
            DispatchQueue.main.async { self?.restartVideo() }
        }
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                guard self.playerItem?.status == .readyToPlay else { return }
                self.player.playImmediately(atRate: 1.0)
            }
        }
    }

    func addPlayerObservers() {
        guard let playerItem = playerItem else { return }
        removePlayerObservers()
        statusObserver = playerItem.observe(\.status, options: [.initial, .new]) { [weak self] playerItem, _ in
            switch playerItem.status {
            case .readyToPlay:
                self?.player.playImmediately(atRate: 1.0)
                self?.hideLoading()
            case .failed:
                let failureError: Error = playerItem.error ?? NSError.localizedError(message: "common.error.unknown".localized, code: 1)
                self?.showError(text: failureError.localizedDescription)
                self?.hideLoading()
            default:
                break
            }
        }
        sizeObserver = playerItem.observe(\.presentationSize, options: [.initial, .new]) { [weak self] playerItem, _ in
            let size: CGSize = playerItem.presentationSize
            guard size.height != 0 && size.width != 0 else { return }
            self?.videoRatioChangeBlock?(size.height / size.width)
        }
    }

    func removePlayerObservers() {
        statusObserver?.invalidate()
        statusObserver = nil
        sizeObserver?.invalidate()
        sizeObserver = nil
    }

    func restartVideo() {
        player.seek(to: CMTime.zero)
        player.playImmediately(atRate: 1.0)
    }

}
