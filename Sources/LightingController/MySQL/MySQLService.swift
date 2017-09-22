//
//  MySQLService.swift
//  instrumentation-lighting
//
//  Created by Matt Lloyd on 21/09/2017.
//
//

import PerfectLib
import MariaDB
import Foundation 


class MySQLService {

    private let host: String
    private let user: String
    private let password: String
    private let database: String

    let client = MySQL()
    
    init(host: String, user: String, password: String, database: String) {
        self.host = host
        self.user = user
        self.password = password
        self.database = database
        let _ = client.setOption(.MYSQL_SET_CHARSET_NAME, "utf8")
    }
    
    func connect() -> Bool {
        guard client.connect(host: host, user: user, password: password, db: database) else {
            Log.error(message: "Failure connecting to data server \(host)")
            return false
        }
        
        Log.info(message: "Connected to data server \(host)")

        return true
    }
}

//let testHost = "127.0.0.1"
//let testUser = "homestead"
//let testPassword = "secret"
//let testDB = "lighting"
//
//let dataMysql = MySQL()
//
//func test() {
//    // need to make sure something is available.
//    guard dataMysql.connect(host: testHost, user: testUser, password: testPassword ) else {
//        Log.info(message: "Failure connecting to data server \(testHost)")
//        return 
//    }
//
//    defer {
//        dataMysql.close()  // defer ensures we close our db connection at the end of this request
//    }
//
//    //set database to be used, this example assumes presence of a users table and run a raw query, return failure message on a error
//    guard dataMysql.selectDatabase(named: testDB) && dataMysql.query(statement: "select * from floors") else {
//        Log.info(message: "Failure: \(dataMysql.errorCode()) \(dataMysql.errorMessage())")
//        return  
//
//    }
//
//    //store complete result set
//    let results = dataMysql.storeResults()
//
//    //setup an array to store results
//    var resultArray = [[String?]]()
//
//    while let row = results?.next() {
//        resultArray.append(row)
//    }
//
//    print(resultArray.debugDescription)
//}
