// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Klear';

  @override
  String get appTagline => 'Spotless on the go';

  @override
  String get homeWelcome => 'Welcome to Klear';

  @override
  String get homeSubtitle => 'Book a car wash at your place, at your time.';

  @override
  String get btnBookNow => 'Book now';

  @override
  String get btnViewServices => 'View services';

  @override
  String get servicesTitle => 'Our services';

  @override
  String get serviceInterior => 'Interior Cleaning';

  @override
  String get serviceExterior => 'Exterior Wash';

  @override
  String get serviceFull => 'Full Care Package';

  @override
  String get serviceInteriorDesc =>
      'Deep interior vacuum and wipe with quality materials.';

  @override
  String get serviceExteriorDesc => 'Premium exterior wash and rinse.';

  @override
  String get serviceFullDesc => 'Comprehensive inside-and-out cleaning.';

  @override
  String get navHome => 'Home';

  @override
  String get navServices => 'Services';

  @override
  String get navOrders => 'My Orders';

  @override
  String get navAccount => 'Account';

  @override
  String get errorLoadingServices =>
      'Could not load services. Please try again.';

  @override
  String get noServices => 'No services available yet.';

  @override
  String get ordersEmptyTitle => 'No orders yet';

  @override
  String get ordersEmptySubtitle =>
      'When you book a wash, it will appear here.';

  @override
  String get accountGuest => 'Guest user';

  @override
  String get accountSignInHint =>
      'Sign in to manage bookings and view your history.';

  @override
  String get signIn => 'Sign in';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get selectService => 'Select a service';

  @override
  String get serviceSelected => 'Service selected';

  @override
  String get enterAddress => 'Enter address';

  @override
  String get addressLabel => 'Address';

  @override
  String get addressHint => 'Street, city, neighborhood';

  @override
  String get addressRequired => 'Please enter an address';

  @override
  String get addressSaved => 'Address saved';

  @override
  String get continueLabel => 'Continue';

  @override
  String get selectDateTime => 'Select date & time';

  @override
  String get selectDate => 'Select date';

  @override
  String get selectTime => 'Select time';

  @override
  String get notSelected => 'Not selected';

  @override
  String get dateTimeSaved => 'Date and time saved';

  @override
  String get confirmBooking => 'Confirm booking';

  @override
  String get bookingSummary => 'Booking summary';

  @override
  String get serviceLabel => 'Service';

  @override
  String get dateTimeLabel => 'Date & time';

  @override
  String get totalPrice => 'Total';

  @override
  String get confirm => 'Confirm';

  @override
  String get cancelBooking => 'Cancel';

  @override
  String get bookingConfirmed => 'Booking confirmed!';

  @override
  String get bookingConfirmedMessage =>
      'Your car wash has been scheduled. We\'ll see you soon!';

  @override
  String get done => 'Done';

  @override
  String get welcomeTitle => 'Welcome to Klear';

  @override
  String get welcomeSubtitle =>
      'To get started, create an account with your email';

  @override
  String get emailAddress => 'Email address';

  @override
  String get emailRequired => 'Please enter your email address';

  @override
  String get emailInvalid => 'Invalid email address';

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get phoneRequired => 'Please enter your phone number';

  @override
  String get phoneInvalid => 'Invalid phone number';

  @override
  String get verifyCode => 'Verify code';

  @override
  String get otpSent => 'Enter the verification code';

  @override
  String get otpSentSubtitle => 'We sent a 6-digit code to your email';

  @override
  String get otpCode => 'Code';

  @override
  String get otpInvalid => 'Please enter the 6-digit code';

  @override
  String get verify => 'Verify';

  @override
  String get setupProfile => 'Set up your profile';

  @override
  String get profileSetupSubtitle =>
      'Tell us a bit about yourself so we can serve you better';

  @override
  String get fullName => 'Full name';

  @override
  String get fullNameHint => 'Your name';

  @override
  String get fullNameRequired => 'Please enter your name';

  @override
  String get useCurrentLocation => 'Use my current location';

  @override
  String get locationServiceDisabled =>
      'Location services are disabled. Please enable them in settings.';

  @override
  String get locationPermissionDenied =>
      'Location permission denied. Tap to retry.';

  @override
  String get save => 'Save';

  @override
  String get signOut => 'Sign out';

  @override
  String get signInRequired => 'Please sign in to continue';

  @override
  String get signInToBook => 'Sign in to book a wash';

  @override
  String get profile => 'Profile';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get language => 'Language';

  @override
  String get languageArabic => 'Arabic';

  @override
  String get languageEnglish => 'English';

  @override
  String get signInTitle => 'Sign in';

  @override
  String get signInSubtitle =>
      'Welcome back! Enter your email to receive a login code';

  @override
  String get createAccount => 'Create account';

  @override
  String get createAccountTitle => 'Create account';

  @override
  String get createAccountSubtitle =>
      'Create your new account to start washing your car';

  @override
  String get haveAccount => 'Already have an account? Sign in';

  @override
  String get noAccount => 'No account yet? Create one';

  @override
  String approxMinutes(String minutes) {
    return '≈ $minutes min';
  }

  @override
  String get bookingCar => 'Car';

  @override
  String get bookingNotes => 'Notes (optional)';

  @override
  String get bookingNotesHint => 'Anything the wash team should know';

  @override
  String get bookingFailed => 'Could not save your booking. Please try again.';

  @override
  String get submitting => 'Submitting…';

  @override
  String get saving => 'Saving…';

  @override
  String get saveFailed => 'Could not save. Please try again.';

  @override
  String get priceEstimate => 'Cost estimate';

  @override
  String get priceBase => 'Base price';

  @override
  String get sizeAdjustment => 'Size adjustment';

  @override
  String get totalEstimate => 'Estimated total';

  @override
  String get selectCar => 'Select your car';

  @override
  String get myCars => 'My cars';

  @override
  String get myCarsSubtitle =>
      'Register your vehicles so the team can identify them';

  @override
  String get carsEmptyTitle => 'No cars yet';

  @override
  String get carsEmptySubtitle =>
      'Add your car so we can give an exact price and the wash team can identify it.';

  @override
  String get noCarsAddPrompt =>
      'You don\'t have any cars yet. Add your first one to continue the booking.';

  @override
  String get addCar => 'Add car';

  @override
  String get editCar => 'Edit car';

  @override
  String get deleteCar => 'Delete';

  @override
  String get deleteCarConfirmTitle => 'Delete this car?';

  @override
  String get deleteCarConfirmMessage =>
      'This car will be removed. You can add it again anytime.';

  @override
  String get carMake => 'Make (brand)';

  @override
  String get carMakeHint => 'e.g. Toyota';

  @override
  String get carMakeRequired => 'Please enter the car make';

  @override
  String get carModel => 'Model';

  @override
  String get carModelHint => 'e.g. Corolla';

  @override
  String get carModelRequired => 'Please enter the car model';

  @override
  String get carPlate => 'Plate number';

  @override
  String get carPlateHint => 'e.g. 1234A';

  @override
  String get carPlateRequired => 'Please enter the plate number';

  @override
  String get carSize => 'Car size';

  @override
  String get sizeSmall => 'Small';

  @override
  String get sizeMedium => 'Medium';

  @override
  String get sizeLarge => 'Large';

  @override
  String bookingStepOf(String current, String total) {
    return 'Step $current of $total';
  }

  @override
  String get bookingDetailsTitle => 'When & where';

  @override
  String get useSavedAddress => 'Use saved address';

  @override
  String get customDateTime => 'Pick another time';

  @override
  String get quickSlotToday => 'Today';

  @override
  String get quickSlotTomorrow => 'Tomorrow';

  @override
  String get quickSlotMorning => 'Morning';

  @override
  String get quickSlotAfternoon => 'Afternoon';

  @override
  String get quickSlotEvening => 'Evening';

  @override
  String get priceBeforeCarSize => 'Before car size adjustment';

  @override
  String get bookService => 'Book';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusConfirmed => 'Confirmed';

  @override
  String get statusInProgress => 'In progress';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get reviewAndPay => 'Review & Pay';

  @override
  String get paymentMethod => 'Payment method';

  @override
  String get payOnArrival => 'Pay on arrival';

  @override
  String get payOnArrivalSubtitle =>
      'Pay the captain in cash when the wash is done';

  @override
  String get onlinePaymentSoon => 'Online payment — coming soon';

  @override
  String get setDefaultCar => 'Set as default';

  @override
  String get defaultCar => 'Default';

  @override
  String get upcomingWash => 'Upcoming wash';

  @override
  String get viewDetails => 'View details';

  @override
  String get orderDetailsTitle => 'Booking details';

  @override
  String get cancelOrderTitle => 'Cancel this booking?';

  @override
  String get cancelOrderMessage =>
      'You can cancel while the booking is still pending.';

  @override
  String get cancelOrderAction => 'Cancel booking';

  @override
  String get orderCancelled => 'Booking cancelled';

  @override
  String get cancelFailed => 'Could not cancel the booking. Please try again.';

  @override
  String get locationLoading => 'Getting your location…';

  @override
  String get locationFailed => 'Could not get your location. Please try again.';

  @override
  String get basePriceNoCar => 'Base price — select a car for a precise total';
}
