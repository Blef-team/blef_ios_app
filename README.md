# Blef iOS app
> The iOS app for the game of Blef

This repository contains the Xcode project and assets for the iOS game Blef. The app  makes use of the Blef game engine API service.

### Gameplay
Blef is a Polish card game inspired by Poker. In the game, each player has a certain number of playing cards between 9 and Ace, each card only known to its owner, and players have to make guesses about other players' cards. You can find more information and game rules [here](https://github.com/Blef-team/blef_game_engine/blob/master/README.md).

The game can be started from the launch screen, by pressing "New game":

![New game screen](/docs/new_game_screen.jpeg?raw=true "New game")

or from a shared invite link. In both cases the game starts:

![Game created screen](/docs/game_created_screen.jpeg?raw=true "Game created")

The game can be shared via a custom URL scheme-based link (blef:///\<game_uuid>), by tapping the "Share button" in the game screen:

![Share game screen](/docs/share_game_screen.jpeg?raw=true "Share game")

Once there are at least two players, the game is started by the _admin_ player (the one who joined first), by tapping "Start game":

![Start game screen](/docs/start_game_screen.jpeg?raw=true "Start game")

The player's cards are displayed at the bottom of the screen. The game is played by selecting a bet, or checking the previous player's bet:

![Make move screen](/docs/make_move_screen.jpeg?raw=true "Make move")

The current bet is displayed in the middle of the screen. The game will wait until the other players have made their moves and it's the app user's turn again:

![Other player's move screen](/docs/other_player_move_screen.PNG?raw=true "Other player's move")

### Game engine API service

For information about the game engine API service, please check out the [Blef Game Engine repo](https://github.com/Blef-team/blef_game_engine).

### Attribution

Card image assets were created by [Simon (aussiesim)](https://game-icons.net), licensed under [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/), and were adapted and modifed by Blef Team.

Door icon assets were created by [inkubators - Flaticon](https://www.flaticon.com/authors/inkubators) ([license](https://www.freepikcompany.com/legal#nav-flaticon-agreement)), and were adapted and modified by Blef Team.
