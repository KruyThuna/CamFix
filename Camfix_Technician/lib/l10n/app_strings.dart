import '../app_settings.dart';

/// Lightweight in-app localisation for the technician app. [t] returns the
/// string for the currently selected [AppLang]; entries fall back to English.
/// The whole [MaterialApp] rebuilds when the language changes, so any widget
/// that calls [t] in `build` re-translates live.
class AppStrings {
  AppStrings._();

  static String t(String key) {
    final entry = _map[key];
    if (entry == null) {
      assert(false, 'Missing i18n key: $key');
      return key;
    }
    return entry[AppSettings.instance.lang] ?? entry[AppLang.en] ?? key;
  }

  /// Localised label for a job status code (ASSIGNED / IN_PROGRESS / ...).
  static String jobStatus(String code) {
    final key = 'status${code.replaceAll('_', '')}';
    return _map.containsKey(key) ? t(key) : code.replaceAll('_', ' ');
  }

  /// Localised label for a service category. The stored value stays English
  /// (the API and admin console use it); this is display-only.
  static String category(String english) {
    const keys = {
      'Air Conditioner': 'svcAirConditioner',
      'Electrical': 'svcElectrical',
      'Appliance Repair': 'svcApplianceRepair',
      'Motorcycle': 'svcMotorcycle',
      'Car': 'svcCar',
      'Water network': 'svcWaterNetwork',
    };
    final key = keys[english];
    return key == null ? english : t(key);
  }

