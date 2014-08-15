BlueScript
==============
Like Unreal Engine 4's BluePrint, for JS / CoffeeScript

# Why ?
Because I liked the way BluePrint worked, and believed it's principle could work with JS.
Plus, instead of looking like big blocks, your code now looks like a rainbow !

# How ?
The program is mainly coded in not-so-well formatted CoffeeScript, with some Stylus to make it look good, and a bit of Jade for the template.
Finally, it uses atom-shell to display the content outside of a browser.
It also feature a way-to-complicated Gulpfile to glue all this together in a somewhat working way.

# What (can I do) ?
If you want to help, feel free to do so by submitting pull request or issues.
There is a lot of work to do, especially on ... everything.

# But ...
Oh, I forgot to mention how to compile it.
first, make sure you installed gulp and bower globally (if you don't, npm will likely fail when running the scripts).
Then run `npm i`, it should install all the needed dependencies.
To install atom-shell, run `gulp build:shell` (this task doesn't get executed at every build becaue it can be long).
Finally, run `gulp` and the default task should build the project and run it. (Specifically, it runs the `build`, `watch` and `run` tasks)
