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
/// import 'l10n/app_localizations.dart';
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
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Klear'**
  String get appTitle;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Spotless on the go'**
  String get appTagline;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

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

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingGetStarted;

  /// No description provided for @onboardingStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Book a wash in minutes'**
  String get onboardingStep1Title;

  /// No description provided for @onboardingStep1Body.
  ///
  /// In en, this message translates to:
  /// **'Pick a service, choose a time, and drop a pin — your car wash is booked.'**
  String get onboardingStep1Body;

  /// No description provided for @onboardingStep2Title.
  ///
  /// In en, this message translates to:
  /// **'We come to you'**
  String get onboardingStep2Title;

  /// No description provided for @onboardingStep2Body.
  ///
  /// In en, this message translates to:
  /// **'Our captain arrives at your home, office, or anywhere you park.'**
  String get onboardingStep2Body;

  /// No description provided for @onboardingStep3Title.
  ///
  /// In en, this message translates to:
  /// **'Spotless, every time'**
  String get onboardingStep3Title;

  /// No description provided for @onboardingStep3Body.
  ///
  /// In en, this message translates to:
  /// **'Quality products and a careful team leave your car fresh and shining.'**
  String get onboardingStep3Body;

  /// No description provided for @homeWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Klear'**
  String get homeWelcome;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Book a car wash at your place, at your time.'**
  String get homeSubtitle;

  /// No description provided for @btnBookNow.
  ///
  /// In en, this message translates to:
  /// **'Book now'**
  String get btnBookNow;

  /// No description provided for @btnViewServices.
  ///
  /// In en, this message translates to:
  /// **'View services'**
  String get btnViewServices;

  /// No description provided for @servicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Our services'**
  String get servicesTitle;

  /// No description provided for @serviceInterior.
  ///
  /// In en, this message translates to:
  /// **'Interior Cleaning'**
  String get serviceInterior;

  /// No description provided for @serviceExterior.
  ///
  /// In en, this message translates to:
  /// **'Exterior Wash'**
  String get serviceExterior;

  /// No description provided for @serviceFull.
  ///
  /// In en, this message translates to:
  /// **'Full Care Package'**
  String get serviceFull;

  /// No description provided for @serviceInteriorDesc.
  ///
  /// In en, this message translates to:
  /// **'Deep interior vacuum and wipe with quality materials.'**
  String get serviceInteriorDesc;

  /// No description provided for @serviceExteriorDesc.
  ///
  /// In en, this message translates to:
  /// **'Premium exterior wash and rinse.'**
  String get serviceExteriorDesc;

  /// No description provided for @serviceFullDesc.
  ///
  /// In en, this message translates to:
  /// **'Comprehensive inside-and-out cleaning.'**
  String get serviceFullDesc;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navServices.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get navServices;

  /// No description provided for @navOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get navOrders;

  /// No description provided for @navAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get navAccount;

  /// No description provided for @errorLoadingServices.
  ///
  /// In en, this message translates to:
  /// **'Could not load services. Please try again.'**
  String get errorLoadingServices;

  /// No description provided for @badgePopular.
  ///
  /// In en, this message translates to:
  /// **'Most popular'**
  String get badgePopular;

  /// No description provided for @badgeNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get badgeNew;

  /// No description provided for @badgeBestValue.
  ///
  /// In en, this message translates to:
  /// **'Best value'**
  String get badgeBestValue;

  /// No description provided for @discountLabel.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discountLabel;

  /// No description provided for @bookNow.
  ///
  /// In en, this message translates to:
  /// **'Book now'**
  String get bookNow;

  /// No description provided for @allServices.
  ///
  /// In en, this message translates to:
  /// **'All services'**
  String get allServices;

  /// No description provided for @noServices.
  ///
  /// In en, this message translates to:
  /// **'No services available yet.'**
  String get noServices;

  /// No description provided for @ordersEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No orders yet'**
  String get ordersEmptyTitle;

  /// No description provided for @ordersEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'When you book a wash, it will appear here.'**
  String get ordersEmptySubtitle;

  /// No description provided for @accountGuest.
  ///
  /// In en, this message translates to:
  /// **'Guest user'**
  String get accountGuest;

  /// No description provided for @accountSignInHint.
  ///
  /// In en, this message translates to:
  /// **'Sign in to manage bookings and view your history.'**
  String get accountSignInHint;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @selectService.
  ///
  /// In en, this message translates to:
  /// **'Select a service'**
  String get selectService;

  /// No description provided for @serviceSelected.
  ///
  /// In en, this message translates to:
  /// **'Service selected'**
  String get serviceSelected;

  /// No description provided for @enterAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter address'**
  String get enterAddress;

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressLabel;

  /// No description provided for @addressHint.
  ///
  /// In en, this message translates to:
  /// **'Street, city, neighborhood'**
  String get addressHint;

  /// No description provided for @addressRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter an address'**
  String get addressRequired;

  /// No description provided for @addressSaved.
  ///
  /// In en, this message translates to:
  /// **'Address saved'**
  String get addressSaved;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @selectDateTime.
  ///
  /// In en, this message translates to:
  /// **'Select date & time'**
  String get selectDateTime;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// No description provided for @selectTime.
  ///
  /// In en, this message translates to:
  /// **'Select time'**
  String get selectTime;

  /// No description provided for @notSelected.
  ///
  /// In en, this message translates to:
  /// **'Not selected'**
  String get notSelected;

  /// No description provided for @dateTimeSaved.
  ///
  /// In en, this message translates to:
  /// **'Date and time saved'**
  String get dateTimeSaved;

  /// No description provided for @confirmBooking.
  ///
  /// In en, this message translates to:
  /// **'Confirm booking'**
  String get confirmBooking;

  /// No description provided for @bookingSummary.
  ///
  /// In en, this message translates to:
  /// **'Booking summary'**
  String get bookingSummary;

  /// No description provided for @serviceLabel.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get serviceLabel;

  /// No description provided for @dateTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Date & time'**
  String get dateTimeLabel;

  /// No description provided for @totalPrice.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalPrice;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @cancelBooking.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelBooking;

  /// No description provided for @bookingConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Booking confirmed!'**
  String get bookingConfirmed;

  /// No description provided for @bookingConfirmedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your car wash has been scheduled. We\'ll see you soon!'**
  String get bookingConfirmedMessage;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Klear'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'To get started, create an account with your email'**
  String get welcomeSubtitle;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get emailAddress;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email address'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address'**
  String get emailInvalid;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// No description provided for @clientIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Client ID'**
  String get clientIdLabel;

  /// No description provided for @phoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number'**
  String get phoneRequired;

  /// No description provided for @phoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number'**
  String get phoneInvalid;

  /// No description provided for @verifyCode.
  ///
  /// In en, this message translates to:
  /// **'Verify code'**
  String get verifyCode;

  /// No description provided for @otpSent.
  ///
  /// In en, this message translates to:
  /// **'Enter the verification code'**
  String get otpSent;

  /// No description provided for @otpSentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to your email'**
  String get otpSentSubtitle;

  /// No description provided for @otpWillSendSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll email you a one-time code to sign in'**
  String get otpWillSendSubtitle;

  /// No description provided for @otpCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get otpCode;

  /// No description provided for @otpInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter the 6-digit code'**
  String get otpInvalid;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @setupProfile.
  ///
  /// In en, this message translates to:
  /// **'Set up your profile'**
  String get setupProfile;

  /// No description provided for @profileSetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us a bit about yourself so we can serve you better'**
  String get profileSetupSubtitle;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @fullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get fullNameHint;

  /// No description provided for @fullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get fullNameRequired;

  /// No description provided for @useCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my current location'**
  String get useCurrentLocation;

  /// No description provided for @locationServiceDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled. Please enable them in settings.'**
  String get locationServiceDisabled;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied. Tap to retry.'**
  String get locationPermissionDenied;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signInRequired.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to continue'**
  String get signInRequired;

  /// No description provided for @signInToBook.
  ///
  /// In en, this message translates to:
  /// **'Sign in to book a wash'**
  String get signInToBook;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get languageArabic;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInTitle;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back! Enter your email to receive a login code'**
  String get signInSubtitle;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @createAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccountTitle;

  /// No description provided for @createAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your new account to start washing your car'**
  String get createAccountSubtitle;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get haveAccount;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'No account yet? Create one'**
  String get noAccount;

  /// No description provided for @approxMinutes.
  ///
  /// In en, this message translates to:
  /// **'≈ {minutes} min'**
  String approxMinutes(String minutes);

  /// No description provided for @bookingCar.
  ///
  /// In en, this message translates to:
  /// **'Car'**
  String get bookingCar;

  /// No description provided for @bookingNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get bookingNotes;

  /// No description provided for @bookingNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Anything the wash team should know'**
  String get bookingNotesHint;

  /// No description provided for @bookingFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save your booking. Please try again.'**
  String get bookingFailed;

  /// No description provided for @submitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting…'**
  String get submitting;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get saving;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save. Please try again.'**
  String get saveFailed;

  /// No description provided for @priceEstimate.
  ///
  /// In en, this message translates to:
  /// **'Cost estimate'**
  String get priceEstimate;

  /// No description provided for @priceBase.
  ///
  /// In en, this message translates to:
  /// **'Base price'**
  String get priceBase;

  /// No description provided for @sizeAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Size adjustment'**
  String get sizeAdjustment;

  /// No description provided for @attrAffectsPrice.
  ///
  /// In en, this message translates to:
  /// **'Affects price'**
  String get attrAffectsPrice;

  /// No description provided for @totalEstimate.
  ///
  /// In en, this message translates to:
  /// **'Estimated total'**
  String get totalEstimate;

  /// No description provided for @selectCar.
  ///
  /// In en, this message translates to:
  /// **'Select your car'**
  String get selectCar;

  /// No description provided for @myCars.
  ///
  /// In en, this message translates to:
  /// **'My cars'**
  String get myCars;

  /// No description provided for @myCarsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Register your vehicles so the team can identify them'**
  String get myCarsSubtitle;

  /// No description provided for @carsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No cars yet'**
  String get carsEmptyTitle;

  /// No description provided for @carsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your car so we can give an exact price and the wash team can identify it.'**
  String get carsEmptySubtitle;

  /// No description provided for @noCarsAddPrompt.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any cars yet. Add your first one to continue the booking.'**
  String get noCarsAddPrompt;

  /// No description provided for @addCar.
  ///
  /// In en, this message translates to:
  /// **'Add car'**
  String get addCar;

  /// No description provided for @editCar.
  ///
  /// In en, this message translates to:
  /// **'Edit car'**
  String get editCar;

  /// No description provided for @deleteCar.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteCar;

  /// No description provided for @deleteCarConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this car?'**
  String get deleteCarConfirmTitle;

  /// No description provided for @deleteCarConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This car will be removed. You can add it again anytime.'**
  String get deleteCarConfirmMessage;

  /// No description provided for @carMake.
  ///
  /// In en, this message translates to:
  /// **'Make (brand)'**
  String get carMake;

  /// No description provided for @carMakeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Toyota'**
  String get carMakeHint;

  /// No description provided for @carMakeRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter the car make'**
  String get carMakeRequired;

  /// No description provided for @carModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get carModel;

  /// No description provided for @carModelHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Corolla'**
  String get carModelHint;

  /// No description provided for @carModelRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter the car model'**
  String get carModelRequired;

  /// No description provided for @carPlate.
  ///
  /// In en, this message translates to:
  /// **'Plate number'**
  String get carPlate;

  /// No description provided for @carPlateHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 1234A'**
  String get carPlateHint;

  /// No description provided for @carPlateRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter the plate number'**
  String get carPlateRequired;

  /// No description provided for @carSize.
  ///
  /// In en, this message translates to:
  /// **'Car size'**
  String get carSize;

  /// No description provided for @sizeSmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get sizeSmall;

  /// No description provided for @sizeMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get sizeMedium;

  /// No description provided for @sizeLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get sizeLarge;

  /// No description provided for @bookingStepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String bookingStepOf(String current, String total);

  /// No description provided for @bookingDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'When & where'**
  String get bookingDetailsTitle;

  /// No description provided for @useSavedAddress.
  ///
  /// In en, this message translates to:
  /// **'Use saved address'**
  String get useSavedAddress;

  /// No description provided for @customDateTime.
  ///
  /// In en, this message translates to:
  /// **'Pick another time'**
  String get customDateTime;

  /// No description provided for @quickSlotToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get quickSlotToday;

  /// No description provided for @quickSlotTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get quickSlotTomorrow;

  /// No description provided for @quickSlotMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get quickSlotMorning;

  /// No description provided for @quickSlotAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get quickSlotAfternoon;

  /// No description provided for @quickSlotEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get quickSlotEvening;

  /// No description provided for @priceBeforeCarSize.
  ///
  /// In en, this message translates to:
  /// **'Before car size adjustment'**
  String get priceBeforeCarSize;

  /// No description provided for @bookService.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get bookService;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get statusAccepted;

  /// No description provided for @statusOnTheWay.
  ///
  /// In en, this message translates to:
  /// **'On the way'**
  String get statusOnTheWay;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get statusInProgress;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @trackCaptain.
  ///
  /// In en, this message translates to:
  /// **'Track your captain'**
  String get trackCaptain;

  /// No description provided for @trackCaptainSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Follow your captain\'s live location'**
  String get trackCaptainSubtitle;

  /// No description provided for @captainOnTheWay.
  ///
  /// In en, this message translates to:
  /// **'Your captain is on the way'**
  String get captainOnTheWay;

  /// No description provided for @captainWashing.
  ///
  /// In en, this message translates to:
  /// **'Your captain is washing your car'**
  String get captainWashing;

  /// No description provided for @trackingLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get trackingLive;

  /// No description provided for @washPoint.
  ///
  /// In en, this message translates to:
  /// **'Wash point'**
  String get washPoint;

  /// No description provided for @captainLastSeen.
  ///
  /// In en, this message translates to:
  /// **'Last update'**
  String get captainLastSeen;

  /// No description provided for @trackNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Tracking unavailable'**
  String get trackNotAvailable;

  /// No description provided for @trackWaitingForLocation.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the captain\'s location…'**
  String get trackWaitingForLocation;

  /// No description provided for @reviewAndPay.
  ///
  /// In en, this message translates to:
  /// **'Review & Pay'**
  String get reviewAndPay;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get paymentMethod;

  /// No description provided for @payOnArrival.
  ///
  /// In en, this message translates to:
  /// **'Pay on arrival'**
  String get payOnArrival;

  /// No description provided for @payOnArrivalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pay the captain in cash when the wash is done'**
  String get payOnArrivalSubtitle;

  /// No description provided for @onlinePaymentSoon.
  ///
  /// In en, this message translates to:
  /// **'Online payment — coming soon'**
  String get onlinePaymentSoon;

  /// No description provided for @setDefaultCar.
  ///
  /// In en, this message translates to:
  /// **'Set as default'**
  String get setDefaultCar;

  /// No description provided for @defaultCar.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultCar;

  /// No description provided for @upcomingWash.
  ///
  /// In en, this message translates to:
  /// **'Upcoming wash'**
  String get upcomingWash;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get viewDetails;

  /// No description provided for @bookAgain.
  ///
  /// In en, this message translates to:
  /// **'Book again'**
  String get bookAgain;

  /// No description provided for @mostOrdered.
  ///
  /// In en, this message translates to:
  /// **'Your favorite'**
  String get mostOrdered;

  /// No description provided for @orderDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking details'**
  String get orderDetailsTitle;

  /// No description provided for @editOrderAction.
  ///
  /// In en, this message translates to:
  /// **'Edit booking'**
  String get editOrderAction;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @bookingUpdated.
  ///
  /// In en, this message translates to:
  /// **'Booking updated'**
  String get bookingUpdated;

  /// No description provided for @bookingUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your booking details have been updated.'**
  String get bookingUpdatedMessage;

  /// No description provided for @cancelOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this booking?'**
  String get cancelOrderTitle;

  /// No description provided for @cancelOrderMessage.
  ///
  /// In en, this message translates to:
  /// **'You can cancel while the booking is still pending.'**
  String get cancelOrderMessage;

  /// No description provided for @cancelOrderAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel booking'**
  String get cancelOrderAction;

  /// No description provided for @orderCancelled.
  ///
  /// In en, this message translates to:
  /// **'Booking cancelled'**
  String get orderCancelled;

  /// No description provided for @cancelFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not cancel the booking. Please try again.'**
  String get cancelFailed;

  /// No description provided for @ordersTabCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get ordersTabCurrent;

  /// No description provided for @ordersTabFinished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get ordersTabFinished;

  /// No description provided for @ordersTabCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get ordersTabCancelled;

  /// No description provided for @ordersEmptyCurrentTitle.
  ///
  /// In en, this message translates to:
  /// **'No current orders'**
  String get ordersEmptyCurrentTitle;

  /// No description provided for @ordersEmptyCurrentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your active bookings will appear here.'**
  String get ordersEmptyCurrentSubtitle;

  /// No description provided for @ordersEmptyFinishedTitle.
  ///
  /// In en, this message translates to:
  /// **'No finished orders'**
  String get ordersEmptyFinishedTitle;

  /// No description provided for @ordersEmptyFinishedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Completed washes will appear here.'**
  String get ordersEmptyFinishedSubtitle;

  /// No description provided for @ordersEmptyCancelledTitle.
  ///
  /// In en, this message translates to:
  /// **'No cancelled orders'**
  String get ordersEmptyCancelledTitle;

  /// No description provided for @ordersEmptyCancelledSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Cancelled bookings will appear here.'**
  String get ordersEmptyCancelledSubtitle;

  /// No description provided for @locationLoading.
  ///
  /// In en, this message translates to:
  /// **'Getting your location…'**
  String get locationLoading;

  /// No description provided for @locationFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not get your location. Please try again.'**
  String get locationFailed;

  /// No description provided for @basePriceNoCar.
  ///
  /// In en, this message translates to:
  /// **'Base price — select a car for a precise total'**
  String get basePriceNoCar;

  /// No description provided for @chooseOnMap.
  ///
  /// In en, this message translates to:
  /// **'Choose on map'**
  String get chooseOnMap;

  /// No description provided for @cancelLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelLabel;

  /// No description provided for @saveLabel.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveLabel;

  /// No description provided for @mapPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose location'**
  String get mapPickerTitle;

  /// No description provided for @mapSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search for a place…'**
  String get mapSearchHint;

  /// No description provided for @mapAddressLoading.
  ///
  /// In en, this message translates to:
  /// **'Getting address…'**
  String get mapAddressLoading;

  /// No description provided for @mapUseThisLocation.
  ///
  /// In en, this message translates to:
  /// **'Use this location'**
  String get mapUseThisLocation;

  /// No description provided for @mapSaveToBook.
  ///
  /// In en, this message translates to:
  /// **'Save to address book'**
  String get mapSaveToBook;

  /// No description provided for @mapSavedToBook.
  ///
  /// In en, this message translates to:
  /// **'Saved to your address book'**
  String get mapSavedToBook;

  /// No description provided for @mapSaveLabelTitle.
  ///
  /// In en, this message translates to:
  /// **'Save location'**
  String get mapSaveLabelTitle;

  /// No description provided for @mapLabelHint.
  ///
  /// In en, this message translates to:
  /// **'Label (Home, Work…)'**
  String get mapLabelHint;

  /// No description provided for @addressLabelRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a label'**
  String get addressLabelRequired;

  /// No description provided for @addressLabelHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get addressLabelHome;

  /// No description provided for @addressLabelWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get addressLabelWork;

  /// No description provided for @addressLabelOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get addressLabelOther;

  /// No description provided for @addressBookTitle.
  ///
  /// In en, this message translates to:
  /// **'Address book'**
  String get addressBookTitle;

  /// No description provided for @addressBookSelectTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose an address'**
  String get addressBookSelectTitle;

  /// No description provided for @addressAddNew.
  ///
  /// In en, this message translates to:
  /// **'Add address'**
  String get addressAddNew;

  /// No description provided for @addressBookEmpty.
  ///
  /// In en, this message translates to:
  /// **'No saved addresses yet'**
  String get addressBookEmpty;

  /// No description provided for @addressBookEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Save your regular locations to book faster'**
  String get addressBookEmptyHint;

  /// No description provided for @addressDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get addressDefault;

  /// No description provided for @addressSetDefault.
  ///
  /// In en, this message translates to:
  /// **'Set as default'**
  String get addressSetDefault;

  /// No description provided for @addressDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get addressDelete;

  /// No description provided for @addressDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this address?'**
  String get addressDeleteConfirm;

  /// No description provided for @addressDeleted.
  ///
  /// In en, this message translates to:
  /// **'Address deleted'**
  String get addressDeleted;

  /// No description provided for @pickAnotherDay.
  ///
  /// In en, this message translates to:
  /// **'Pick another day'**
  String get pickAnotherDay;

  /// No description provided for @timeAllDayTitle.
  ///
  /// In en, this message translates to:
  /// **'If you\'ll be around all day'**
  String get timeAllDayTitle;

  /// No description provided for @timeAllDayLabel.
  ///
  /// In en, this message translates to:
  /// **'Anytime 8am–6pm'**
  String get timeAllDayLabel;

  /// No description provided for @timeSpecificTitle.
  ///
  /// In en, this message translates to:
  /// **'If you\'d prefer a more specific time'**
  String get timeSpecificTitle;

  /// No description provided for @timeSpecificLabel.
  ///
  /// In en, this message translates to:
  /// **'Pick a 4-hour window'**
  String get timeSpecificLabel;

  /// No description provided for @timeWindowMorning.
  ///
  /// In en, this message translates to:
  /// **'8am–12pm'**
  String get timeWindowMorning;

  /// No description provided for @timeWindowMidday.
  ///
  /// In en, this message translates to:
  /// **'10am–2pm'**
  String get timeWindowMidday;

  /// No description provided for @timeWindowAfternoon.
  ///
  /// In en, this message translates to:
  /// **'2pm–6pm'**
  String get timeWindowAfternoon;

  /// No description provided for @timeUrgentTitle.
  ///
  /// In en, this message translates to:
  /// **'Or if you need a wash urgently!'**
  String get timeUrgentTitle;

  /// No description provided for @timeUrgentLabel.
  ///
  /// In en, this message translates to:
  /// **'Anytime today (+25%)'**
  String get timeUrgentLabel;

  /// No description provided for @availLegendFree.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get availLegendFree;

  /// No description provided for @availLegendLimited.
  ///
  /// In en, this message translates to:
  /// **'Limited'**
  String get availLegendLimited;

  /// No description provided for @availLegendFull.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get availLegendFull;

  /// No description provided for @availTeamsLine.
  ///
  /// In en, this message translates to:
  /// **'{n} wash team(s) available'**
  String availTeamsLine(int n);

  /// No description provided for @availSlotFree.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get availSlotFree;

  /// No description provided for @availSlotOneLeft.
  ///
  /// In en, this message translates to:
  /// **'One spot left'**
  String get availSlotOneLeft;

  /// No description provided for @availTodayTag.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get availTodayTag;

  /// No description provided for @availTomorrowTag.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get availTomorrowTag;

  /// No description provided for @availAllFullNote.
  ///
  /// In en, this message translates to:
  /// **'Fully booked — try another day'**
  String get availAllFullNote;

  /// No description provided for @urgentSurcharge.
  ///
  /// In en, this message translates to:
  /// **'Urgent surcharge'**
  String get urgentSurcharge;

  /// No description provided for @diagnosticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get diagnosticsTitle;

  /// No description provided for @diagnosticsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View error & workflow logs'**
  String get diagnosticsSubtitle;

  /// No description provided for @diagnosticsLogsTitle.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics — Logs'**
  String get diagnosticsLogsTitle;

  /// No description provided for @logsCopyAll.
  ///
  /// In en, this message translates to:
  /// **'Copy all'**
  String get logsCopyAll;

  /// No description provided for @logsClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get logsClear;

  /// No description provided for @logsShareWithAdmin.
  ///
  /// In en, this message translates to:
  /// **'Share with admin'**
  String get logsShareWithAdmin;

  /// No description provided for @logsShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Share with admin'**
  String get logsShareTitle;

  /// No description provided for @logsShareDescription.
  ///
  /// In en, this message translates to:
  /// **'Describe what you were doing when the error happened. The last logs will be sent automatically.'**
  String get logsShareDescription;

  /// No description provided for @logsShareHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Tapped Sign in → entered email → saw error'**
  String get logsShareHint;

  /// No description provided for @logsNoEntries.
  ///
  /// In en, this message translates to:
  /// **'No entries yet'**
  String get logsNoEntries;

  /// No description provided for @logsNoEntriesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Errors, warnings and workflow steps appear here. Every error SnackBar is also logged, so a long message never has to be retyped — just open this screen and copy.'**
  String get logsNoEntriesSubtitle;

  /// No description provided for @logsSuggestedFix.
  ///
  /// In en, this message translates to:
  /// **'Suggested fix'**
  String get logsSuggestedFix;

  /// No description provided for @logsCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get logsCopy;

  /// No description provided for @logsCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get logsCopied;

  /// No description provided for @logsCopiedAll.
  ///
  /// In en, this message translates to:
  /// **'Logs copied to clipboard'**
  String get logsCopiedAll;

  /// No description provided for @logsCleared.
  ///
  /// In en, this message translates to:
  /// **'Logs cleared'**
  String get logsCleared;

  /// No description provided for @logsEntryCopied.
  ///
  /// In en, this message translates to:
  /// **'Entry copied'**
  String get logsEntryCopied;

  /// No description provided for @logsReportSending.
  ///
  /// In en, this message translates to:
  /// **'Sending report…'**
  String get logsReportSending;

  /// No description provided for @logsReportSent.
  ///
  /// In en, this message translates to:
  /// **'Report sent'**
  String get logsReportSent;

  /// No description provided for @logsReportFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send report'**
  String get logsReportFailed;

  /// No description provided for @logsCopyLogs.
  ///
  /// In en, this message translates to:
  /// **'Copy logs'**
  String get logsCopyLogs;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get updateAvailable;

  /// No description provided for @updateRequired.
  ///
  /// In en, this message translates to:
  /// **'Update required'**
  String get updateRequired;

  /// No description provided for @updateAvailableSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update available: {current} → {latest}'**
  String updateAvailableSubtitle(String current, String latest);

  /// No description provided for @updateCurrentLatest.
  ///
  /// In en, this message translates to:
  /// **'{current} → {latest}'**
  String updateCurrentLatest(String current, String latest);

  /// No description provided for @updateChangelog.
  ///
  /// In en, this message translates to:
  /// **'Changelog'**
  String get updateChangelog;

  /// No description provided for @updateLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get updateLater;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateNow;

  /// No description provided for @updateCheck.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get updateCheck;

  /// No description provided for @updateChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get updateChecking;

  /// No description provided for @updateUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Up to date'**
  String get updateUpToDate;

  /// No description provided for @updateUpToDateWithVersion.
  ///
  /// In en, this message translates to:
  /// **'Up to date ({version})'**
  String updateUpToDateWithVersion(String version);

  /// No description provided for @updateCouldNotCheck.
  ///
  /// In en, this message translates to:
  /// **'Could not check for updates'**
  String get updateCouldNotCheck;

  /// No description provided for @updateRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'A required update is available ({version}). Please update to continue.'**
  String updateRequiredMessage(String version);

  /// No description provided for @viewLogs.
  ///
  /// In en, this message translates to:
  /// **'View logs'**
  String get viewLogs;

  /// No description provided for @shareWithAdmin.
  ///
  /// In en, this message translates to:
  /// **'Share with admin'**
  String get shareWithAdmin;

  /// No description provided for @appUpdates.
  ///
  /// In en, this message translates to:
  /// **'App updates'**
  String get appUpdates;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @chatWithCaptain.
  ///
  /// In en, this message translates to:
  /// **'Chat with captain'**
  String get chatWithCaptain;

  /// No description provided for @chatTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat with captain'**
  String get chatTitle;

  /// No description provided for @chatEmpty.
  ///
  /// In en, this message translates to:
  /// **'No messages yet — say hello to your captain'**
  String get chatEmpty;

  /// No description provided for @chatHint.
  ///
  /// In en, this message translates to:
  /// **'Type a message…'**
  String get chatHint;

  /// No description provided for @chatLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the conversation'**
  String get chatLoadError;

  /// No description provided for @sendFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send your message'**
  String get sendFailed;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequired;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
