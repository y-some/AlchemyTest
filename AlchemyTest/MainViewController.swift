//
//  ViewController.swift
//  AlchemyTest
//
//  Created by Yasuyuki Someya on 2016/05/01.
//  Copyright © 2016年 Yasuyuki Someya. All rights reserved.
//

import UIKit
import SwiftyJSON
import Photos

class MainViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // 選択された画像
    @IBOutlet weak var selectedImageView: UIImageView!
    // 解析中のインジケータ
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    // MARK: Event

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: Action
    
    /// 画像選択ボタンTap
    @IBAction func SelectPicButtonTapped(sender: AnyObject) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.PhotoLibrary) {
            let controller = UIImagePickerController()
            controller.delegate = self
            controller.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
            self.presentViewController(controller, animated: true, completion: nil)
        }
    }
    
    /// 解析開始ボタンTap
    @IBAction func goButtonTaped(sender: UIButton) {
        if self.selectedImageView.image == nil {
            return
        }
        callAlchemyAPI(self.selectedImageView.image!)
    }
    
    // MARK: Delegate
    
    /// UIImagePickerControllerDelegate：画像選択時
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        picker.dismissViewControllerAnimated(true, completion: nil)
        guard let image = info[UIImagePickerControllerOriginalImage] else {
            return
        }
        self.selectedImageView.image = image as? UIImage
    }

    // MARK: Method
    
    /// AlchemyAPI連携
    /// - parameter image: 解析対象画像イメージ
    func callAlchemyAPI(image: UIImage) {
        let APIKey = "" //APIKeyを取得してここに記述
        let url = "https://gateway-a.watsonplatform.net/calls/image/ImageGetRankedImageFaceTags?imagePostMode=raw&outputMode=json&apikey=" + APIKey
        
        let destURL = NSURL(string: url)!
        
        // API仕様の画像サイズ（1MB）を超えないようにする
        let maxSize:Double = 1024 * 768
        var ratio: CGFloat = 1
        if Double(image.size.width * image.size.height) > maxSize {
            ratio = CGFloat(maxSize / Double(image.size.width * image.size.height))
        }        
        let imageData = UIImageJPEGRepresentation(image, ratio)
        
        let request = NSMutableURLRequest(URL: destURL)
        request.HTTPMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.HTTPBody = imageData

        self.activityIndicator.startAnimating()
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
            data, response, error in
            
            if error == nil {
                let json = JSON(data: data!)
                print(json)
                
                // 解析結果はAppDelegateの変数を経由してSubViewに渡す
                let appDelegate: AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                appDelegate.analyzedFaces = []
                let facesJson = json["imageFaces"].arrayValue
                // レスポンスのimageFaces要素は配列となっている（複数人が映った画像の解析が可能）
                for faceJson in facesJson {
                    let face = AnalyzedFace()
                    face.height = faceJson["height"].string
                    face.width = faceJson["width"].string
                    face.positionX = faceJson["positionX"].string
                    face.positionY = faceJson["positionY"].string
                    face.gender = faceJson["gender"]["gender"].string
                    face.genderScore = faceJson["gender"]["score"].string
                    face.ageRange = faceJson["age"]["ageRange"].string
                    face.ageScore = faceJson["age"]["score"].string
                    if faceJson["identity"]["name"].string != nil {
                        face.name = faceJson["identity"]["name"].string
                    } else {
                        face.name = ""
                    }
                    appDelegate.analyzedFaces.append(face)
                }
                appDelegate.analyzedImage = UIImage.init(data: imageData!)
                
                // リクエストは非同期のため画面遷移をmainQueueで行わないとエラーになる
                NSOperationQueue.mainQueue().addOperationWithBlock(
                    {
                        self.activityIndicator.stopAnimating()
                        if appDelegate.analyzedFaces.count > 0 {
                            self.performSegueWithIdentifier("next", sender: self)
                        } else {
                            let actionSheet = UIAlertController(title:"エラー", message: "顔検出されませんでした", preferredStyle: UIAlertControllerStyle.Alert)
                            let actionCancel = UIAlertAction(title: "キャンセル", style: UIAlertActionStyle.Cancel, handler: {action in
                            })
                            actionSheet.addAction(actionCancel)
                            self.presentViewController(actionSheet, animated: true, completion: nil)
                        }
                    }
                )
            }
        }
        task.resume()
    }
    
 }

