# Rate It: documentation

## 1. What it is
A private Android app where a small group of friends (about 5 to 10) log shows and movies, rate them on several criteria, and see each other's opinions in a shared feed.

## 2. How a person uses it
1. **Sign up.** Choose *Create a group* (the app makes a 6-character code) or *I have a code* (type a friend's code). The code is shown on your own profile with a copy button.
2. **Search** a show or movie and open it.
3. **Add to my list.** Pick a list, give stars, write a review, choose *Suggest* or *Do not suggest*.
4. **Open the feed** to see what the group is watching and rating.
5. **Open any friend** (avatar row on the feed) to see their lists. Open any title to see every friend's ratings, then add it to your own list.

## 3. Screens
| Screen | Purpose |
|---|---|
| Sign in / Sign up | Login, create a group or join with a code, language switch |
| Feed | Member avatars, then five sideways rows: Last watched, Must watch, Favorites, Meh, Avoid |
| Search | Search TMDB by title |
| Title | Poster, details, "Add to my list", and every friend's rating and review |
| Add / edit entry | List, overall and 5 criteria stars, review, suggest toggle, set as last watched |
| Profile | Avatar, counts, info, group code (own profile), four sideways list rows, language, sign out |

## 4. Rules used by the feed
- **Last watched:** each member's pinned show (one per person). Pinning a new one does not delete the old one, it stays in its real list.
- **Must watch:** 4 or 5 stars from at least 2 friends, marked *Suggest*, and you have not watched it.
- **Favorites:** anyone's 5 stars marked *Suggest*.
- **Meh:** friends' 2 or 3 stars marked *Suggest* that you have not watched.
- **Avoid:** anyone's 1 star, or anything marked *Do not suggest*.

## 5. Data (Cloud Firestore)
| Collection | Document ID | Main fields |
|---|---|---|
| `groups` | the group code | `createdBy`, `createdAt` |
| `profiles` | user id | `name`, `avatar` (emoji), `age`, `favShow`, `groupId`, `lastWatched` |
| `entries` | `<uid>_<movie or tv>_<tmdbId>` | `uid`, `groupId`, title info (`title`, `posterPath`, `genres`, `year`, ...), `list`, ratings (`overall`, `acting`, `cinematography`, `plot`, `aesthetic`, `sound`; 0 = not rated), `review`, `suggest`, `updatedAt` |

Title info is copied into each entry so the feed does not need extra lookups.

## 6. Security
Security is enforced by `firestore.rules`, not by the app.
- Only people who have a profile can read data, and only data from **their own group**.
- You can only create, edit and delete **your own** entries, and ratings must be whole numbers from 0 to 5.
- Nobody can change their `groupId` after sign-up.
- Groups cannot be read, changed or deleted from the app. Joining works because the rules check that the group exists.
- Anyone who has the app can create a new group. They still cannot see other groups' data. If you ever want to stop this, tell the maintainer: it needs a different design.
- The TMDB key lives in `secrets/keys.json`, which is ignored by Git, and is passed at build time with `--dart-define-from-file`. It is **not** stored in the repository. It is inside the built APK, which is acceptable for a private app.
- `lib/firebase_options.dart` and `google-services.json` contain Firebase identifiers, not passwords. The security rules are what protect the data.

## 7. Offline behavior
Firestore keeps a copy of data on the phone. Screens show saved data when offline and the feed shows a short note. Changes made offline are saved on the phone and sent automatically when the connection returns.
Search needs internet (it calls TMDB). Sign up and sign in also need internet.

## 8. Languages
English and Arabic. The language follows the phone the first time and can be changed on the sign-in screen or the profile. The look can be System, Light or Dark (Profile, Appearance). Arabic uses a right-to-left layout and the Cairo font. Stars always run left to right. Show titles and genres are stored in English for everyone.

## 9. Running and building
See the Quick start in `README.md`. Common problems:

| Problem | Fix |
|---|---|
| `firebase_options.dart` throws "Run flutterfire configure" | Run `flutterfire configure` and choose Android |
| Build error about Kotlin version | In `android/settings.gradle`, raise the `org.jetbrains.kotlin.android` plugin version to the one the error asks for |
| Build error "Using 'jvmTarget: String' is an error" | Delete the `kotlinOptions { ... }` block in `android/app/build.gradle.kts` and add a `kotlin { compilerOptions { jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17) } }` block at the bottom |
| Build error about minimum SDK | Set `minSdk = 23` in `android/app/build.gradle(.kts)` |
| Sign up says wrong group code | Check the code (letters and numbers only) and that `firestore.rules` is published |
| Search says the TMDB key is missing | Check that `secrets/keys.json` exists and run with `--dart-define-from-file=secrets/keys.json` |
| Old icon or name still shows | Uninstall the app from the phone and run again |

## 10. Free-tier limits
Firebase's free plan has daily limits on reads and writes, and Firestore storage. A group of about 10 friends is expected to stay well inside them, but check the current numbers on the Firebase pricing page before relying on this. If a limit is reached, the app stops syncing until the next day or the plan is upgraded.

## 11. Known limits
- Profile picture is an emoji avatar (Firebase photo storage needs a paid plan).
- Android only.
- No push notifications.
- No password reset screen yet.
- No automated tests yet.
- TMDB's free API is for non-commercial use. Check TMDB's terms before selling the app.

## 12. Handover checklist
- [ ] Client creates their own Firebase project and publishes `firestore.rules`
- [ ] Client creates their own TMDB key
- [ ] Run `flutterfire configure` with the client's project
- [ ] Build the release APK with the client's TMDB key
- [ ] Give the client the source code and this documentation
- [ ] Remove the developer's access to the client's Firebase project
