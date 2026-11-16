# Soul

**A private social network built around projects instead of posts.**

Most social apps reward the highlight reel. Soul asks a different question: what are you working on, and how is it going? You share projects (a band, a training block, a startup, a painting) and post updates as they grow, with a small circle of friends instead of an audience.

## The Soul Tree

Your profile is a living tree instead of a grid of photos. Each project is a branch and each update is a node along it, so your profile literally grows as you do.

Branches change with the state of the project:

| State | Meaning | Look |
| --- | --- | --- |
| Seedling | Started in the last two weeks | Faint, new growth |
| Growing | Active and being updated | Full color |
| Dormant | Paused | Faded |
| Completed | Finished | Settled, slightly muted |

Tap a branch to open the project, or a node to read that update. The tree is drawn with SwiftUI `Canvas` and laid out by a custom layout engine (`Views/Profile/TreeLayoutEngine.swift`), with pinch to zoom.

## Features

- **Feed** of friends' project updates
- **Projects** with status (active, paused, completed), descriptions, cover images, and update history
- **Friends** with requests and a private circle
- **Soul** profile tree, described above
- Email sign up and login

## Tech stack

- **iOS:** SwiftUI, Swift 6, iOS 17, MVVM (view models per tab)
- **Backend:** Supabase (Auth and Postgres, schema in `supabase/migrations/`)
- **Project generation:** XcodeGen (`project.yml`)

## Running locally

```bash
brew install xcodegen
xcodegen generate
open Soul.xcodeproj
```

Point `Soul/Utilities/Constants.swift` at your own Supabase project and apply `supabase/migrations/001_initial_schema.sql`.

---

Built by [Arjun Chadha](https://www.linkedin.com/in/arjun-chadha-7164221b1).
