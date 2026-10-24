<p align="center">
  <img src="docs/images/logo.png" alt="Rate It logo" width="120">
</p>

<h1 align="center">Rate It</h1>

<p align="center">
  Rate shows and movies with your friends.<br>
  A small, private Android app for a group of friends: log what you watch, rate it,
  and see what everyone else loved or hated.
</p>

<p align="center">
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-Android-02569B?logo=flutter&logoColor=white">
  <img alt="Firebase" src="https://img.shields.io/badge/Firebase-Auth%20%2B%20Firestore-FFCA28?logo=firebase&logoColor=black">
  <img alt="Languages" src="https://img.shields.io/badge/Languages-English%20%7C%20%D8%A7%D9%84%D8%B9%D8%B1%D8%A8%D9%8A%D8%A9-EC008C">
  <img alt="License" src="https://img.shields.io/badge/License-MIT-green">
</p>

---

## Screenshots

<!--
  Add your screenshots to docs/screenshots/ with exactly these names
  (or change the names below). Phone screenshots look best at width 200.
-->

<table>
  <tr>
    <td align="center"><img src="docs/screenshots/01-login.png" width="200" alt="Sign in"><br><sub>Sign in</sub></td>
    <td align="center"><img src="docs/screenshots/02-signup.png" width="200" alt="Create account"><br><sub>Create a group or join with a code</sub></td>
    <td align="center"><img src="docs/screenshots/03-feed.png" width="200" alt="Feed"><br><sub>Group feed</sub></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/screenshots/04-search.png" width="200" alt="Search"><br><sub>Search shows and movies</sub></td>
    <td align="center"><img src="docs/screenshots/05-title.png" width="200" alt="Title details"><br><sub>Details and what friends say</sub></td>
    <td align="center"><img src="docs/screenshots/06-profile.png" width="200" alt="Profile"><br><sub>Profile and lists</sub></td>
  </tr>
</table>

## Features

- **Private groups.** Create a group and get a 6-character code, or join a friend's group with theirs. Groups cannot see each other.
- **Log what you watch.** Search shows and movies, then put them in *Watching*, *Watched* or *Dropped*.
- **Detailed ratings.** Overall stars plus acting, cinematography, plot, visual style and pacing/sound. Add a review and a *Suggest / Do not suggest* tag.
- **Last watched.** One pinned show per person.
- **Friends' opinions.** Open any title to see every friend's ratings and review, then add it to your own list.
- **Group feed.** *Last watched*, *Must watch*, *Favorites*, *Meh* and *Avoid*, each scrolling sideways.
- **Profiles.** Avatar, age, favorite show, top rated, most watched genre and your lists.
- **English and Arabic**, with a full right-to-left layout.
- **Light and dark mode.** Follows your phone, or choose one in your profile.
- **Works offline.** Saved data stays readable and changes sync when you are back online.

## Tech stack

| Part | Choice |
|---|---|
| App | Flutter (Android) |
| Login | Firebase Authentication (email and password) |
| Database | Cloud Firestore, protected by security rules |
| Show data | [TMDB](https://www.themoviedb.org/) API |
| Fonts | Inter and Cairo (Google Fonts) |

Everything runs on free tiers. No server code and no paid plan are needed.

## Quick start

You need [Flutter](https://docs.flutter.dev/get-started/install) and an Android phone or emulator.

1. **Get the code**
   ```bash
   git clone https://github.com/YOUR_USERNAME/rate-it.git
   cd rate-it
   flutter pub get
   ```
2. **Firebase** (free Spark plan, no billing card)
   - Create a project at [console.firebase.google.com](https://console.firebase.google.com).
   - Authentication: enable **Email/Password**.
   - Firestore Database: create a database, then paste `firestore.rules` into the **Rules** tab and publish.
   - Run `dart pub global activate flutterfire_cli`, then `flutterfire configure` and choose Android. This creates `lib/firebase_options.dart`.
3. **TMDB key** (free): create a v3 API key at [themoviedb.org](https://www.themoviedb.org/settings/api).
   Copy `secrets/keys.example.json` to `secrets/keys.json` and paste your key inside.
   The `secrets/` folder is ignored by Git, so your key is never uploaded.
4. **Run**
   ```bash
   flutter run --dart-define-from-file=secrets/keys.json
   ```

Build an APK to share with friends:

```bash
flutter build apk --release --dart-define-from-file=secrets/keys.json
```

More detail, including common build errors, is in [docs/DOCUMENTATION.md](docs/DOCUMENTATION.md).

## Project structure

```
lib/
  main.dart            app start, login check, language
  theme.dart           colors, fonts, component styles
  l10n.dart            English and Arabic texts
  models.dart          Profile, Entry, TitleInfo
  services.dart        login, database, TMDB search
  widgets.dart         posters, stars, avatars, shared widgets
  screens/             auth, home, feed, search, title, entry edit, profile
firestore.rules        database security rules
secrets/               your local keys (ignored by Git, only the example file is shared)
docs/                  documentation, logo, screenshots
```

## Status

Tested by hand on one Android phone. There are no automated tests yet.

## License

[MIT](LICENSE). The license covers the code in this repository, not the movie and show data or images, which belong to TMDB and its sources.

## Credits

This product uses the TMDB API but is not endorsed or certified by TMDB.
