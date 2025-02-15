resource "spotify_playlist" "sufi" {
  name= "sufi songs"
  tracks = ["7F8RNvTQlvbeBLeenycvN6"]
}
data "spotify_search_track" "EdSheeran" {
  artist = "Ed Sheeran"
}
resource "spotify_playlist" "perfect" {
  name = "setchuko's Perfect"
  tracks = [data.spotify_search_track.EdSheeran.tracks[0].id,data.spotify_search_track.EdSheeran.tracks[1].id]
}