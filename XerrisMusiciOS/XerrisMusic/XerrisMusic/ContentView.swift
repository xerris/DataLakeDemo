//
//  ContentView.swift
//  XerrisMusic
//
//  Created by Jason Wiker on 2020-12-26.
//

import SwiftUI
import Alamofire
import AWSPinpoint
import Amplify

struct Track: Decodable {
    let mbid: String
}
struct RecentTracks: Decodable {
    let track: [Track]
}
struct Response: Decodable {
    let recenttracks: RecentTracks
}
struct ContentView: View {
    @State var username: String = ""
    
    func callGet() {

        AF.request("https://ws.audioscrobbler.com/2.0/?method=user.getrecenttracks&user=megaranger&api_key=f2bb8310d17edb41045aba6362611f80&format=json&page=1",
                   method: .get).responseDecodable(of: Response.self) { response in
                    
            debugPrint("Response: \(response)")
        }
    }
    
    func callPost() {
//        let firehoseRecorder = AWSFirehoseRecorder.default()
//        let yourData = "Test_data".data(using: .utf8)
//        firehoseRecorder.saveRecord(yourData, streamName: "YourStreamName")
//        firehoseRecorder.submitAllRecords()
    }
    
    func recordEvents() {
        let properties: AnalyticsProperties = [
            "eventPropertyStringKey": "eventPropertyStringValue",
            "eventPropertyIntKey": 123,
            "eventPropertyDoubleKey": 12.34,
            "eventPropertyBoolKey": true
        ]
        let event = BasicAnalyticsEvent(name: "eventName", properties: properties)
        Amplify.Analytics.record(event: event)
    }
    
    var body: some View {
           VStack {
                Text("Welcome to Xerris Music")
                    .font(.title)
                Text("Enter your LastFM username and press play!")
                    .font(.subheadline)
                HStack(alignment: .center) {
                    Text("Username:")
                        .font(.callout)
                        .bold()
                    TextField("Enter username...", text: $username)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                }.padding()
                Button(action: {
                            self.callGet()
                            self.callPost()
                    self.recordEvents()
                           }) {
                               Text("Play")
                           }
           }
       }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
