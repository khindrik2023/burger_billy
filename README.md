# BURGER BILLY
#### Video Demo: https://youtu.be/_lc5L3oo3v0
#### Description: Platformer video game
#### NOTE: Love 11.4 was used to design this game (https://love2d.org/wiki/11.4). You must install this version of Love to ensure that the game works properly.


## GAME SYNOPSIS
“Billy can’t read because he eats too many burgers! Help Billy stop eating and start reading!”


## HOW TO PLAY
- Type a word you want to spell when prompted.
- Press the left and right arrow keys to move left and right.
- Press the up arrow key to jump.
- Find the letters that spell your word, and warp to the next level.
- Avoid falling off cliffs.
- AVOID ALL BURGERS!



## INTRODUCTION
A lot of kids today don’t enjoy learning from books and would rather play games on their iPads. Burger Billy is a simple video game designed for ages 4 and up, that parents and teachers can use to teach reading and spelling. The game is challenging enough to keep kids engaged, and there’s a lot of fun secret passage ways to make it entertaining for the adults too. Kids will love learning new words in this fun new way, and more importantly, it creates a nice bonding experience between child and teacher.


## HOW THE GAME WORKS
The User must type a word that she wants to spell. When the game begins, the Player must collect all the letters needed to spell the word that was entered. If the player wins, they are congratulated and given an option to try another word. If the player loses by dying, then the player is directed to a “Loser” screen, and given a chance to try again.

NOTE*** The knowledge used to create this game is from a Udemy tutorial called “Master Lua Programming” by Kyle Shaub. It is important that I credit Kyle here, because I learned all the syntax from him and I use the basic game structure that he teaches. But I will demostrate below how I have learned all the course material, and was able to manipulate the syntax and explore new syntax to build upon the basic foundation taught by Kyle to create my own, more complex and unique game.


## ADDED FUNCTIONALITY
Kyle’s Udemy course teaches a basic structure for a platformer. I used those basics as a foundation, but developed a more complex game and made it my own. Here are some new, more advanced functionalities that I added —

#### User Input Functionality
- Intro screen with original artwork.
- User input screen, where the user can type a word that they would like to spell.
- Before the word can be accepted, it should be in the dictionary. The game opens a dictionary text file and creates a list of words, and checks to see if the user’s input is in that list.
- The User cannot continue if she did not type a word.
- The User cannot continue if she types more than one word.
- The User does not have to worry about case-sensitivity.
- Specific backgrounds, music, and SFX for User input screen.

#### Gameplay Functionality
- The word that the Player is trying to spell is updated in realtime in upper lefthand corner.
- The Player now has a health meter, represented by 3 hearts in the upper lefthand corner. If player is touched or falls 3 times the game will end.
- When the Player finds a letter, the letter acts as a warp zone to the next level. Levels are loaded based on the word that was entered. Behind the hood, the word is split into a list of characters, and ASCII values of the characters are used to map to 26 unique levels. As the Player continues to spell the word, an index is used to monitor how many letters the Player has spelled.
- I created a new “Wall” collider. If a burger bumps into a wall, it will turn and go in the other direction. In order for the burgers to detect the walls, I had to create a query function to check for walls at every frame.
- There are many levels with secret passages to get the letters faster.
- New “game states”, such as an intro screen, a user input screen, a winner screen, and loser screen. These are used to control loading levels and music.
- A `resetGame()` function was added to hard reset the game if the user decided to continue playing.

#### New Graphics Etc.
- 26 new original level designs.
- New Player graphics, redesigned from old Super Mario graphics.
- New platform and enemy graphics.
- New background graphics.
- New fonts.
- New music and SFX.


## FILE DESCRIPTIONS
- `main.lua` - This is main file that launches the main Lua functions - love.load(), love.update(), love.draw(), as well as all other smaller functions, and libraries needed.
- `player.lua` - This contains all functions for the main character Billy, such as jumping and moving, drawing graphics, etc.
- `enemy.lua`  - This contains all functions for the burger enemies, such as moving, avoiding walls and pitfalls, and drawing graphics.


### CLONED LIBRARIES
- `dictionary` - This is a dictionary used to check if user input is a valid word.
- `anim8` - This library makes animation easier by being able to divide a sheet of animation into a grid, and assign numbers to each square.
- `hump` - This library is primarily used to create a camera to track the Player.
- `Simple-Tiled-Implementation` - This library allows you to load levels made from tiles, created in the software Tiled
- `winfield` - This is library is the heart of the game, as it let's you create objects called "colliders". You can design the physics in which the colliders behave in, and design how the colliders react to each other.


## FINAL WORDS
In completing this final project, I've embarked on an incredible learning journey, and I couldn't be prouder of what I've created. The knowledge and skills I gained during my time in CS50x have been invaluable, serving as the foundation upon which this project was built. I'm immensely grateful to all the dedicated instructors who made CS50x possible and provided the guidance and support that allowed me to reach this point. When I started CS50x just 3.5 months ago, I had no programming experience. This project stands as a testament to the growth and capability that can be achieved through hard work and dedication. Thank you CS50x.