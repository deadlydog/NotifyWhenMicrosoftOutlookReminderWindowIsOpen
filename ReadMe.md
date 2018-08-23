# Notify When Microsoft Outlook Remind Window Is Open

## The Problem

* When the Microsoft Outlook reminder window appears, it often appears behind other windows so you do not notice it right away.
* Even if it appears on top of other windows, if you have multiple monitors you still may not notice the little window appear.

## The Solution

This is a simple executable that will run in the background and watch for the Microsoft Outlook reminder window to open, and then perform some actions to try and make it more aparent to you that the window has opened (i.e. that a reminder has gone off).

The actions taken to try and grab your attention are configurable, so you can customize it to be as subtle or obtrusive as you like (coming soon).

## Limitations / Quirks

* This script triggers for any window with `Reminder(s)` in it's title, so if you saved a file with the name `I like Reminder(s).txt` and opened it in Notepad, this would trigger because that text will appear in the window's title.