//
//  dataModel.swift
//  Visitor App
//
//  Created by Gill, Nathan on 24/11/2023.
//

import Foundation
import UIKit
/*
 Bed information structure, mostly declared as optionals to accommodate
 inconsistencies in data
 */
struct BedData: Decodable {
    var bed_id: String?
    var name: String?
    var latitude: String?
    var longitude: String?
    var last_modified: String?
}

struct BedArr: Decodable {
    var beds: [BedData] = []
}

struct PlantData: Decodable {
    var recnum: String?
    var acid: String?
    var accsta: String?
    var family: String?
    var genus: String?
    var species: String?
    var infraspecific_epithet: String?
    var vernacular_name: String?
    var cultivar_name: String?
    var donor: String?
    var latitude: String?
    var longitude: String?
    var country: String?
    var iso: String?
    var sgu: String?
    var loc: String?
    var alt: String?
    var cnam: String?
    var cid: String?
    var cdat: String?
    var bed: String?
    var memoriam: String?
    var redlist: String?
    var last_modified:String?
}

struct PlantArr: Decodable {
    var plants: [PlantData] = []
}

struct ImageData: Decodable {
    let recnum: String
    let imgid: String
    let img_file_name: String?
    let imgtitle: String?
    let photodt: String?
    let photonme: String?
    let copy: String?
    let last_modified: String?
}

//might not needs this
struct ImageArr: Decodable {
    let images: [ImageData]
}

struct PlantOnRecnum: Decodable {
    var recnum: String?
    var plant: PlantData?
}


struct PlantBedDataType: Decodable {
    var bed_id: String?
    var data: [PlantData]
}

struct RecnumImgDatatype: Decodable {
    var recnum: String?
    var data: [ImageData]
}
