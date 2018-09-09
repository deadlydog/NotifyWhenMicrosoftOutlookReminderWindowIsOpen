# Notify When Microsoft Outlook Reminder Window Is Open

## The Problem

* When the Microsoft Outlook reminder window appears, it often appears behind other windows so you do not notice it right away.
* Even if it appears on top of other windows, if you have multiple monitors you still may not notice the little window appear.

This often results in you being late to meetings or appointments simply because you did not notice the Outlook reminder.


## The Solution

This is a simple executable that will run in the background and watch for the Microsoft Outlook reminder window to open, and then perform some actions to try and make it more aparent to you that the window has opened (i.e. that a reminder has gone off).


## Settings

To access the settings, right-click the icon in the Windows system tray and choose `Settings`. You will also be prompted to view the settings the first time the application is launched.

### Configurable Alerts

The actions taken to try and grab your attention are configurable, so you can customize it to be as subtle or obtrusive as you like. Some available settings include:

* Ensure the Outlook reminders window is restored (not minimized or maximized).
* Set the Outlook reminders window to "always on top" to ensure it is not hidden behind other windows.
* Show a Windows notification when the Outlook reminders window appears.
* Display a tooltip at the mouse's position when the Outlook reminders window appears.
* Change the mouse cursor when the Outlook reminders window appears (until the window is closed).
* Display a transparent window briefly when the Outlook reminders window appears.

You can also customize how often the alerts should trigger again if the Outlook reminders window remains open.


## How To Run The App

Simply [download the executable][DownloadLatestVersionOfExecutableUrl] and run it. It will extract some additional resources to a `NotifyWhenMicrosoftOutlookReminderWindowIsOpenResources` directory, so you may want to put the executable in a directory like `C:\OutlookRemindersNotifier`, rather than leaving it on your desktop or downloads directory.


### Run Automatically When Logging Into Windows

 If you want to have it run automatically when you log into Windows, copy a shortcut to it into [your startup directory][HowToOpenStartupDirectoryInstructionsUrl].

 The steps to do this are:
 1. Right-click on the `NotifyWhenMicrosoftOutlookReminderWindowIsOpen.exe` file and choose `Create shortcut`.
 2. Right-click on the new shortcut file and choose `Cut`.
 3. Press the `Windows Key` and type `Run` to find and launch the `Run` application (or press the `Windows Key` + `r` to launch the app).
 4. In the Run application, type `shell:startup` and hit OK. This should open up your startup directory in File Explorer.
 5. Paste the shortcut into the startup directory.

That's it. Now when you log into Windows the application should start automatically.


## Limitations / Quirks

* This script triggers for any window with `Reminder(s)` in it's title, so if you saved a file with the name `I like Reminder(s).txt` and opened it in Notepad, this would trigger because that text will appear in the window's title.


## Credit

This script started from [this Stack Overflow answer][StackOverflowPostThatScriptStartedFromUrl]. I just decided to add more features and make them customizable.


<!-- Links -->
[DownloadLatestVersionOfExecutableUrl]: https://github.com/deadlydog/NotifyWhenMicrosoftOutlookReminderWindowIsOpen/releases
[HowToOpenStartupDirectoryInstructionsUrl]: https://www.thewindowsclub.com/startup-folder-in-windows-8
[StackOverflowPostThatScriptStartedFromUrl]: https://stackoverflow.com/a/35154133/602585