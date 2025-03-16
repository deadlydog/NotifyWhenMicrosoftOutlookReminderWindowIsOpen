# Notify When Microsoft Outlook Reminder Window Is Open

## The Problem

- When the Microsoft Outlook reminder window appears, it often appears behind other windows so you do not notice it right away.
- Even if it appears on top of other windows, if you have multiple monitors you still may not notice the little window appear.

This often results in you being late to meetings or appointments simply because you did not notice the Outlook reminder window.

## This App's Solution

This is a simple executable that will run in the background and watch for the Microsoft Outlook reminder window to open, and then perform some actions to try and make it more apparent to you that the window has opened, so you are less likely to miss your reminders.

## Settings

To access the settings, right-click the icon in the Windows system tray and choose `Settings`.
You will also be prompted to view the settings the first time the application is launched.

### Configurable Alerts

The actions taken to try and grab your attention are configurable, so you can customize it to be as subtle or obtrusive as you like. Some available settings include:

- Ensure the Outlook reminders window is restored (not minimized or maximized).
- Set the Outlook reminders window to "always on top" to ensure it is not hidden behind other windows.
- Show a Windows notification when the Outlook reminders window appears.
- Display a tooltip at the mouse's position when the Outlook reminders window appears.
- Change the mouse cursor when the Outlook reminders window appears (until the window is closed).
- Display a transparent window briefly when the Outlook reminders window appears.

You can also customize how often the alerts should trigger again if the Outlook reminders window remains open.

![Alerts Demo Gif][AlertsDemoGif]

### Different versions of Outlook and other applications

If you are using the new version of Outlook, or want to use this app to monitor a different application, you can adjust the `Window Detection Settings`.
The alerts will trigger whenever a window whose title contains the specified text is open, and it belongs to a process with the matching process name.

| Outlook Version   | Window Title Text To Match | Process Name |
| ----------------- | -------------------------- | ------------ |
| Outlook (classic) | Reminder(s)                | Outlook.exe  |
| Outlook (new)     | Reminders                  | olk.exe      |

The settings are configured for `Outlook (classic)` by default.
If you are using the new Outlook, you will need to update the Window Title Text To Match to `Reminders` and the Process Name to `olk.exe` in the settings.
Similarly, if you are using a very old version of Outlook, you may need to update the Window Title Text To Match to what it uses in the Reminders window title.

## How To Run The App

Simply [download the executable][DownloadLatestVersionOfExecutableUrl] and run it.
It will extract some additional resources to a `NotifyWhenMicrosoftOutlookReminderWindowIsOpenResources` directory, so you may want to put the executable in a directory like `C:\OutlookRemindersNotifier`, rather than leaving it on your desktop or downloads directory.

### Run App Automatically When Logging Into Windows

 If you want to have it run automatically when you log into Windows, copy a shortcut to it into [your startup directory][HowToOpenStartupDirectoryInstructionsUrl].

 The steps to do this are:

 1. Right-click on the `NotifyWhenMicrosoftOutlookReminderWindowIsOpen.exe` file and choose `Create shortcut`.
 2. Right-click on the new shortcut file and choose `Cut`.
 3. Press the `Windows Key` and type `Run` to find and launch the `Run` application (or press the `Windows Key` + `r` to launch the app).
 4. In the Run application, type `shell:startup` and hit OK. This should open up your startup directory in File Explorer.
 5. Paste the shortcut into the startup directory.

That's it.
Now when you log into Windows the application should start automatically.

## Other Considerations

- The alerts in this app only fire when the Outlook Reminders window has been triggered by Outlook.
Unfortunately, Outlook doesn't provide the ability to get reminded one or two minutes before the event; it only offers "5 minutes before start" and "0 minutes before start".
This means that you may still be a minute or two late for the event simply because Outlook reminded you of it too late, especially if you need to walk to another room to get to the event.
The free [Outlook Better Reminders addin][OutlookBetterRemindersOutlookAddinGitHubUrl] will show a reminder 1 minute before the actual event time, allowing you to show up right on time for your events, so you may want to check it out as well.

## Credit

This script started from [this Stack Overflow answer][StackOverflowPostThatScriptStartedFromUrl].
I just decided to add more features and make them customizable.

## Donate

Donate a [toonie](https://en.wikipedia.org/wiki/Toonie) or more to me for providing this application open source and for free :)

[![paypal](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=7DDL257P2DN9A)

<!-- Links -->
[DownloadLatestVersionOfExecutableUrl]: https://github.com/deadlydog/NotifyWhenMicrosoftOutlookReminderWindowIsOpen/releases
[HowToOpenStartupDirectoryInstructionsUrl]: https://www.thewindowsclub.com/startup-folder-in-windows-8
[StackOverflowPostThatScriptStartedFromUrl]: https://stackoverflow.com/a/35154133/602585
[OutlookBetterRemindersOutlookAddinGitHubUrl]: https://ben-spiller.github.io/OutlookBetterReminders/
[AlertsDemoGif]: docs/Images/AlertsDemo.gif
