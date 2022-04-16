//
//  WebViewFileIntegration.swift
//  planning-ios
//
//  Created by Matthew O'Connor on 11/3/16.
//  Copyright © 2016 American Planning Association. All rights reserved.
//

import Foundation
import Alamofire

class WebViewFileIntegration {
    
    let rootDirectory = "apa/webviewfiles/"
    let fileManager = FileManager.default
    
    var managedFiles : [(file:String, directory:String, source:String, sourceLastUpdateUrl:String)] {
        get {
            return [
                (file:"javits-1A.pdf",
                    directory:"pdf/",
                    source:"\(appCore.site_domain)/medialibrary/media/9115159/file/",
                    sourceLastUpdateUrl:"\(appCore.site_domain)/medialibrary/media/9115159/last-updated/json/"),
                (file:"javits-1C.pdf",
                    directory:"pdf/",
                    source:"\(appCore.site_domain)/medialibrary/media/9115160/file/",
                    sourceLastUpdateUrl:"\(appCore.site_domain)/medialibrary/media/9115160/last-updated/json/"),
                (file:"javits-1D.pdf",
                    directory:"pdf/",
                    source:"\(appCore.site_domain)/medialibrary/media/9115161/file/",
                    sourceLastUpdateUrl:"\(appCore.site_domain)/medialibrary/media/9115161/last-updated/json/"),
                (file:"javits-1E.pdf",
                    directory:"pdf/",
                    source:"\(appCore.site_domain)/medialibrary/media/9115162/file/",
                    sourceLastUpdateUrl:"\(appCore.site_domain)/medialibrary/media/9115162/last-updated/json/"),
                (file:"planning-guide.pdf",
                    directory:"pdf/",
                    source:"\(appCore.site_domain)/medialibrary/media/9115163/file/",
                    sourceLastUpdateUrl:"\(appCore.site_domain)/medialibrary/media/9115163/last-updated/json/"),
                (file:"javits-level-1.pdf",
                    directory:"pdf/",
                    source:"\(appCore.site_domain)/medialibrary/media/9115748/file/",
                    sourceLastUpdateUrl:"\(appCore.site_domain)/medialibrary/media/9115748/last-updated/json/"),
                (file:"marriot-activities.pdf",
                    directory:"pdf/",
                    source:"\(appCore.site_domain)/medialibrary/media/9115749/file/",
                    sourceLastUpdateUrl:"\(appCore.site_domain)/medialibrary/media/9115749/last-updated/json/")
            ]
        }
    }
    
    func importFile(managedFile:(file:String, directory:String, source:String, sourceLastUpdateUrl:String), callback:@escaping (_ success:Bool) -> Void ) {
        let url = URL(string: managedFile.source)
        let request = URLRequest(url: url!)
        
        //get data
        URLSession.shared.dataTask(with: request){
            data,response,error in

            if data != nil {

                let directoryURL = self.getDocUrl(directory:managedFile.directory, file:"")
                let docURL = self.getDocUrl(directory:managedFile.directory, file:managedFile.file)
                do {
                    
                    try self.fileManager.createDirectory(at: directoryURL!, withIntermediateDirectories: true)
                    
                    let fileExists = self.fileManager.fileExists(atPath:docURL!.path)
                    
                    if fileExists {
                        try data?.write(to:docURL!) //write file to the disk.
                    }else{
                        self.fileManager.createFile(atPath:docURL!.path, contents:data)
                    }
                    
                    callback(true)
                }catch{
                    print("Error info: \(error)")
                    callback(false)
                }
                
            }else{
                callback(error == nil)
            }
            
        }.resume()
        
    }
    
    func fileRequiresUpdate(managedFile:(file:String, directory:String, source:String, sourceLastUpdateUrl:String), callback:@escaping (_ requiresUpdate:Bool) -> Void) {
        // determines if file needs to be updated from source. If anything fails, assume yes
        let docURL = getDocUrl(directory:managedFile.directory, file:managedFile.file)
        
        do {
            let attributes = try fileManager.attributesOfItem(atPath:docURL!.path)
            if let localLastUpdated = attributes[FileAttributeKey.modificationDate] as? Date {
                request(managedFile.sourceLastUpdateUrl).responseJSON { response in
                    switch response.result {
                        
                    case .success(let data):
                        let json = JSON(data)
                        
                        if let updated_time_json = json["updated_time"].string {
                            
                            // convert to date
                            let fixed_updated_time : String = updated_time_json.components(separatedBy: CharacterSet (charactersIn: "TZ")).joined(separator: " ")
                            let json_date_formatter = DateFormatter()
                            json_date_formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
                            json_date_formatter.timeZone = TimeZone(identifier:"UTC")
                            let sourceLastUpdated = json_date_formatter.date(from: fixed_updated_time)
                            
                            //compare dates
                            callback(localLastUpdated < sourceLastUpdated!)
                            
                        }else{
                            callback(true)
                        }
                        
                    case .failure(let error):
                        print("Request failed with error: \(error)")
                        callback(true)
                    }
                }
            }else{
                callback(true)
            }
        }catch{
            print("Request failed with error: \(error)")
            callback(true)
        }
        
        
    
    }
    
    func getDocUrl(directory:String, file:String) -> URL? {
        //Get the local docs directory and append local filename.
        var docURL = (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)).last
        docURL = docURL?.appendingPathComponent("\(rootDirectory)\(directory)\(file)")
        return docURL
    }
    
    func cleanManagedFiles() {
        // remove files that are not in managedFiles
    }
    
}
