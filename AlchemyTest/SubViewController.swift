//
//  SubViewController.swift
//  AlchemyTest
//
//  Created by Yasuyuki Someya on 2016/05/07.
//  Copyright © 2016年 Yasuyuki Someya. All rights reserved.
//

import UIKit

class SubViewController: UIViewController, UIScrollViewDelegate {

    // 解析結果ImageViewの親であるScrollView
    @IBOutlet weak var resultScrollView: UIScrollView!
    // 解析結果画像のImageView
    @IBOutlet weak var resultImageView: UIImageView!
    
    // MARK: Event

    override func viewDidLoad() {
        super.viewDidLoad()
        self.resultScrollView.delegate = self
        self.resultScrollView.maximumZoomScale = 4.0
        self.resultScrollView.minimumZoomScale = 0.4
        self.setResult()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: Delegate

    /// UIScrollViewDelegate：解析結果ImageViewの親であるScrollViewのZoom時
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return self.resultImageView
    }
    
    // MARK: Method
    
    /// 解析対象画像と解析結果（テキストと顔の矩形）を合成する
    func setResult() {
        
        // 解析結果はAppDelegateの変数を経由して受け取る
        let appDelegate: AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let drawImage = appDelegate.analyzedImage!
        
        let imageWidth = appDelegate.analyzedImage!.size.width
        let imageHeight = appDelegate.analyzedImage!.size.height
        let rect = CGRectMake(0, 0, imageWidth, imageHeight)
        
        UIGraphicsBeginImageContext(appDelegate.analyzedImage!.size)
        drawImage.drawInRect(rect)

        let analyzedFaces = appDelegate.analyzedFaces
        var outputText: String
        let font = UIFont.boldSystemFontOfSize(30)
        let textStyle = NSMutableParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
        let textFontAttributes = [
            NSFontAttributeName: font,
            NSForegroundColorAttributeName: UIColor.orangeColor(),
            NSParagraphStyleAttributeName: textStyle
        ]

        for i in 0...analyzedFaces.count - 1 {
            // 顔の矩形描画
            let roundRect = UIBezierPath(
                roundedRect: CGRectMake(
                    CGFloat(Double(analyzedFaces[i].positionX!)!),
                    CGFloat(Double(analyzedFaces[i].positionY!)!),
                    CGFloat(Double(analyzedFaces[i].width!)!),
                    CGFloat(Double(analyzedFaces[i].height!)!)),
                cornerRadius: 10)
            UIColor.orangeColor().setStroke()
            roundRect.lineWidth = 6
            roundRect.stroke()
            
            // テキストの描画
            outputText = ""
            if let gender = analyzedFaces[i].gender {
                if gender == "MALE" {
                    outputText += "男性 "
                } else {
                    outputText += "女性 "
                }
            }
            if let genderScore = analyzedFaces[i].genderScore {
                let outputGenderScore: Double = floor(Double(genderScore)! * 1000) / 10
                outputText += "\(outputGenderScore)" + "%\n"
            }
            if let ageRange = analyzedFaces[i].ageRange {
                outputText += "\(ageRange)" + "才 "
            }
            if let ageScore = analyzedFaces[i].ageScore {
                let outputAgeScore: Double = floor(Double(ageScore)! * 1000) / 10
                outputText += "\(outputAgeScore)" + "%\n"
            }
            if let name = analyzedFaces[i].name {
                outputText += "\(name)"
            }
            let margin: Double = 10 //矩形とテキストのマージン
            let textRect = CGRectMake(
                CGFloat(Double(analyzedFaces[i].positionX!)!),
                CGFloat(Double(analyzedFaces[i].positionY!)! + Double(analyzedFaces[i].height!)! + margin),
                250,
                250)
            
            outputText.drawInRect(textRect, withAttributes: textFontAttributes)
        }
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext()
        self.resultImageView.image = newImage
    }
}