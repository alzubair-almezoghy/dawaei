import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingStart.
  ///
  /// In en, this message translates to:
  /// **'All set'**
  String get onboardingStart;

  /// No description provided for @onboardingRemindersTitle.
  ///
  /// In en, this message translates to:
  /// **'Your medicine, right on time'**
  String get onboardingRemindersTitle;

  /// No description provided for @onboardingRemindersBody.
  ///
  /// In en, this message translates to:
  /// **'Clear reminders help you remember when it is time for each medicine.'**
  String get onboardingRemindersBody;

  /// No description provided for @onboardingOrganizeTitle.
  ///
  /// In en, this message translates to:
  /// **'All your medicines in one place'**
  String get onboardingOrganizeTitle;

  /// No description provided for @onboardingOrganizeBody.
  ///
  /// In en, this message translates to:
  /// **'Organize medication times and review medicine details with ease.'**
  String get onboardingOrganizeBody;

  /// No description provided for @onboardingTrackTitle.
  ///
  /// In en, this message translates to:
  /// **'Stay on top of every dose'**
  String get onboardingTrackTitle;

  /// No description provided for @onboardingTrackBody.
  ///
  /// In en, this message translates to:
  /// **'Mark doses as taken and keep a clear view of the daily schedule.'**
  String get onboardingTrackBody;

  /// No description provided for @onboardingRoutineTitle.
  ///
  /// In en, this message translates to:
  /// **'Let’s set up your routine!'**
  String get onboardingRoutineTitle;

  /// No description provided for @onboardingRoutineBody.
  ///
  /// In en, this message translates to:
  /// **'Choose any of the categories you’d like to include.'**
  String get onboardingRoutineBody;

  /// No description provided for @onboardingCategoryMedications.
  ///
  /// In en, this message translates to:
  /// **'Medications'**
  String get onboardingCategoryMedications;

  /// No description provided for @onboardingCategoryMedicationsBody.
  ///
  /// In en, this message translates to:
  /// **'Add medicines to your treatment plan for reminders and dose tracking.'**
  String get onboardingCategoryMedicationsBody;

  /// No description provided for @onboardingCategoryMeasurements.
  ///
  /// In en, this message translates to:
  /// **'Measurements'**
  String get onboardingCategoryMeasurements;

  /// No description provided for @onboardingCategoryMeasurementsBody.
  ///
  /// In en, this message translates to:
  /// **'Record health data such as blood pressure, weight, or blood sugar.'**
  String get onboardingCategoryMeasurementsBody;

  /// No description provided for @onboardingFinalStepLabel.
  ///
  /// In en, this message translates to:
  /// **'Your final step'**
  String get onboardingFinalStepLabel;

  /// No description provided for @onboardingSetupProgress.
  ///
  /// In en, this message translates to:
  /// **'Setup progress'**
  String get onboardingSetupProgress;

  /// No description provided for @measurementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Health measurements'**
  String get measurementsTitle;

  /// No description provided for @measurementsSetupBody.
  ///
  /// In en, this message translates to:
  /// **'Save at least one health reading to complete measurement setup.'**
  String get measurementsSetupBody;

  /// No description provided for @measurementType.
  ///
  /// In en, this message translates to:
  /// **'Measurement type'**
  String get measurementType;

  /// No description provided for @measurementWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get measurementWeight;

  /// No description provided for @measurementBloodPressure.
  ///
  /// In en, this message translates to:
  /// **'Blood pressure'**
  String get measurementBloodPressure;

  /// No description provided for @measurementBloodSugar.
  ///
  /// In en, this message translates to:
  /// **'Blood sugar'**
  String get measurementBloodSugar;

  /// No description provided for @measurementValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get measurementValue;

  /// No description provided for @measurementUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get measurementUnit;

  /// No description provided for @measurementAdd.
  ///
  /// In en, this message translates to:
  /// **'Save measurement'**
  String get measurementAdd;

  /// No description provided for @measurementSaved.
  ///
  /// In en, this message translates to:
  /// **'Measurement saved.'**
  String get measurementSaved;

  /// No description provided for @measurementRecords.
  ///
  /// In en, this message translates to:
  /// **'Saved measurements'**
  String get measurementRecords;

  /// No description provided for @measurementSearch.
  ///
  /// In en, this message translates to:
  /// **'Search measurements'**
  String get measurementSearch;

  /// No description provided for @commonMeasurements.
  ///
  /// In en, this message translates to:
  /// **'Common measurements'**
  String get commonMeasurements;

  /// No description provided for @allMeasurements.
  ///
  /// In en, this message translates to:
  /// **'All measurements'**
  String get allMeasurements;

  /// No description provided for @measurementNoResults.
  ///
  /// In en, this message translates to:
  /// **'No measurements match your search.'**
  String get measurementNoResults;

  /// No description provided for @measurementRecipientQuestion.
  ///
  /// In en, this message translates to:
  /// **'Who is this reminder for?'**
  String get measurementRecipientQuestion;

  /// No description provided for @measurementSelf.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get measurementSelf;

  /// No description provided for @measurementAddRecipient.
  ///
  /// In en, this message translates to:
  /// **'Add care recipient'**
  String get measurementAddRecipient;

  /// No description provided for @measurementRecipientName.
  ///
  /// In en, this message translates to:
  /// **'Care recipient name'**
  String get measurementRecipientName;

  /// No description provided for @measurementContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get measurementContinue;

  /// No description provided for @measurementEntryBody.
  ///
  /// In en, this message translates to:
  /// **'Enter a reading and unit to save this measurement.'**
  String get measurementEntryBody;

  /// No description provided for @medicationRecipientTitle.
  ///
  /// In en, this message translates to:
  /// **'Who is this medicine for?'**
  String get medicationRecipientTitle;

  /// No description provided for @medicationRecipientBody.
  ///
  /// In en, this message translates to:
  /// **'If you manage treatment for loved ones, create separate profiles to support each person and help them stay on track.'**
  String get medicationRecipientBody;

  /// No description provided for @medicationRecipientAdd.
  ///
  /// In en, this message translates to:
  /// **'Add a care recipient'**
  String get medicationRecipientAdd;

  /// No description provided for @medicationRecipientLater.
  ///
  /// In en, this message translates to:
  /// **'Remind me later'**
  String get medicationRecipientLater;

  /// No description provided for @medicationRecipientOwn.
  ///
  /// In en, this message translates to:
  /// **'I only manage my own treatment'**
  String get medicationRecipientOwn;

  /// No description provided for @medicationRecipientSupport.
  ///
  /// In en, this message translates to:
  /// **'You can add and manage care recipients later in Settings.'**
  String get medicationRecipientSupport;

  /// No description provided for @careRecipientCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a care recipient'**
  String get careRecipientCreateTitle;

  /// No description provided for @careRecipientRelationship.
  ///
  /// In en, this message translates to:
  /// **'Relationship'**
  String get careRecipientRelationship;

  /// No description provided for @manageCareRecipients.
  ///
  /// In en, this message translates to:
  /// **'Manage care recipients'**
  String get manageCareRecipients;

  /// No description provided for @careRecipientsEmpty.
  ///
  /// In en, this message translates to:
  /// **'You have not added any care recipients yet.'**
  String get careRecipientsEmpty;

  /// No description provided for @removeCareRecipient.
  ///
  /// In en, this message translates to:
  /// **'Remove this care recipient?'**
  String get removeCareRecipient;

  /// No description provided for @removeCareRecipientBody.
  ///
  /// In en, this message translates to:
  /// **'Saved medications will remain, but they will no longer be linked to this profile.'**
  String get removeCareRecipientBody;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Dawaei'**
  String get appTitle;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get home;

  /// No description provided for @medications.
  ///
  /// In en, this message translates to:
  /// **'Medications'**
  String get medications;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'A little care, every day.'**
  String get welcome;

  /// No description provided for @greeting.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Dawaei'**
  String get greeting;

  /// No description provided for @heroBody.
  ///
  /// In en, this message translates to:
  /// **'A calmer place to organize your medication routine.'**
  String get heroBody;

  /// No description provided for @todayOverview.
  ///
  /// In en, this message translates to:
  /// **'Your day at a glance'**
  String get todayOverview;

  /// No description provided for @scheduledToday.
  ///
  /// In en, this message translates to:
  /// **'Scheduled today'**
  String get scheduledToday;

  /// No description provided for @confirmedToday.
  ///
  /// In en, this message translates to:
  /// **'Confirmed taken'**
  String get confirmedToday;

  /// No description provided for @noDosesTitle.
  ///
  /// In en, this message translates to:
  /// **'Your day starts here'**
  String get noDosesTitle;

  /// No description provided for @noDosesBody.
  ///
  /// In en, this message translates to:
  /// **'There are no scheduled doses to show. Your medication routine will appear here.'**
  String get noDosesBody;

  /// No description provided for @noRemindersToday.
  ///
  /// In en, this message translates to:
  /// **'No medication reminders are scheduled for today. Your weekly schedule is still saved.'**
  String get noRemindersToday;

  /// No description provided for @viewMedications.
  ///
  /// In en, this message translates to:
  /// **'View medications'**
  String get viewMedications;

  /// No description provided for @todaySchedule.
  ///
  /// In en, this message translates to:
  /// **'Today\'s schedule'**
  String get todaySchedule;

  /// No description provided for @nextReminder.
  ///
  /// In en, this message translates to:
  /// **'Next reminder'**
  String get nextReminder;

  /// No description provided for @noReminder.
  ///
  /// In en, this message translates to:
  /// **'No reminder scheduled'**
  String get noReminder;

  /// No description provided for @noReminderBody.
  ///
  /// In en, this message translates to:
  /// **'Enjoy a clear view of what comes next.'**
  String get noReminderBody;

  /// No description provided for @allRemindersPassed.
  ///
  /// In en, this message translates to:
  /// **'All reminders for today have passed.'**
  String get allRemindersPassed;

  /// No description provided for @privateOnDevice.
  ///
  /// In en, this message translates to:
  /// **'Private, on your device'**
  String get privateOnDevice;

  /// No description provided for @offlineReady.
  ///
  /// In en, this message translates to:
  /// **'Works offline'**
  String get offlineReady;

  /// No description provided for @medicationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your medications'**
  String get medicationsTitle;

  /// No description provided for @medicationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A place for every part of your routine.'**
  String get medicationsSubtitle;

  /// No description provided for @noMedicationsTitle.
  ///
  /// In en, this message translates to:
  /// **'A fresh start'**
  String get noMedicationsTitle;

  /// No description provided for @noMedicationsBody.
  ///
  /// In en, this message translates to:
  /// **'Your medication list is empty. Add a medication and the reminder times provided by your healthcare professional.'**
  String get noMedicationsBody;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your medication history'**
  String get historyTitle;

  /// No description provided for @historySubtitle.
  ///
  /// In en, this message translates to:
  /// **'A clearer picture, one day at a time.'**
  String get historySubtitle;

  /// No description provided for @noHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'No records yet'**
  String get noHistoryTitle;

  /// No description provided for @noHistoryBody.
  ///
  /// In en, this message translates to:
  /// **'Only doses you explicitly confirm will be recorded as taken. A reminder alone never confirms a dose.'**
  String get noHistoryBody;

  /// No description provided for @personalize.
  ///
  /// In en, this message translates to:
  /// **'Make yourself at home'**
  String get personalize;

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose what feels right for you.'**
  String get settingsSubtitle;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get system;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @privacyAndAbout.
  ///
  /// In en, this message translates to:
  /// **'Privacy & about'**
  String get privacyAndAbout;

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationSettings;

  /// No description provided for @notificationSettingsBody.
  ///
  /// In en, this message translates to:
  /// **'Choose whether Dawaei can remind you about saved medication times.'**
  String get notificationSettingsBody;

  /// No description provided for @medicationAlertSettings.
  ///
  /// In en, this message translates to:
  /// **'Medication alerts'**
  String get medicationAlertSettings;

  /// No description provided for @medicationAlertSettingsBody.
  ///
  /// In en, this message translates to:
  /// **'Choose how medication reminders sound and appear. Android can still limit alerts based on system sound modes and permissions.'**
  String get medicationAlertSettingsBody;

  /// No description provided for @standardReminderMode.
  ///
  /// In en, this message translates to:
  /// **'Standard reminder'**
  String get standardReminderMode;

  /// No description provided for @alarmReminderMode.
  ///
  /// In en, this message translates to:
  /// **'Alarm-style reminder'**
  String get alarmReminderMode;

  /// No description provided for @reminderModeHelp.
  ///
  /// In en, this message translates to:
  /// **'Alarm-style uses the alarm audio stream and a more prominent notification. It cannot change your phone\'s sound settings.'**
  String get reminderModeHelp;

  /// No description provided for @reminderSound.
  ///
  /// In en, this message translates to:
  /// **'Reminder sound'**
  String get reminderSound;

  /// No description provided for @systemReminderSound.
  ///
  /// In en, this message translates to:
  /// **'Default device sound'**
  String get systemReminderSound;

  /// No description provided for @dawaeiReminderSound.
  ///
  /// In en, this message translates to:
  /// **'Dawaei alarm tone'**
  String get dawaeiReminderSound;

  /// No description provided for @reminderVibration.
  ///
  /// In en, this message translates to:
  /// **'Vibrate with reminders'**
  String get reminderVibration;

  /// No description provided for @allowAlertsDuringDnd.
  ///
  /// In en, this message translates to:
  /// **'Allow alerts during Do Not Disturb'**
  String get allowAlertsDuringDnd;

  /// No description provided for @dndAccessGranted.
  ///
  /// In en, this message translates to:
  /// **'Do Not Disturb access is allowed'**
  String get dndAccessGranted;

  /// No description provided for @dndAccessNeeded.
  ///
  /// In en, this message translates to:
  /// **'Android approval is needed for this option'**
  String get dndAccessNeeded;

  /// No description provided for @dndAccessHelp.
  ///
  /// In en, this message translates to:
  /// **'This asks Android to let the medication channel interrupt Do Not Disturb. It does not turn DND off or change your ringer or volume. Total silence and device rules can still suppress alerts.'**
  String get dndAccessHelp;

  /// No description provided for @requestDndAccess.
  ///
  /// In en, this message translates to:
  /// **'Review Do Not Disturb access'**
  String get requestDndAccess;

  /// No description provided for @confirmDndTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow medication alerts during Do Not Disturb?'**
  String get confirmDndTitle;

  /// No description provided for @confirmDndBody.
  ///
  /// In en, this message translates to:
  /// **'Android will open its permission screen. If allowed, only Dawaei medication alerts may interrupt Do Not Disturb; the system still controls whether they are audible.'**
  String get confirmDndBody;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @testMedicationAlert.
  ///
  /// In en, this message translates to:
  /// **'Test reminder'**
  String get testMedicationAlert;

  /// No description provided for @testAlertSent.
  ///
  /// In en, this message translates to:
  /// **'A test reminder was sent using the current alert settings.'**
  String get testAlertSent;

  /// No description provided for @testAlertError.
  ///
  /// In en, this message translates to:
  /// **'Could not send the test reminder. Check notification permission.'**
  String get testAlertError;

  /// No description provided for @fullScreenAlarmStatus.
  ///
  /// In en, this message translates to:
  /// **'Full-screen alarm alert'**
  String get fullScreenAlarmStatus;

  /// No description provided for @fullScreenAllowed.
  ///
  /// In en, this message translates to:
  /// **'Android allows the alarm screen'**
  String get fullScreenAllowed;

  /// No description provided for @fullScreenUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Full-screen display is unavailable'**
  String get fullScreenUnavailable;

  /// No description provided for @fullScreenHelp.
  ///
  /// In en, this message translates to:
  /// **'Android 14 and later may restrict full-screen alerts to eligible alarm or calling apps. If unavailable, the reminder remains a notification and can open the alarm screen when tapped.'**
  String get fullScreenHelp;

  /// No description provided for @openFullScreenSettings.
  ///
  /// In en, this message translates to:
  /// **'Review full-screen access'**
  String get openFullScreenSettings;

  /// No description provided for @silentModeHelp.
  ///
  /// In en, this message translates to:
  /// **'Silent or vibrate mode may mute notification sounds on some devices. Dawaei never changes these settings. Check the device alarm volume and the Dawaei notification channel in Android Settings.'**
  String get silentModeHelp;

  /// No description provided for @exactAlarmPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Exact alarm permission'**
  String get exactAlarmPermissionTitle;

  /// No description provided for @notificationPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification permission'**
  String get notificationPermissionTitle;

  /// No description provided for @batteryOptimizationTitle.
  ///
  /// In en, this message translates to:
  /// **'Background battery limits'**
  String get batteryOptimizationTitle;

  /// No description provided for @batteryOptimizationHelp.
  ///
  /// In en, this message translates to:
  /// **'Some manufacturers may delay reminders while restricting background activity. Android scheduled notifications continue when the app is closed normally. Review battery and auto-start settings if reminders are delayed. Force-stopping Dawaei prevents alarms until you open it again.'**
  String get batteryOptimizationHelp;

  /// No description provided for @batteryOptimizationIgnored.
  ///
  /// In en, this message translates to:
  /// **'Battery optimization is not restricting Dawaei'**
  String get batteryOptimizationIgnored;

  /// No description provided for @batteryOptimizationActive.
  ///
  /// In en, this message translates to:
  /// **'Battery optimization may delay reminders'**
  String get batteryOptimizationActive;

  /// No description provided for @openBatterySettings.
  ///
  /// In en, this message translates to:
  /// **'Review battery settings'**
  String get openBatterySettings;

  /// No description provided for @openNotificationChannelSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Android alert settings'**
  String get openNotificationChannelSettings;

  /// No description provided for @notificationsAllowed.
  ///
  /// In en, this message translates to:
  /// **'Notifications are allowed'**
  String get notificationsAllowed;

  /// No description provided for @notificationsBlocked.
  ///
  /// In en, this message translates to:
  /// **'Notifications are turned off'**
  String get notificationsBlocked;

  /// No description provided for @permissionUnknown.
  ///
  /// In en, this message translates to:
  /// **'Permission status unavailable'**
  String get permissionUnknown;

  /// No description provided for @allowNotifications.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications'**
  String get allowNotifications;

  /// No description provided for @exactAlarmSettings.
  ///
  /// In en, this message translates to:
  /// **'Precise reminder access'**
  String get exactAlarmSettings;

  /// No description provided for @exactAlarmSettingsBody.
  ///
  /// In en, this message translates to:
  /// **'Precise reminders may be restricted by Android. If access is off, Dawaei uses inexact reminders when the system allows them.'**
  String get exactAlarmSettingsBody;

  /// No description provided for @exactAlarmsAllowed.
  ///
  /// In en, this message translates to:
  /// **'Precise access is allowed'**
  String get exactAlarmsAllowed;

  /// No description provided for @exactAlarmsBlocked.
  ///
  /// In en, this message translates to:
  /// **'Precise access is off; inexact reminders may be delayed'**
  String get exactAlarmsBlocked;

  /// No description provided for @openExactAlarmSettings.
  ///
  /// In en, this message translates to:
  /// **'Review precise access'**
  String get openExactAlarmSettings;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About Dawaei'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @foundationVersion.
  ///
  /// In en, this message translates to:
  /// **'Foundation build'**
  String get foundationVersion;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your privacy matters'**
  String get privacyTitle;

  /// No description provided for @privacyBody.
  ///
  /// In en, this message translates to:
  /// **'Dawaei works without an account. Your medications and preferences are stored locally on this device. The app contains no analytics, ads, or network calls. Medication data is not encrypted, so protect access to your device. Android cloud backup and device transfer are excluded for app data. You can clear local data through Android Settings → Apps → Dawaei → Storage → Clear storage. Uninstalling also removes local app data.'**
  String get privacyBody;

  /// No description provided for @disclaimerTitle.
  ///
  /// In en, this message translates to:
  /// **'A companion for organization'**
  String get disclaimerTitle;

  /// No description provided for @disclaimer.
  ///
  /// In en, this message translates to:
  /// **'Reminders are an organizational aid. They do not replace professional medical advice or determine whether medication was consumed. Follow your healthcare professional\'s instructions. Dawaei does not recommend doses or treatment.'**
  String get disclaimer;

  /// No description provided for @aboutBody.
  ///
  /// In en, this message translates to:
  /// **'An offline-first medication organizer for Arabic and English. This build includes local medication management, local reminders, dose history, and user confirmation.'**
  String get aboutBody;

  /// No description provided for @doseHistory.
  ///
  /// In en, this message translates to:
  /// **'Dose history'**
  String get doseHistory;

  /// No description provided for @adherence.
  ///
  /// In en, this message translates to:
  /// **'Adherence'**
  String get adherence;

  /// No description provided for @week.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get week;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// No description provided for @previousDay.
  ///
  /// In en, this message translates to:
  /// **'Previous day'**
  String get previousDay;

  /// No description provided for @nextDay.
  ///
  /// In en, this message translates to:
  /// **'Next day'**
  String get nextDay;

  /// No description provided for @taken.
  ///
  /// In en, this message translates to:
  /// **'Taken'**
  String get taken;

  /// No description provided for @skipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get skipped;

  /// No description provided for @missed.
  ///
  /// In en, this message translates to:
  /// **'Unconfirmed'**
  String get missed;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Awaiting confirmation'**
  String get pending;

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// No description provided for @markTaken.
  ///
  /// In en, this message translates to:
  /// **'Confirm taken'**
  String get markTaken;

  /// No description provided for @markSkipped.
  ///
  /// In en, this message translates to:
  /// **'Mark skipped'**
  String get markSkipped;

  /// No description provided for @undoConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Clear confirmation'**
  String get undoConfirmation;

  /// No description provided for @noDosesForDate.
  ///
  /// In en, this message translates to:
  /// **'No doses scheduled for this day'**
  String get noDosesForDate;

  /// No description provided for @doseStatusSaved.
  ///
  /// In en, this message translates to:
  /// **'Dose status updated.'**
  String get doseStatusSaved;

  /// No description provided for @adherenceRate.
  ///
  /// In en, this message translates to:
  /// **'Confirmed rate'**
  String get adherenceRate;

  /// No description provided for @noDueDoses.
  ///
  /// In en, this message translates to:
  /// **'No doses due in this period'**
  String get noDueDoses;

  /// No description provided for @doseHistoryNote.
  ///
  /// In en, this message translates to:
  /// **'“Unconfirmed” means the app received no confirmation; it does not prove the medication was not taken.'**
  String get doseHistoryNote;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Getting things ready…'**
  String get loading;

  /// No description provided for @settingsLoadError.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your preferences. Try again.'**
  String get settingsLoadError;

  /// No description provided for @settingsSaveError.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t save that preference. Please try again.'**
  String get settingsSaveError;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @startupError.
  ///
  /// In en, this message translates to:
  /// **'Dawaei could not finish starting. Please try again.'**
  String get startupError;

  /// No description provided for @pageNotFound.
  ///
  /// In en, this message translates to:
  /// **'This page is unavailable'**
  String get pageNotFound;

  /// No description provided for @backHome.
  ///
  /// In en, this message translates to:
  /// **'Back to today'**
  String get backHome;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @addMedication.
  ///
  /// In en, this message translates to:
  /// **'Add medication'**
  String get addMedication;

  /// No description provided for @editMedication.
  ///
  /// In en, this message translates to:
  /// **'Edit medication'**
  String get editMedication;

  /// No description provided for @saveMedication.
  ///
  /// In en, this message translates to:
  /// **'Save medication'**
  String get saveMedication;

  /// No description provided for @medicationSaved.
  ///
  /// In en, this message translates to:
  /// **'Medication saved.'**
  String get medicationSaved;

  /// No description provided for @medicationUpdated.
  ///
  /// In en, this message translates to:
  /// **'Medication updated.'**
  String get medicationUpdated;

  /// No description provided for @medicationPaused.
  ///
  /// In en, this message translates to:
  /// **'Medication paused.'**
  String get medicationPaused;

  /// No description provided for @medicationResumed.
  ///
  /// In en, this message translates to:
  /// **'Medication resumed.'**
  String get medicationResumed;

  /// No description provided for @medicationArchived.
  ///
  /// In en, this message translates to:
  /// **'Medication removed. Its dose history is kept.'**
  String get medicationArchived;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @retryDatabase.
  ///
  /// In en, this message translates to:
  /// **'Try loading medications again'**
  String get retryDatabase;

  /// No description provided for @medicationLoadError.
  ///
  /// In en, this message translates to:
  /// **'Your medication list could not be opened. Your saved data is still on this device.'**
  String get medicationLoadError;

  /// No description provided for @medicationName.
  ///
  /// In en, this message translates to:
  /// **'Medication name'**
  String get medicationName;

  /// No description provided for @dosageAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get dosageAmount;

  /// No description provided for @dosageUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get dosageUnit;

  /// No description provided for @chooseDosageUnit.
  ///
  /// In en, this message translates to:
  /// **'Choose a unit'**
  String get chooseDosageUnit;

  /// No description provided for @customUnit.
  ///
  /// In en, this message translates to:
  /// **'Write the unit'**
  String get customUnit;

  /// No description provided for @medicationForm.
  ///
  /// In en, this message translates to:
  /// **'Form'**
  String get medicationForm;

  /// No description provided for @chooseMedicationForm.
  ///
  /// In en, this message translates to:
  /// **'Choose a form'**
  String get chooseMedicationForm;

  /// No description provided for @formTablet.
  ///
  /// In en, this message translates to:
  /// **'Tablet'**
  String get formTablet;

  /// No description provided for @formCapsule.
  ///
  /// In en, this message translates to:
  /// **'Capsule'**
  String get formCapsule;

  /// No description provided for @formSyrup.
  ///
  /// In en, this message translates to:
  /// **'Syrup'**
  String get formSyrup;

  /// No description provided for @formInjection.
  ///
  /// In en, this message translates to:
  /// **'Injection'**
  String get formInjection;

  /// No description provided for @formDrops.
  ///
  /// In en, this message translates to:
  /// **'Drops'**
  String get formDrops;

  /// No description provided for @formCream.
  ///
  /// In en, this message translates to:
  /// **'Cream'**
  String get formCream;

  /// No description provided for @formOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get formOther;

  /// No description provided for @customForm.
  ///
  /// In en, this message translates to:
  /// **'Describe the form'**
  String get customForm;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End date (optional)'**
  String get endDate;

  /// No description provided for @noEndDate.
  ///
  /// In en, this message translates to:
  /// **'No end date'**
  String get noEndDate;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Instructions (optional)'**
  String get notes;

  /// No description provided for @medicationColor.
  ///
  /// In en, this message translates to:
  /// **'Card color'**
  String get medicationColor;

  /// No description provided for @noColor.
  ///
  /// In en, this message translates to:
  /// **'No color'**
  String get noColor;

  /// No description provided for @reminderSchedule.
  ///
  /// In en, this message translates to:
  /// **'Reminder schedule'**
  String get reminderSchedule;

  /// No description provided for @scheduleTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder time'**
  String get scheduleTime;

  /// No description provided for @addReminderTime.
  ///
  /// In en, this message translates to:
  /// **'Add a reminder time'**
  String get addReminderTime;

  /// No description provided for @removeReminderTime.
  ///
  /// In en, this message translates to:
  /// **'Remove reminder time'**
  String get removeReminderTime;

  /// No description provided for @repeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeat;

  /// No description provided for @everyDay.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get everyDay;

  /// No description provided for @specificDays.
  ///
  /// In en, this message translates to:
  /// **'Selected days'**
  String get specificDays;

  /// No description provided for @selectDays.
  ///
  /// In en, this message translates to:
  /// **'Choose one or more days'**
  String get selectDays;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @paused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get paused;

  /// No description provided for @pauseMedication.
  ///
  /// In en, this message translates to:
  /// **'Pause reminders'**
  String get pauseMedication;

  /// No description provided for @resumeMedication.
  ///
  /// In en, this message translates to:
  /// **'Resume reminders'**
  String get resumeMedication;

  /// No description provided for @archiveMedication.
  ///
  /// In en, this message translates to:
  /// **'Remove medication'**
  String get archiveMedication;

  /// No description provided for @emptyMedicationsAction.
  ///
  /// In en, this message translates to:
  /// **'Add your first medication'**
  String get emptyMedicationsAction;

  /// No description provided for @emptyMedicationsDescription.
  ///
  /// In en, this message translates to:
  /// **'Add your own medication and the times provided by your healthcare professional.'**
  String get emptyMedicationsDescription;

  /// No description provided for @medicineDetails.
  ///
  /// In en, this message translates to:
  /// **'Medication details'**
  String get medicineDetails;

  /// No description provided for @dosageLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get dosageLabel;

  /// No description provided for @scheduleLabel.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get scheduleLabel;

  /// No description provided for @instructions.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get instructions;

  /// No description provided for @createdAt.
  ///
  /// In en, this message translates to:
  /// **'Added on'**
  String get createdAt;

  /// No description provided for @scheduleDailySummary.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get scheduleDailySummary;

  /// No description provided for @scheduleWeekdaysSummary.
  ///
  /// In en, this message translates to:
  /// **'Selected days'**
  String get scheduleWeekdaysSummary;

  /// No description provided for @archiveConfirmationTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this medication?'**
  String get archiveConfirmationTitle;

  /// No description provided for @archiveConfirmationBody.
  ///
  /// In en, this message translates to:
  /// **'It will disappear from your medication list. Previous dose records are kept in your history.'**
  String get archiveConfirmationBody;

  /// No description provided for @invalidMedicationName.
  ///
  /// In en, this message translates to:
  /// **'Enter a medication name (up to 100 characters).'**
  String get invalidMedicationName;

  /// No description provided for @invalidDosageAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount greater than zero, with up to three decimal places.'**
  String get invalidDosageAmount;

  /// No description provided for @invalidDosageUnit.
  ///
  /// In en, this message translates to:
  /// **'Choose a unit or enter a custom unit.'**
  String get invalidDosageUnit;

  /// No description provided for @invalidMedicationDates.
  ///
  /// In en, this message translates to:
  /// **'The end date must be the same as or later than the start date.'**
  String get invalidMedicationDates;

  /// No description provided for @notesTooLong.
  ///
  /// In en, this message translates to:
  /// **'Instructions must be 1,000 characters or fewer.'**
  String get notesTooLong;

  /// No description provided for @atLeastOneReminder.
  ///
  /// In en, this message translates to:
  /// **'Add at least one reminder time.'**
  String get atLeastOneReminder;

  /// No description provided for @invalidOrDuplicateTime.
  ///
  /// In en, this message translates to:
  /// **'Choose a valid, unique time for each reminder.'**
  String get invalidOrDuplicateTime;

  /// No description provided for @invalidDailyDays.
  ///
  /// In en, this message translates to:
  /// **'Choose either every day or selected days.'**
  String get invalidDailyDays;

  /// No description provided for @selectAtLeastOneDay.
  ///
  /// In en, this message translates to:
  /// **'Select at least one day of the week.'**
  String get selectAtLeastOneDay;

  /// No description provided for @invalidMedicationColor.
  ///
  /// In en, this message translates to:
  /// **'Choose one of the available colors.'**
  String get invalidMedicationColor;

  /// No description provided for @invalidScheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Check the reminder schedule'**
  String get invalidScheduleTitle;

  /// No description provided for @dateRange.
  ///
  /// In en, this message translates to:
  /// **'{start} – {end}'**
  String dateRange(Object end, Object start);

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @noEndDateValue.
  ///
  /// In en, this message translates to:
  /// **'Ongoing'**
  String get noEndDateValue;

  /// No description provided for @alarmTitle.
  ///
  /// In en, this message translates to:
  /// **'Time for your medication'**
  String get alarmTitle;

  /// No description provided for @stopAlarm.
  ///
  /// In en, this message translates to:
  /// **'Stop alarm'**
  String get stopAlarm;

  /// No description provided for @reviewDose.
  ///
  /// In en, this message translates to:
  /// **'Review and confirm dose'**
  String get reviewDose;

  /// No description provided for @alarmConfirmationNote.
  ///
  /// In en, this message translates to:
  /// **'Stopping the alarm does not mark the dose as taken. Confirm it in dose history after taking it.'**
  String get alarmConfirmationNote;

  /// No description provided for @alarmActionError.
  ///
  /// In en, this message translates to:
  /// **'Could not stop the alarm. Try again or dismiss its notification.'**
  String get alarmActionError;

  /// No description provided for @alarmPermission.
  ///
  /// In en, this message translates to:
  /// **'Allow alarm screen'**
  String get alarmPermission;

  /// No description provided for @alarmPermissionBody.
  ///
  /// In en, this message translates to:
  /// **'Allow the alarm screen over the lock screen. Sound depends on alarm volume and device permissions.'**
  String get alarmPermissionBody;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
