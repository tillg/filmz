# Filmz

Maintaining my films and series. The ones I saw as well as the ones I want to see.

Data that I want to keep for a film:
* Title
* Year
* Genre (potentially multiple can apply)
* Rating (1-10) of ME
* Rating (1-10) of IMDB
* Poster (link to URL of IMDB)
* Description (from IMDB, maybe edited by me)
* Trailer (link to IMDB Trailer)
* Country (from IMDB maybe edited by me)
* Language (from IMDB maybe edited by me)
* Release Date (from IMDB)
* Runtime (from IMDB)
* Plot (from IMDB maybe edited by me)

Around sharing
* Who recommended me this film
* For who is this film. I.e. "Me alone", "Me and partner", "Family"

Functionality:
* Search, add, edit, delete a film
* Share a film

## Setup / Run / Build 

In order to **build and publish** a package go on `Product > Archive` and then `Distribute App`.
To *distribute* it the App I currently use TestFlight. Use [App Store Connect](https://appstoreconnect.apple.com) to upload the app and see what has been uploaded in the past.

To **build from the command line** run `Scripts/build.sh`.

To **set the icons**, make to have one png in 1024x1024 and then run `./Scripts/generate_app_icons.sh ./Logo/original_icon.png`.

To make nice **screenshots**, this is my process:
* Run the app from Xcode in the simulator (iPhone or iPad)
* Use the Screenshot button at the bottom right of the simulator
* Then make the screenshots in 3D with [Previewed](https://previewed.app/)

To create a **Privacy Policy** or to update it, I used [freeprivacypolicy.com](https://www.freeprivacypolicy.com/live/71c56b38-c4cf-4f25-b4c0-fc0920dfb53a).

Switching on/off **debug** is needed because some features are _hidden_ behind the debug flag (notably the cache Viewer). To switch it on/off go to `Filmz > Filmz > FilmzApp.swift` and change the `debug` variable.

## Roadmap

Features in no specific order:

* Add MY RATING next to the OMDB Rating
* Share a movie with a friend.
* View what I have in my cache.

Technical playgrounds & toys on my list:

* Use Windsurf in order to compare it to cursor ai
* use Google AI Studio to work on the website

## Done

* 2025-02-16 Replace my image cache with [Kingfisher](https://github.com/onevcat/Kingfisher).
* 2025-02 Cache the movie pictures in order to speed up the app.

## Movie Databases

I need a movie database to query in the background. Here are some options I found:

* [Open Movie Database API](https://www.omdbapi.com/): I think it's a download of the [Open Movie Database](https://www.omdb.org/) (OMDB) and makes the content available via API. Free, but limited to 1000 requests per day. 
* [The Movie Database](https://www.themoviedb.org/): To get a commercial license I need to email them.
* ~~[IMDB](https://www.imdb.com/): The API is crazyyy expensive ($150,000 plus metered costs 😀)~~

Other services to look at:

* [Rotten Tomatoes](https://www.rottentomatoes.com/)
* [Metacritic](https://www.metacritic.com/)
* [Letterboxd](https://letterboxd.com/)
* [Flixster](https://www.flixster.com/)
* [JustWatch](https://www.justwatch.com/)
* [Filmweb](https://www.filmweb.pl/)
* [Film-Rezensionen](https://www.film-rezensionen.de/)