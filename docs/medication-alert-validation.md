# Medication alert validation

## Test status

The connected phone is a Samsung SCG20 running Android 16. ADB sees it as `R5CW72GYKTN`. The updated APK was not produced in this environment, so none of the device scenarios below are marked as passed. Run this matrix after a successful debug build/install.

| Scenario | Expected behavior | Actual result |
| --- | --- | --- |
| Normal sound mode | Scheduled notification plays the selected channel sound and optional vibration. Alarm mode uses Android's alarm audio attributes. | Not tested with the new APK. |
| Vibrate mode | Notification vibration follows Dawaei's vibration toggle and Android's vibration settings. Sound remains subject to the device's ringer policy. | Not tested with the new APK. |
| Silent mode | Dawaei does not change ringer mode or volume. Android/device policy may mute notification audio; check the separate alarm volume. | Not tested. No app-level override is promised. |
| Do Not Disturb | By default, DND may silence the alert. If the user enables the option and grants Notification Policy Access, the selected channel requests DND bypass. Total Silence and device policy may still block sound. | Not tested; requires explicit user approval and device mode changes. |
| Locked screen | Android posts the scheduled notification. Full-screen presentation is used only if Android grants it; otherwise the notification opens the alarm screen when tapped. | Not tested with the new APK. |
| App backgrounded / normally closed | Android's scheduled-notification receiver posts the alarm without relying on an open Flutter screen. | Not tested with the new APK. |
| Device restart | The local-notifications boot receiver restores cached scheduled alarms after boot. Reopen Dawaei to refresh the seven-day schedule horizon. | Not tested with the new APK. |
| Timezone changed | Reopening/resuming Dawaei refreshes the device timezone and reconciles schedules. A timezone change while the app remains stopped cannot be verified by the current Flutter reconciliation path. | Not tested. Reopen the app after changing time zone. |
| Medication edited or deleted | Existing repository changes trigger schedule reconciliation; outdated pending notifications are cancelled and replacements are scheduled. | Existing scheduler tests pass; no real-device test with this APK. |
| Battery restricted / manufacturer limits | Android may delay background work. Settings now shows battery status and links to Android's battery optimization screen. Samsung auto-start/sleep rules may need user configuration. | Not tested with the new APK. |
| Force-stopped app | Android may cancel or suppress alarms until the user launches Dawaei again. | Expected platform limitation; no reliability claim. |

## Manual device run

1. Install the newly built debug APK and allow Dawaei notifications.
2. In **Settings → Medication alerts**, choose alarm-style, select the tone, set vibration, and tap **Test reminder**. Confirm sound/vibration and inspect Dawaei's Android notification-channel settings.
3. Add a medication for a time about two minutes ahead. Lock the phone and verify the notification at the scheduled time.
4. Repeat with the app backgrounded and then closed normally. Verify the medication remains unconfirmed until explicitly marked taken.
5. To test Silent, Vibrate, or DND, change the device mode manually, record the alarm volume and DND policy, and restore the original modes afterward. Do not assume that alarm audio attributes defeat Silent or Total Silence.
6. For DND bypass, enable the Dawaei option, approve Notification Policy Access in Android, and verify the medication channel shows the intended bypass setting. Revoke it afterward if not desired.
7. Reboot once with a medication scheduled after restart. Then edit and delete another reminder and confirm its old notification no longer appears.
8. Change the device timezone, reopen Dawaei, and verify upcoming times are recalculated.
9. On Samsung, inspect Android **Battery → Background usage limits** and Dawaei's battery mode if a test is delayed.