  static const Map<String, Map<AppLang, String>> _map = {
    // --- Common -----------------------------------------------------------
    'appName': {AppLang.en: 'CAM FIX', AppLang.km: 'CAM FIX'},
    'technician': {AppLang.en: 'Technician', AppLang.km: 'ជាងជួសជុល'},
    'camfixTechnician': {
      AppLang.en: 'CAM FIX Technician',
      AppLang.km: 'ជាង CAM FIX',
    },
    'cancel': {AppLang.en: 'Cancel', AppLang.km: 'បោះបង់'},
    'save': {AppLang.en: 'Save', AppLang.km: 'រក្សាទុក'},
    'edit': {AppLang.en: 'Edit', AppLang.km: 'កែសម្រួល'},
    'changePhoto': {AppLang.en: 'Change photo', AppLang.km: 'ប្តូររូបភាព'},
    'takePhoto': {AppLang.en: 'Take photo', AppLang.km: 'ថតរូប'},
    'chooseFromGallery': {
      AppLang.en: 'Choose from gallery',
      AppLang.km: 'ជ្រើសរើសពីវិចិត្រសាល',
    },
    'removePhoto': {AppLang.en: 'Remove photo', AppLang.km: 'លុបរូបភាព'},
    'signOut': {AppLang.en: 'Sign out', AppLang.km: 'ចាកចេញ'},
    'email': {AppLang.en: 'Email', AppLang.km: 'អ៊ីមែល'},
    'password': {AppLang.en: 'Password', AppLang.km: 'ពាក្យសម្ងាត់'},
    'phone': {AppLang.en: 'Phone', AppLang.km: 'ទូរស័ព្ទ'},
    'phoneNumber': {AppLang.en: 'Phone number', AppLang.km: 'លេខទូរស័ព្ទ'},
    'firstName': {AppLang.en: 'First name', AppLang.km: 'នាមខ្លួន'},
    'lastName': {AppLang.en: 'Last name', AppLang.km: 'នាមត្រកូល'},
    'serviceCategory': {AppLang.en: 'Service category', AppLang.km: 'ប្រភេទសេវាកម្ម'},
    'serviceArea': {AppLang.en: 'Service area', AppLang.km: 'តំបន់សេវាកម្ម'},
    'languageName': {AppLang.en: 'ខ្មែរ', AppLang.km: 'English'},
    'continueBtn': {AppLang.en: 'Continue', AppLang.km: 'បន្ត'},

    // --- Language screen -------------------------------------------------
    'chooseLanguage': {AppLang.en: 'Choose language', AppLang.km: 'ជ្រើសរើសភាសា'},
    'khmer': {AppLang.en: 'Khmer', AppLang.km: 'ភាសាខ្មែរ'},
    'english': {AppLang.en: 'English', AppLang.km: 'ភាសាអង់គ្លេស'},

    // --- Service categories (see AppStrings.category) --------------------
    'svcAirConditioner': {
      AppLang.en: 'Air Conditioner',
      AppLang.km: 'ម៉ាស៊ីនត្រជាក់',
    },
    'svcElectrical': {AppLang.en: 'Electrical', AppLang.km: 'អគ្គិសនី'},
    'svcApplianceRepair': {
      AppLang.en: 'Appliance Repair',
      AppLang.km: 'ជួសជុលគ្រឿងប្រើប្រាស់',
    },
    'svcMotorcycle': {AppLang.en: 'Motorcycle', AppLang.km: 'ម៉ូតូ'},
    'svcCar': {AppLang.en: 'Car', AppLang.km: 'ឡាន'},
    'svcWaterNetwork': {AppLang.en: 'Water network', AppLang.km: 'បណ្តាញទឹក'},

    // --- Splash ---------------------------------------------------------------
    'splashSubtitle': {AppLang.en: 'Technician', AppLang.km: 'ជាងជួសជុល'},

    // --- Login -------------------------------------------------------------
    'loginTitle': {AppLang.en: 'Technician sign in', AppLang.km: 'ការចូលរបស់ជាង'},
    'loginSubtitle': {
      AppLang.en: 'Use the email and password you registered with.',
      AppLang.km: 'ប្រើអ៊ីមែល និងពាក្យសម្ងាត់ដែលអ្នកបានចុះឈ្មោះ។',
    },
    'signInBtn': {AppLang.en: 'Sign in', AppLang.km: 'ចូល'},
    'signInWithPhone': {
      AppLang.en: 'Sign in with a phone code instead',
      AppLang.km: 'ចូលដោយប្រើលេខកូដទូរស័ព្ទជំនួសវិញ',
    },
    'newTechnicianQ': {AppLang.en: 'New technician?', AppLang.km: 'ជាងថ្មី?'},
    'createAccount': {AppLang.en: 'Create an account', AppLang.km: 'បង្កើតគណនី'},

    // --- Phone login -------------------------------------------------------
    'phoneSignIn': {AppLang.en: 'Phone sign in', AppLang.km: 'ចូលដោយទូរស័ព្ទ'},
    'phoneSignInBody': {
      AppLang.en:
          "We'll text a 6-digit code to the number on your technician account.",
      AppLang.km:
          'យើងនឹងផ្ញើលេខកូដ ៦ ខ្ទង់ទៅកាន់លេខទូរស័ព្ទនៅលើគណនីជាងរបស់អ្នក។',
    },
    'sendCode': {AppLang.en: 'Send code', AppLang.km: 'ផ្ញើលេខកូដ'},
    'enterYourPhone': {
      AppLang.en: 'Enter your phone number',
      AppLang.km: 'សូមបញ្ចូលលេខទូរស័ព្ទរបស់អ្នក',
    },

    // --- OTP -------------------------------------------------------------------
    'enterCode': {AppLang.en: 'Enter code', AppLang.km: 'បញ្ចូលលេខកូដ'},
    'sentTo': {AppLang.en: 'Sent to', AppLang.km: 'បានផ្ញើទៅ'},
    'devModeCodeFilled': {
      AppLang.en: 'Dev mode: code filled in for you',
      AppLang.km: 'របៀបសាកល្បង៖ លេខកូដត្រូវបានបំពេញឱ្យអ្នក',
    },
    'verify': {AppLang.en: 'Verify', AppLang.km: 'ផ្ទៀងផ្ទាត់'},
    'enter6DigitCode': {
      AppLang.en: 'Enter the 6-digit code',
      AppLang.km: 'សូមបញ្ចូលលេខកូដ ៦ ខ្ទង់',
    },
    'sendVerificationCode': {
      AppLang.en: 'Send verification code',
      AppLang.km: 'ផ្ញើលេខកូដផ្ទៀងផ្ទាត់',
    },
    'resendCode': {AppLang.en: 'Resend code', AppLang.km: 'ផ្ញើលេខកូដម្តងទៀត'},
    'verificationCode': {
      AppLang.en: 'Verification code',
      AppLang.km: 'លេខកូដផ្ទៀងផ្ទាត់',
    },
    'verifyPhoneFirst': {
      AppLang.en: 'Send and enter the verification code sent to your phone first',
      AppLang.km: 'សូមផ្ញើ និងបញ្ចូលលេខកូដផ្ទៀងផ្ទាត់ដែលបានផ្ញើទៅទូរស័ព្ទរបស់អ្នកសិន',
    },
    'enterPhoneFirst': {
      AppLang.en: 'Enter your phone number first',
      AppLang.km: 'សូមបញ្ចូលលេខទូរស័ព្ទរបស់អ្នកសិន',
    },
    'codeSentToPhone': {
      AppLang.en: 'Code sent - check your phone',
      AppLang.km: 'បានផ្ញើលេខកូដ — សូមពិនិត្យទូរស័ព្ទរបស់អ្នក',
    },

    // --- Register --------------------------------------------------------------
    'createAccountTitle': {AppLang.en: 'Create account', AppLang.km: 'បង្កើតគណនី'},
    'registerIntro': {
      AppLang.en: 'An admin reviews new technicians before you can take jobs.',
      AppLang.km: 'អ្នកគ្រប់គ្រងពិនិត្យជាងថ្មីមុនពេលអ្នកអាចទទួលការងារបាន។',
    },
    'passwordMin6': {
      AppLang.en: 'Password (min 6 characters)',
      AppLang.km: 'ពាក្យសម្ងាត់ (យ៉ាងតិច ៦ តួអក្សរ)',
    },
    'serviceAreaHint': {
      AppLang.en: 'e.g. Sen Sok, Phnom Penh',
      AppLang.km: 'ឧ. សែនសុខ, ភ្នំពេញ',
    },
    'registerBtn': {AppLang.en: 'Register', AppLang.km: 'ចុះឈ្មោះ'},
    'fillEveryField': {
      AppLang.en: 'Please fill in every field',
      AppLang.km: 'សូមបំពេញគ្រប់ប្រអប់ទាំងអស់',
    },

    // --- Pending / gate ------------------------------------------------------
    'checkingStatus': {
      AppLang.en: 'Checking your status…',
      AppLang.km: 'កំពុងពិនិត្យស្ថានភាពរបស់អ្នក…',
    },
    'pullToRefresh': {
      AppLang.en: 'Pull down to refresh.',
      AppLang.km: 'ទាញចុះក្រោមដើម្បីធ្វើឱ្យស្រស់។',
    },
    'notApprovedTitle': {
      AppLang.en: 'Application not approved',
      AppLang.km: 'ពាក្យស្នើសុំមិនត្រូវបានអនុម័ត',
    },
    'contactSupportDetails': {
      AppLang.en: 'Contact CAM FIX support for details.',
      AppLang.km: 'ទាក់ទងផ្នែកជំនួយ CAM FIX សម្រាប់ព័ត៌មានលម្អិត។',
    },
    'accountSuspendedTitle': {
      AppLang.en: 'Account suspended',
      AppLang.km: 'គណនីត្រូវបានផ្អាក',
    },
    'accountSuspendedBody': {
      AppLang.en:
          'Your technician account is currently suspended. Contact CAM FIX support.',
      AppLang.km:
          'គណនីជាងរបស់អ្នកកំពុងត្រូវបានផ្អាក។ សូមទាក់ទងផ្នែកជំនួយ CAM FIX។',
    },
    'waitingApprovalTitle': {
      AppLang.en: 'Waiting for approval',
      AppLang.km: 'កំពុងរង់ចាំការអនុម័ត',
    },
    'waitingApprovalBody': {
      AppLang.en:
          "An admin is reviewing your registration. You'll get an email once you're approved — pull down to check again.",
      AppLang.km:
          'អ្នកគ្រប់គ្រងកំពុងពិនិត្យការចុះឈ្មោះរបស់អ្នក។ អ្នកនឹងទទួលបានអ៊ីមែលនៅពេលត្រូវបានអនុម័ត — ទាញចុះក្រោមដើម្បីពិនិត្យម្តងទៀត។',
    },

    // --- Home --------------------------------------------------------------
    'tabActive': {AppLang.en: 'Active', AppLang.km: 'កំពុងដំណើរការ'},
    'tabHistory': {AppLang.en: 'History', AppLang.km: 'ប្រវត្តិ'},
    'tooltipProfile': {AppLang.en: 'Profile', AppLang.km: 'ប្រវត្តិរូប'},
    'tooltipNotifications': {AppLang.en: 'Notifications', AppLang.km: 'ការជូនដំណឹង'},
    'onlineSharingLocation': {
      AppLang.en: "You're online — sharing your location",
      AppLang.km: 'អ្នកកំពុងអនឡាញ — កំពុងចែករំលែកទីតាំងរបស់អ្នក',
    },
    'offline': {AppLang.en: "You're offline", AppLang.km: 'អ្នកកំពុងក្រៅបណ្តាញ'},
    'noActiveJobs': {
      AppLang.en: 'No active jobs right now.',
      AppLang.km: 'មិនមានការងារកំពុងដំណើរការទេឥឡូវនេះ។',
    },
    'noPastJobs': {
      AppLang.en: 'No past jobs yet.',
      AppLang.km: 'មិនទាន់មានការងារពីមុនទេ។',
    },

    // --- Job detail -------------------------------------------------------
    'job': {AppLang.en: 'Job', AppLang.km: 'ការងារ'},
    'jobHash': {AppLang.en: 'Job #', AppLang.km: 'ការងារ #'},
    'declineJobQ': {AppLang.en: 'Decline this job?', AppLang.km: 'បដិសេធការងារនេះ?'},
    'declineJobBody': {
      AppLang.en: 'It will go back to the dispatcher to reassign.',
      AppLang.km: 'វានឹងត្រឡប់ទៅអ្នកចាត់ចែងវិញដើម្បីចាត់តាំងឡើងវិញ។',
    },
    'decline': {AppLang.en: 'Decline', AppLang.km: 'បដិសេធ'},
    'customer': {AppLang.en: 'Customer', AppLang.km: 'អតិថិជន'},
    'address': {AppLang.en: 'Address', AppLang.km: 'អាសយដ្ឋាន'},
    'description': {AppLang.en: 'Description', AppLang.km: 'ការពិពណ៌នា'},
    'onMyWay': {AppLang.en: "I'm on my way", AppLang.km: 'ខ្ញុំកំពុងធ្វើដំណើរទៅ'},
    'iveArrived': {AppLang.en: "I've arrived", AppLang.km: 'ខ្ញុំបានមកដល់'},
    'startJob': {AppLang.en: 'Start job', AppLang.km: 'ចាប់ផ្តើមការងារ'},
    'sendQuote': {AppLang.en: 'Send quote', AppLang.km: 'ផ្ញើសម្រង់ថ្លៃ'},
    'sendRevisedQuote': {AppLang.en: 'Send revised quote', AppLang.km: 'ផ្ញើសម្រង់ថ្លៃថ្មី'},
    'quoteFormTitle': {AppLang.en: 'Repair quote', AppLang.km: 'សម្រង់ថ្លៃជួសជុល'},
    'quoteFormIntro': {
      AppLang.en: 'Break down the cost — the customer sees exactly this before they accept.',
      AppLang.km: 'បំបែកតម្លៃ — អតិថិជននឹងឃើញព័ត៌មាននេះពិតប្រាកដមុននឹងទទួលយក។',
    },
    'quoteFormInspection': {AppLang.en: 'Inspection fee', AppLang.km: 'ថ្លៃត្រួតពិនិត្យ'},
    'quoteFormLabor': {AppLang.en: 'Labor cost', AppLang.km: 'ថ្លៃការងារ'},
    'quoteFormParts': {AppLang.en: 'Parts cost', AppLang.km: 'ថ្លៃគ្រឿងបន្លាស់'},
    'quoteFormTravel': {AppLang.en: 'Travel fee', AppLang.km: 'ថ្លៃធ្វើដំណើរ'},
    'quoteFormReason': {AppLang.en: 'What did you find? (optional)', AppLang.km: 'អ្នករកឃើញអ្វី? (មិនចាំបាច់)'},
    'quoteFormReasonHint': {
      AppLang.en: 'e.g. compressor damaged, needs a new part',
      AppLang.km: 'ឧ. ម៉ាស៊ីនខូច ត្រូវការគ្រឿងបន្លាស់ថ្មី',
    },
    'quoteFormTotal': {AppLang.en: 'Total', AppLang.km: 'សរុប'},
    'quoteFormSubmit': {AppLang.en: 'Send to customer', AppLang.km: 'ផ្ញើទៅអតិថិជន'},
    'quoteSentSuccess': {AppLang.en: 'Quote sent', AppLang.km: 'សម្រង់ថ្លៃត្រូវបានផ្ញើ'},
    'waitingForCustomerDecision': {
      AppLang.en: 'Waiting for the customer to accept or decline your quote.',
      AppLang.km: 'កំពុងរង់ចាំអតិថិជនទទួលយក ឬបដិសេធសម្រង់ថ្លៃរបស់អ្នក។',
    },
    'quoteWasDeclinedInfo': {
      AppLang.en: 'The customer declined your last quote. Send a revised one, or decline the job.',
      AppLang.km: 'អតិថិជនបានបដិសេធសម្រង់ថ្លៃចុងក្រោយរបស់អ្នក។ សូមផ្ញើសម្រង់ថ្លៃថ្មី ឬបដិសេធការងារនេះ។',
    },
    'markComplete': {AppLang.en: 'Mark complete', AppLang.km: 'សម្គាល់ថាបានបញ្ចប់'},
    'noActionsForJob': {
      AppLang.en: 'No actions available for this job',
      AppLang.km: 'មិនមានសកម្មភាពសម្រាប់ការងារនេះទេ',
    },
    'couldNotOpen': {AppLang.en: 'Could not open', AppLang.km: 'មិនអាចបើកបានទេ'},

    // --- Profile --------------------------------------------------------------
    'myProfile': {AppLang.en: 'My profile', AppLang.km: 'ប្រវត្តិរូបរបស់ខ្ញុំ'},
    'name': {AppLang.en: 'Name', AppLang.km: 'ឈ្មោះ'},
    'category': {AppLang.en: 'Category', AppLang.km: 'ប្រភេទ'},
    'about': {AppLang.en: 'About', AppLang.km: 'អំពី'},
    'openingHours': {AppLang.en: 'Opening hours', AppLang.km: 'ម៉ោងបើក'},
    'rating': {AppLang.en: 'Rating', AppLang.km: 'ការវាយតម្លៃ'},
    'statusLabel': {AppLang.en: 'Status', AppLang.km: 'ស្ថានភាព'},
    'language': {AppLang.en: 'Language', AppLang.km: 'ភាសា'},
    'darkMode': {AppLang.en: 'Dark mode', AppLang.km: 'របៀបងងឹត'},

    // --- Location (GPS) --------------------------------------------------
    'locationServiceOff': {
      AppLang.en: 'Location services are turned off',
      AppLang.km: 'សេវាកម្មទីតាំងត្រូវបានបិទ',
    },
    'locationPermissionDenied': {
      AppLang.en: 'Location permission denied',
      AppLang.km: 'ការអនុញ្ញាតទីតាំងត្រូវបានបដិសេធ',
    },
    'locationFailed': {
      AppLang.en: "Couldn't get your location",
      AppLang.km: 'មិនអាចទាញយកទីតាំងរបស់អ្នកបានទេ',
    },
    'gettingLocation': {
      AppLang.en: 'Getting location…',
      AppLang.km: 'កំពុងទាញយកទីតាំង…',
    },
    'searchLocationHint': {
      AppLang.en: 'Search for a place or address',
      AppLang.km: 'ស្វែងរកកន្លែង ឬអាសយដ្ឋាន',
    },
    'useThisLocation': {
      AppLang.en: 'Use this location',
      AppLang.km: 'ប្រើទីតាំងនេះ',
    },
    'pickOnMap': {
      AppLang.en: 'Pick on map',
      AppLang.km: 'ជ្រើសរើសលើផែនទី',
    },

    // --- Notifications screen ----------------------------------------------
    'notifications': {AppLang.en: 'Notifications', AppLang.km: 'ការជូនដំណឹង'},
    'markAllRead': {
      AppLang.en: 'Mark all read',
      AppLang.km: 'សម្គាល់ថាបានអានទាំងអស់',
    },
    'noNotificationsYet': {
      AppLang.en: 'No notifications yet',
      AppLang.km: 'មិនទាន់មានការជូនដំណឹងទេ',
    },
    'justNow': {AppLang.en: 'just now', AppLang.km: 'អម្បាញ់មិញ'},
    'minAgo': {AppLang.en: 'min ago', AppLang.km: 'នាទីមុន'},
    'hrAgo': {AppLang.en: 'h ago', AppLang.km: 'ម៉ោងមុន'},
    'dayAgo': {AppLang.en: 'd ago', AppLang.km: 'ថ្ងៃមុន'},

    // --- Job status labels (see AppStrings.jobStatus) --------------------
    'statusASSIGNED': {AppLang.en: 'Assigned', AppLang.km: 'បានចាត់តាំង'},
    'statusONTHEWAY': {AppLang.en: 'On the way', AppLang.km: 'កំពុងធ្វើដំណើរមក'},
    'statusARRIVED': {AppLang.en: 'Arrived', AppLang.km: 'បានមកដល់'},
    'statusQUOTEPENDING': {AppLang.en: 'Quote sent', AppLang.km: 'បានផ្ញើសម្រង់ថ្លៃ'},
    'statusINPROGRESS': {AppLang.en: 'In progress', AppLang.km: 'កំពុងដំណើរការ'},
    'statusCOMPLETED': {AppLang.en: 'Completed', AppLang.km: 'បានបញ្ចប់'},
    'statusREQUESTED': {AppLang.en: 'Requested', AppLang.km: 'បានស្នើសុំ'},
    'statusCANCELLED': {AppLang.en: 'Cancelled', AppLang.km: 'បានលុបចោល'},

    // --- Approval / account status (Profile "Status" row) ---------------
    'apPENDING': {AppLang.en: 'Pending', AppLang.km: 'កំពុងរង់ចាំ'},
    'apAPPROVED': {AppLang.en: 'Approved', AppLang.km: 'បានអនុម័ត'},
    'apREJECTED': {AppLang.en: 'Rejected', AppLang.km: 'បានបដិសេធ'},
    'acACTIVE': {AppLang.en: 'Active', AppLang.km: 'សកម្ម'},
    'acSUSPENDED': {AppLang.en: 'Suspended', AppLang.km: 'ត្រូវបានផ្អាក'},

    // --- Chat -------------------------------------------------------------
    'message': {AppLang.en: 'Message', AppLang.km: 'សារ'},
    'messageField': {AppLang.en: 'Message', AppLang.km: 'សារ'},
    'today': {AppLang.en: 'Today', AppLang.km: 'ថ្ងៃនេះ'},
    'sayHello': {
      AppLang.en: 'No messages yet - say hello!',
      AppLang.km: 'មិនទាន់មានសារទេ - សូមសួរសុខទុក្ខ!',
    },
  };

  /// Localised approval status (PENDING/APPROVED/REJECTED).
  static String approval(String code) {
    final key = 'ap${code.toUpperCase()}';
    return _map.containsKey(key) ? t(key) : code;
  }

  /// Localised account status (ACTIVE/SUSPENDED).
  static String account(String code) {
    final key = 'ac${code.toUpperCase()}';
    return _map.containsKey(key) ? t(key) : code;
  }
}
