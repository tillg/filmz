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

To **set the icons**, make to have one png in 1024x1024 and then run `./Scripts/generate_app_icons.sh ./Logo/original_icon.png`.

To make nice **screenshots**, this is my process:
* Run the app from Xcode in the simulator (iPhone or iPad)
* Use the Screenshot button at the bottom right of the simulator
* Then make the screenshots in 3D with [Previewed](https://previewed.app/)

## Roadmap

Features in no specific order:

* Disallow adding the same movie twice.
* Add a field when I added a film.
* Sort options: By alphabet, by date added, by rating.
* Add rating from IMDB and from the user.
* 
* Share a movie with a friend.

Technical playgrounds & toys on my list:

* Use Windsurf in order to compare it to cursor ai
* use Google AI Studio to work on the logo

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