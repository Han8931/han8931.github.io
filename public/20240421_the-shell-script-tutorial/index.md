# Bash script tutorial


- [Reference](https://www.shellscript.sh/first.html)

Let's create our first shell script
```sh
#!/bin/sh
# This is a comment!
echo Hello World        # This is a comment, too!
```
- The first line tells Unix that the file is to be executed by `/bin/sh`. This is the standard location of the _Bourne shell_ on just about every Unix system. If you're using GNU/Linux, /bin/sh is normally a symbolic link to bash (or, more recently, dash).
- The second line begins with a special symbol: `#`. This marks the line as a comment, and it is ignored completely by the shell.  
- The only exception is when the _very first_ line of the file starts with `#!` (shebang) - as ours does. This is a special directive which Unix treats specially. It means that even if you are using csh, ksh, or anything else as your interactive shell, that what follows should be interpreted by the Bourne shell.  
- Similarly, a Perl script may start with the line `#!/usr/bin/perl` to tell your interactive shell that the program which follows should be executed by perl. For Bourne shell programming, we shall stick to `#!/bin/sh.`
- The third line runs a command: `echo`, with two parameters, or arguments - the first is `"Hello"`; the second is `"World"`.  
- Note that `echo` will automatically put a single space between its parameters.
- To make it executable, run `chmod +rx <filename>`

# Variables

Let's look back at our first Hello World example. This could be done using variables. Note that _there must be no spaces around the "`=`" sign_: `VAR=value` works; `VAR = value` doesn't work. In the first case, the shell sees the "`=`" symbol and treats the command as a variable assignment. In the second case, the shell assumes that VAR must be the name of a command and tries to execute it.  

```sh
#!/bin/sh  
MY_MESSAGE="Hello World"  
echo $MY_MESSAGE
```

- This assigns the string "Hello World" to the variable `MY_MESSAGE` then `echo`es out the value of the variable.  
- Note that we need the quotes around the string Hello World. Whereas we could get away with `echo Hello World` because echo will take any number of parameters, a variable can only hold one value, so a string with spaces must be quoted so that the shell knows to treat it all as one. Otherwise, the shell will try to execute the command `World` after assigning `MY_MESSAGE=Hello`
- The shell does not care about types of variables; they may store strings, integers, real numbers - anything you like.

We can interactively set variable names using the `read` command; the following script asks you for your name then greets you personally
```sh
#!/bin/sh  
echo What is your name?  
read MY_NAME
echo "Hello $MY_NAME - hope you're well."
```

# Escape Characters
Certain characters are significant to the shell; for example, that the use of double quotes (`"`) characters affect how spaces and TAB characters are treated, for example:
```
$ echo Hello       World
Hello World
$ echo "Hello       World"
Hello     World
```

So how do we display: `Hello    "World"` ?
`$ echo "Hello   \"World\""`

The first and last " characters wrap the whole lot into one parameter passed to `echo` so that the spacing between the two words is kept as is. But the code:
`$ echo "Hello   " World ""`
would be interpreted as three parameters:

1. "Hello   "
2. World
3. ""

So the output would be
`Hello    World`
Note that we lose the quotes entirely. This is because the first and second quotes mark off the Hello and following spaces; the second argument is an unquoted "World" and the third argument is the empty string; "".

# Loop

## For Loop

```sh
#!/bin/sh
for i in 1 2 3 4 5
do
  echo "Looping ... number $i"
done
```

```sh
#!/bin/sh
for i in hello 1 * 2 goodbye 
do
  echo "Looping ... i is set to $i"
done
```

The output of the above code is
```
Looping ... i is set to hello
Looping ... i is set to 1
Looping ... i is set to (name of first file in current directory)
    ... etc ...
Looping ... i is set to (name of last file in current directory)
Looping ... i is set to 2
Looping ... i is set to goodbye
```

This is well worth trying. Make sure that you understand what is happening here. Try it without the `*` and grasp the idea, then re-read the [Wildcards](https://www.shellscript.sh/wildcards.html) section and try it again with the `*` in place. Try it also in different directories, and with the `*` surrounded by double quotes, and try it preceded by a backslash (`\*`)

## While Loop


```sh
#!/bin/sh
INPUT_STRING=hello
while [ "$INPUT_STRING" != "bye" ]
do
  echo "Please type something in (bye to quit)"
  read INPUT_STRING
  echo "You typed: $INPUT_STRING"
done
```

```sh
#!/bin/sh
while :
do
  echo "Please type something in (^C to quit)"
  read INPUT_STRING
  echo "You typed: $INPUT_STRING"
done
```

The colon (`:`) always evaluates to true; whilst using this can be necessary sometimes, it is often preferable to use a real exit condition. Compare quitting the above loop with the one below; see which is the more elegant. Also think of some situations in which each one would be more useful than the other:

```sh
#!/bin/sh
while read input_text
do
  case $input_text in
        hello)          echo English    ;;
        howdy)          echo American   ;;
        gday)           echo Australian ;;
        bonjour)        echo French     ;;
        "guten tag")    echo German     ;;
        *)              echo Unknown Language: $input_text
                ;;
   esac
done < myfile.txt
```

This reads the file "`myfile.txt`", one line at a time, into the variable "`$input_text`". The [case](https://www.shellscript.sh/case.html) statement then checks the value of `$input_text`. If the word that was read from `myfile.txt` was "hello" then it `echo`es the word "English". If it was "gday" then it will `echo Australian`. If the word (or words) read from a line of `myfile.txt` don't match any of the provided patterns, then the catch-all "\*" default will display the message "Unknown Language: \$input_text" - where of course "$input_text" is the value of the line that it read in from `myfile.txt`.

A handy Bash (but not Bourne Shell) tip I learned recently from the [Linux From Scratch](http://www.linuxfromscratch.org/) project is:
`mkdir rc{0,1,2,3,4,5,6,S}.d`

instead of the more cumbersome:
```sh
for runlevel in 0 1 2 3 4 5 6 S
do
  mkdir rc${runlevel}.d
done
```

And `ls` can be done recursively, too:
```
$ cd /
$ ls -ld {,usr,usr/local}/{bin,sbin,lib}
drwxr-xr-x    2 root     root         4096 Oct 26 01:00 /bin
drwxr-xr-x    6 root     root         4096 Jan 16 17:09 /lib
drwxr-xr-x    2 root     root         4096 Oct 27 00:02 /sbin
drwxr-xr-x    2 root     root        40960 Jan 16 19:35 usr/bin
drwxr-xr-x   83 root     root        49152 Jan 16 17:23 usr/lib
drwxr-xr-x    2 root     root         4096 Jan 16 22:22 usr/local/bin
drwxr-xr-x    3 root     root         4096 Jan 16 19:17 usr/local/lib
drwxr-xr-x    2 root     root         4096 Dec 28 00:44 usr/local/sbin
drwxr-xr-x    2 root     root         8192 Dec 27 02:10 usr/sbin
```

# Test

Test is used by virtually every shell script written. It may not seem that way, because `test` is not often called directly. `test` is more frequently called as `[`. `[` is a symbolic link to `test`, just to make shell programs more readable. It is also normally a shell builtin (which means that the shell itself will interpret `[` as meaning `test`, even if your Unix environment is set up differently):

```
$ type [
[ is a shell builtin
$ which [
/usr/bin/[
$ ls -l /usr/bin/[
lrwxrwxrwx 1 root root 4 Mar 27 2000 /usr/bin/[ -> test
$ ls -l /usr/bin/test
-rwxr-xr-x 1 root root 35368 Mar 27  2000 /usr/bin/test
```

This means that '`[`' is actually a program, just like `ls` and other programs, so it must be surrounded by spaces:
```
if [$foo = "bar" ]
```

will not work; it is interpreted as `if test$foo = "bar" ]`, which is a '`]`' without a beginning '`[`'. Put spaces around all your operators. I've highlighted the mandatory spaces with the word **'SPACE'** .

> Note: Some shells also accept "`==`" for string comparison; this is not portable, a single "`=`" should be used for strings, or "`-eq`" for integers.

Test is a simple but powerful comparison utility. For full details, run `man test` on your system, but here are some usages and typical examples.

Test is most often invoked indirectly via the `if` and `while` statements. It is also the reason you will come into difficulties if you create a program called `test` and try to run it, as this shell builtin will be called instead of your program!  The syntax for `if...then...else...` is:
```sh
if [ ... ]
then
  # if-code
else
  # else-code
fi
```

Also, be aware of the syntax - the "`if [ ... ]`" and the "`then`" commands must be on different lines. Alternatively, the semicolon "`;`" can separate them:
```sh
if [ ... ]; then
  # do something
fi
```

You can also use the `elif`, like this:
```sh
if  [ something ]; then
 echo "Something"
 elif [ something_else ]; then
   echo "Something else"
 else
   echo "None of the above"
fi
```
This will `echo "Something"` if the `[ something ]` test succeeds, otherwise it will test `[ something_else ]`, and `echo "Something else"` if that succeeds. If all else fails, it will `echo "None of the above"`.


# Case

The `case` statsement saves going through a whole set of `if ... then ... else` statements. Its syntax is really simple:

```sh
#!/bin/sh

echo "Please talk to me ..."
while :
do 
	read INPUT_STRING
	case $INPUT_STRING in
		hello)
			echo "Hello yourself!"
			;;
		bye)
			echo "See you again!"
			break
			;;
		*)
			echo "Sorry I don't understand"
			;;
	esac
done
```


# Variables 2

The first set of variables we will look at are `$0 ... $9` and `$#`. The variable `$0` is the basename of the program as it was called. `$1...$9` are the first 9 additional parameters the script was called with. The variable `$@` is all parameters. The variable `$*` is similar, but does not preserve any whitespace and quoting, so "File with spaces" becomes "File", "with", and "spaces". `$#` is the number of parameters the script was called with. 

```sh
#!/bin/sh
echo "I was called with $# parameters"
echo "My name is $0"
echo "My first parameter is $1"
```

The othere two main variables set are `$$` and `$!`. These are both process numbers. The `$$` variable is the PID of the currently running shell. This can be useful for creating temporary files, such as `/tmp/my-script.$$` which is useful if many instances of the script could be run at the same time, and they all need their own temporary files. 

The `$!` variable is the PID of the last run background processd. This is useful to keep track of the process as it gets on with its job. 

Another interesting vardfiable is `IFS`. This is the _Interfal Field Separator_. The default value is `SPACE TAB NEWLINE`, but if you are changing it, it's easier to take a copy as shown:

```sh
#!/bin/sh

old_IFS="$IFS"
IFS=: # Set IFS as colon
echo "Please input some data separated by colons"
read x y z
IFS=$old_IFS 
echo "x is $x y is $y z is $z"
```


# Functions

```sh
#!/bin/sh

add_a_user() {
USER=$1
PASSWORD=$2
COMMENTS=$@
echo "Adding user $USER"
echo useradd -c "$COMMENTS" $USER
echo passwd $USER $PASSWORD
}

```

