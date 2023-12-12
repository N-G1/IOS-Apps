---------------------------------Simon Game---------------------------------
This app functions more or less exactly the same as the popular short term
memory game Simon, the user is presented with a menu screen containing buttons
to a 'How to play' screen, a 'Single player' screen, a 'leaderboard' screen and 
a 'Multiplayer' screen. 

Single player functions exactly how you would expect, displaying a pattern that
the user has to match to get to the next stage, increasing in length each time, 
once the user fails, their highscore is displayed at the top and their score is
shared on the leaderboard screen, where the top 15 scores of the user will be
displayed. 

Multiplayer is local and operates by inputting the number of players, each player 
then takes turns playing until they fail, when they do, the app informs the next 
player to get ready and after a decent pause, continues onto the next player, this 
is repeated until every player has played and displays the player who wons score
with their name.

The 'how to play' screen has no notable features excluding describing how the 
game works and how the multiplayer functions  

---------------------------------Visitor App---------------------------------

This app presents the user with a map, tracking their location and a TableView
displaying information about plants including a thumbnail, sorted by the beds 
they are planted in and ordered by distance from the users current location.

All plant information is pulled via API from a database.

Moving around causes the TableView to reorder itself by closest to the user, 
holding a cell down causes the user to favourite a plant, which displays 
a star and is cached in core data.

Tapping a cell displays more information about a plant, including a planted 
location on a map if it is available and anymore images stored related to the 
plant.

All plant and bed data is cached in core data upon first run, which significantly
increases load time, however, this means that subsequent loads are very fast,
assuming there is not any new large amounts of plant data that need to be stored.
