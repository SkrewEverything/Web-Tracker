# Web Tracker 🔍


It scans and logs the currently opened websites in Chrome Browser. It can even log incognito windows.

And the best thing is, **It doesn't require any permissions to run**🔥.


## Usage

Clone the repository, open the project in Xcode, build the project and run the executable.

By default, it logs every `5 secs` and creates the database file `web-tracker.db` in the home directory.

**To provide custom time and file name**:

The executable can take multiple arguments

**1)** Both time and file name. The order doesn't matter.

**Example**:
```sh
$ Web\ Tracker 2.5 "./Desktop/tracker.db"
```
*or*
```sh
$ Web\ Tracker "./Desktop/tracker.db" 2.5
```

**2)** Either time or file name

**Example**:
```sh
$ Web\ Tracker 2.5
```
*or*
```sh
$ Web\ Tracker "./Desktop/tracker.db"
```

### To run it in the background

To be able to close the Terminal when Web Tracker is running, use this command while running the executable.

```sh
$ nohup ./Web\ Tracker &
```
And you can quit the Terminal.

### To quit/stop the Web Tracker

To quit the Web Tracker, first find its PID using `ps` and use `kill` to stop the Web Tracker.

```sh
$ ps -e | grep "Web Tracker"
$ kill -9 pid_of_webtracker_from_above_command
```

**The database has these columns**:

- Table name: `Data`

| Column Name | Data Type |
|:-----------:|:---------:|
|     url     |  varchar  |
|    title    |  varchar  |
|  incognito  |    int    |
|     time    |  varchar  |
|     date    |  varchar  |

**For incognito**: `0` means normal window, `1` means incognito window.



## Disclaimer
If the use of this product causes the death of your firstborn or anyone, I'm not responsible ( no warranty, no liability, etc.)

**For technical people**: It is only for educational purpose.

## Contributing

Feel free to fork the project and submit a pull request with your changes!

##### Not experienced or lazy to fork and submit a pull request ?
Open an issue for adding new features, enhancement, bugs etc. I might take a look into it.

License
----

MIT


**Free Software, Hell Yeah!**

