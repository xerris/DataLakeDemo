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

struct TrackImage: Codable {
    let size: String
    let text: String
    enum CodingKeys: String, CodingKey{
           case text = "#text"
            case size = "size"
       }
}

struct TrackDate: Codable {
    let uts: String
    let text: String
    enum CodingKeys: String, CodingKey{
           case text = "#text"
            case uts = "uts"
       }
}

struct TrackDetail: Codable {
    let mbid: String
    let text: String
    enum CodingKeys: String, CodingKey{
           case text = "#text"
            case mbid = "mbid"
       }
}

struct Track: Codable {
    let mbid: String
    let name: String
    let url: String
    let artist: TrackDetail
    let album: TrackDetail
    let image: [TrackImage]
    let date: TrackDate
    
}
struct RecentTracks: Codable {
    let track: [Track]
}

struct TrackResponse: Codable {
    let recenttracks: RecentTracks
}
struct TagDetail: Codable {
    let name: String
    let url: String
}
struct TagDetails: Codable {
    let tag: [TagDetail]
}
struct AlbumDetails: Codable {
    let listeners: String
    let tags: TagDetails
}
struct AlbumResponse: Codable {
    let album: AlbumDetails
}

struct ContentView: View {
    @State var username: String = ""
    
    func callGet() {
        AF.request("https://ws.audioscrobbler.com/2.0/?method=user.getrecenttracks&user=megaranger&api_key=f2bb8310d17edb41045aba6362611f80&format=json&page=170&limit=200",
                   method: .get).responseDecodable(of: TrackResponse.self) { response in
                    
            //debugPrint("Response: \(response)")
            let tracks: [Track] = (response.value?.recenttracks.track)!
            for track in tracks {
                callGetAlbum(track: track)
            }
        }
    }
    
    func callGetAlbum(track: Track) {
        let url = ("https://ws.audioscrobbler.com/2.0/?method=album.getinfo&api_key=f2bb8310d17edb41045aba6362611f80&format=json&mbid=" + track.album.mbid)
      
        AF.request(url, method: .post).responseDecodable(of: AlbumResponse.self) { response in

            //debugPrint("Response: \(response)")
            let listeners: String = response.value?.album.listeners ?? "?"
            var properties: AnalyticsProperties = [
                "artist": track.artist.text,
                "album": track.album.text,
                "playTime": track.date.uts,
                "trackname": track.name
            ]
            if listeners != "?"{
                properties["listeners"] = listeners
            }
            var tagVal = 1
            let tags: [TagDetail] = response.value?.album.tags.tag ?? []
            for tag in tags {
                properties["tag" + String(tagVal)] = tag.name
                tagVal += 1
            }
            print(properties)
            let event = BasicAnalyticsEvent(name: "SongListen", properties: properties)
            Amplify.Analytics.record(event: event)
        }
        
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
