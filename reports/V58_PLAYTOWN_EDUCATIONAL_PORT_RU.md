# InfiniteSpace v58 — Play Town educational mini-games on the ship

Source: user-owned Godot project [FeofanovIvan/safecitykids](https://github.com/FeofanovIvan/safecitykids), local Mac copy. Base InfiniteSpace: `release/v57-installed-snapshot`.

**19 of 20 original game cards:** the five home activities (puzzle, wardrobe, pairs, habitats, professions), five school activities (letters, words, word building, shapes, drawing), five shopping/maths activities (number pick, grocery, number writing, product count, fractions), and four playground educational activities (maze, color mixing, build path, piano). Excluded only scooter race.

The ship cockpit removes Miko, crew, simulator, shop, capacity and speed displays. Retains a crystal picture and crystal balance, horizontal swipeable gallery, navigation arrows and return to flight.

Original Play Town files are copied **from the user's Mac** by `install_v58.py` into `res://education/playtown/` with relative resource paths rebased. The original Play Town project is never changed. All 19 original .tscn gameplay scenes are loaded into an isolated embedded SubViewport at native 1536×768 scaled to each landscape screen. Store and subscription autoruns are disabled in the copied version. Game scene exits return to the gallery rather than replacing InfiniteSpace. Genuine `GameState.coin_balance_changed` increases the Miko fuel tank (maximum 50), no award for opening a card.

The distributed ZIP contains code and a local-source copier, **not the 19 image binaries**. The images are Git LFS and must exist as real files in the user's original Mac Play Town source. Full build is assembled during installation on the Mac, with exact-source safety checks and rollback/backup. Sync to `release/v58-installed-snapshot` requires Git LFS and an authenticated GitHub remote. Godot runtime F5 requires a user's Mac; static tests here use source-compatible fixture scenes and cannot confirm all 19 real games.

Patch name: `InfiniteSpace_v58_Patch_PlayTown_EducationalGames.zip`.
