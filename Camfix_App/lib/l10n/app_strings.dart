import '../app_settings.dart';

/// Lightweight in-app localisation. [t] returns the string for the language
/// currently selected in [AppSettings]. Entries that only list an English
/// value fall back to English in both languages.
///
/// The whole [MaterialApp] is rebuilt when the language changes (see
/// `CamFixApp`), so every widget that reads [t] in its `build` re-translates
/// live — including screens already on the navigation stack.
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

  static const Map<String, Map<AppLang, String>> _map = {
    // --- Language screen -------------------------------------------------
    'chooseLanguage': {AppLang.en: 'Choose language', AppLang.km: 'ជ្រើសរើសភាសា'},
    'khmer': {AppLang.en: 'Khmer', AppLang.km: 'ភាសាខ្មែរ'},
    'english': {AppLang.en: 'English', AppLang.km: 'ភាសាអង់គ្លេស'},
    'continue': {AppLang.en: 'Continue', AppLang.km: 'បន្ត'},

    // --- Common -------------------------------------------------------------
    'cancel': {AppLang.en: 'Cancel', AppLang.km: 'បោះបង់'},
    'save': {AppLang.en: 'Save', AppLang.km: 'រក្សាទុក'},
    'done': {AppLang.en: 'Done', AppLang.km: 'រួចរាល់'},
    'successful': {AppLang.en: 'Successful', AppLang.km: 'ជោគជ័យ'},
    'seeAll': {AppLang.en: 'See All', AppLang.km: 'មើលទាំងអស់'},
    'or': {AppLang.en: 'or', AppLang.km: 'ឬ'},
    'search': {AppLang.en: 'Search', AppLang.km: 'ស្វែងរក'},
    'ok': {AppLang.en: 'OK', AppLang.km: 'យល់ព្រម'},
    'retry': {AppLang.en: 'Retry', AppLang.km: 'ព្យាយាមម្តងទៀត'},
    'copied': {AppLang.en: 'Copied', AppLang.km: 'បានចម្លង'},
    'changePhoto': {AppLang.en: 'Change photo', AppLang.km: 'ប្តូររូបភាព'},
    'takePhoto': {AppLang.en: 'Take photo', AppLang.km: 'ថតរូប'},
    'chooseFromGallery': {
      AppLang.en: 'Choose from gallery',
      AppLang.km: 'ជ្រើសរើសពីវិចិត្រសាល',
    },
    'removePhoto': {AppLang.en: 'Remove photo', AppLang.km: 'លុបរូបភាព'},
    'continueAnyway': {
      AppLang.en: 'Continue anyway',
      AppLang.km: 'បន្តទោះយ៉ាងណា',
    },

    // --- Network / connectivity ----------------------------------------
    'netOffline': {
      AppLang.en: 'No internet connection',
      AppLang.km: 'គ្មានការតភ្ជាប់អ៊ីនធឺណិត',
    },
    'netNoInternet': {
      AppLang.en: 'Connected, but no internet access',
      AppLang.km: 'បានតភ្ជាប់ ប៉ុន្តែចូលអ៊ីនធឺណិតមិនបាន',
    },
    'netCheckConnection': {
      AppLang.en: 'Check your Wi-Fi or mobile data',
      AppLang.km: 'សូមពិនិត្យ Wi-Fi ឬទិន្នន័យទូរស័ព្ទរបស់អ្នក',
    },
    'netBackOnline': {
      AppLang.en: 'Back online',
      AppLang.km: 'តភ្ជាប់អ៊ីនធឺណិតឡើងវិញ',
    },

    // --- Auth: sign in / sign up ------------------------------------------
    'signIn': {AppLang.en: 'Sign In', AppLang.km: 'ចូល'},
    'signingIn': {AppLang.en: 'Signing in…', AppLang.km: 'កំពុងចូល…'},
    'signUp': {AppLang.en: 'Sign Up', AppLang.km: 'ចុះឈ្មោះ'},
    'creatingAccount': {
      AppLang.en: 'Creating account…',
      AppLang.km: 'កំពុងបង្កើតគណនី…',
    },
    'login': {AppLang.en: 'Login', AppLang.km: 'ចូល'},
    'loginWithPhone': {
      AppLang.en: 'Login with Phone numbers',
      AppLang.km: 'ចូលដោយលេខទូរស័ព្ទ',
    },
    'continueWithGoogle': {
      AppLang.en: 'Continue with Google',
      AppLang.km: 'បន្តជាមួយ Google',
    },
    'forgotPasswordQ': {
      AppLang.en: 'Forgot password?',
      AppLang.km: 'ភ្លេចពាក្យសម្ងាត់?',
    },
    'dontHaveAccount': {
      AppLang.en: "Don't have an account? ",
      AppLang.km: 'មិនមានគណនីមែនទេ? ',
    },
    'alreadyHaveAccount': {
      AppLang.en: 'Already have an account? ',
      AppLang.km: 'មានគណនីរួចហើយ? ',
    },
    'emailField': {AppLang.en: 'Email', AppLang.km: 'អ៊ីមែល'},
    'passwordField': {AppLang.en: 'Password', AppLang.km: 'ពាក្យសម្ងាត់'},
    'confirmPasswordField': {
      AppLang.en: 'Confirm Password',
      AppLang.km: 'បញ្ជាក់ពាក្យសម្ងាត់',
    },

    // --- Auth: validation messages --------------------------------------
    'errEnterEmailAndPassword': {
      AppLang.en: 'Enter your email and password',
      AppLang.km: 'បញ្ចូលអ៊ីមែល និងពាក្យសម្ងាត់របស់អ្នក',
    },
    'errEnterValidEmail': {
      AppLang.en: 'Enter a valid email',
      AppLang.km: 'បញ្ចូលអ៊ីមែលឲ្យបានត្រឹមត្រូវ',
    },
    'errPasswordMin': {
      AppLang.en: 'Password must be at least 6 characters',
      AppLang.km: 'ពាក្យសម្ងាត់ត្រូវមានយ៉ាងតិច ៦ តួអក្សរ',
    },
    'errPasswordsDontMatch': {
      AppLang.en: 'Passwords do not match',
      AppLang.km: 'ពាក្យសម្ងាត់មិនត្រូវគ្នា',
    },
    'errEnterValidPhone': {
      AppLang.en: 'Enter a valid phone number',
      AppLang.km: 'បញ្ចូលលេខទូរស័ព្ទឲ្យបានត្រឹមត្រូវ',
    },
    'errEnter6DigitCode': {
      AppLang.en: 'Enter the 6-digit code',
      AppLang.km: 'បញ្ចូលលេខកូដ ៦ ខ្ទង់',
    },

    // --- Phone login ----------------------------------------------------
    'enterWord': {AppLang.en: 'Enter', AppLang.km: 'បញ្ចូល'},
    'phoneNumbersTitle': {AppLang.en: 'Phone numbers', AppLang.km: 'លេខទូរស័ព្ទ'},
    'sendingCode': {AppLang.en: 'Sending code…', AppLang.km: 'កំពុងផ្ញើលេខកូដ…'},

    // --- Verify code / email ------------------------------------------
    'verification': {AppLang.en: 'Verification', AppLang.km: 'ការផ្ទៀងផ្ទាត់'},
    'codeWord': {AppLang.en: 'Code', AppLang.km: 'លេខកូដ'},
    'verifyWord': {AppLang.en: 'Verify', AppLang.km: 'ផ្ទៀងផ្ទាត់'},
    'verifying': {AppLang.en: 'Verifying…', AppLang.km: 'កំពុងផ្ទៀងផ្ទាត់…'},
    'verifyTitle': {AppLang.en: 'Verify', AppLang.km: 'ផ្ទៀងផ្ទាត់'},
    'yourEmailTitle': {AppLang.en: 'Your Email', AppLang.km: 'អ៊ីមែលរបស់អ្នក'},
    'weSentCodeTo': {
      AppLang.en: 'we sent a 6-digit code to ',
      AppLang.km: 'យើងបានផ្ញើលេខកូដ ៦ ខ្ទង់ទៅ ',
    },
    'enterCodeSentTo': {
      AppLang.en: 'Enter the code sent to\n',
      AppLang.km: 'បញ្ចូលលេខកូដដែលបានផ្ញើទៅ\n',
    },
    'didntGetCode': {
      AppLang.en: "Didn't get a code? ",
      AppLang.km: 'មិនទាន់ទទួលលេខកូដ? ',
    },
    'clickToResend': {
      AppLang.en: 'Click to resend.',
      AppLang.km: 'ចុចដើម្បីផ្ញើម្តងទៀត។',
    },
    'sending': {AppLang.en: 'Sending…', AppLang.km: 'កំពុងផ្ញើ…'},
    'newCodeSent': {
      AppLang.en: 'A new code was sent',
      AppLang.km: 'បានផ្ញើលេខកូដថ្មី',
    },
    'devCodeFilled': {
      AppLang.en: 'Dev mode: code filled in for you (no delivery provider).',
      AppLang.km: 'របៀបអភិវឌ្ឍន៍៖ លេខកូដត្រូវបានបំពេញឲ្យស្រាប់ (គ្មានសេវាផ្ញើ)។',
    },
    'otpSentTitle': {
      AppLang.en: 'Verification code sent',
      AppLang.km: 'បានផ្ញើលេខកូដផ្ទៀងផ្ទាត់',
    },
    'otpSentBySms': {
      AppLang.en: 'A 6-digit code has been sent by SMS to',
      AppLang.km: 'លេខកូដ ៦ ខ្ទង់ត្រូវបានផ្ញើតាម SMS ទៅ',
    },
    'otpSentByEmail': {
      AppLang.en: 'A 6-digit code has been sent by email to',
      AppLang.km: 'លេខកូដ ៦ ខ្ទង់ត្រូវបានផ្ញើតាមអ៊ីមែលទៅ',
    },

    // --- Forgot / new password ---------------------------------------
    'forgotWord': {AppLang.en: 'Forgot', AppLang.km: 'ភ្លេច'},
    'passwordQWord': {AppLang.en: 'Password?', AppLang.km: 'ពាក្យសម្ងាត់?'},
    'enterYourEmailAddress': {
      AppLang.en: 'Enter your email address',
      AppLang.km: 'បញ្ចូលអាសយដ្ឋានអ៊ីមែលរបស់អ្នក',
    },
    'send': {AppLang.en: 'Send', AppLang.km: 'ផ្ញើ'},
    'createWord': {AppLang.en: 'Create', AppLang.km: 'បង្កើត'},
    'newPasswordTitle': {AppLang.en: 'New Password', AppLang.km: 'ពាក្យសម្ងាត់ថ្មី'},
    'newPasswordField': {AppLang.en: 'New Password', AppLang.km: 'ពាក្យសម្ងាត់ថ្មី'},
    'newPasswordHint': {
      AppLang.en:
          'Your new password must be different\nfrom previously used password',
      AppLang.km: 'ពាក្យសម្ងាត់ថ្មីរបស់អ្នកត្រូវខុសពី\nពាក្យសម្ងាត់ដែលធ្លាប់ប្រើពីមុន',
    },

    // --- Dashboard -------------------------------------------------------
    'goodMorning': {AppLang.en: 'Good Morning!', AppLang.km: 'អរុណសួស្តី!'},
    'goodAfternoon': {AppLang.en: 'Good Afternoon!', AppLang.km: 'ទិវាសួស្តី!'},
    'goodEvening': {AppLang.en: 'Good Evening!', AppLang.km: 'សាយ័ណ្ហសួស្តី!'},
    'searchForService': {
      AppLang.en: 'Search for a service',
      AppLang.km: 'ស្វែងរកសេវាកម្ម',
    },
    'bookAService': {AppLang.en: 'Book a service', AppLang.km: 'កក់សេវាកម្ម'},
    'activeJob': {AppLang.en: 'Active Job', AppLang.km: 'ការងារកំពុងដំណើរការ'},
    'active': {AppLang.en: 'Active', AppLang.km: 'កំពុងដំណើរការ'},
    'history': {AppLang.en: 'History', AppLang.km: 'ប្រវត្តិ'},
    'nearbyTechnicians': {
      AppLang.en: 'Nearby Technicians',
      AppLang.km: 'ជាងនៅជិត',
    },
    'completed': {AppLang.en: 'Completed', AppLang.km: 'បានបញ្ចប់'},
    'live': {AppLang.en: 'Live', AppLang.km: 'ផ្សាយផ្ទាល់'},
    'reorder': {AppLang.en: 'RE-ORDER', AppLang.km: 'បញ្ជាទិញឡើងវិញ'},
    'ratings': {AppLang.en: 'RATINGS', AppLang.km: 'ការវាយតម្លៃ'},
    'available': {AppLang.en: 'Available', AppLang.km: 'ទំនេរ'},
    'unavailable': {AppLang.en: 'Unavailable', AppLang.km: 'រវល់'},
    'activeJobsEmpty': {
      AppLang.en: 'Your list of Active Jobs is empty.\nPlease book a service!',
      AppLang.km: 'បញ្ជីការងាររបស់អ្នកនៅទទេ។\nសូមកក់សេវាកម្ម!',
    },
    'noCompletedJobs': {
      AppLang.en: 'No completed jobs yet.',
      AppLang.km: 'មិនទាន់មានការងារបានបញ្ចប់ទេ។',
    },

    // --- Service categories -------------------------------------------
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

    // --- Bottom navigation --------------------------------------------------
    'navHome': {AppLang.en: 'Home', AppLang.km: 'ទំព័រដើម'},
    'navService': {AppLang.en: 'Service', AppLang.km: 'សេវាកម្ម'},
    'navChat': {AppLang.en: 'Chat', AppLang.km: 'ជជែក'},
    'navProfile': {AppLang.en: 'Profile', AppLang.km: 'ប្រវត្តិរូប'},

    // --- Services screen --------------------------------------------------
    'noProvidersInCategory': {
      AppLang.en: 'No providers in this category yet.',
      AppLang.km: 'មិនទាន់មានអ្នកផ្តល់សេវាក្នុងប្រភេទនេះទេ។',
    },
    'noProvidersMatch': {
      AppLang.en: 'No providers match your search.',
      AppLang.km: 'រកមិនឃើញអ្នកផ្តល់សេវាដែលត្រូវនឹងការស្វែងរករបស់អ្នក។',
    },
    'rateOf5': {AppLang.en: 'Rate', AppLang.km: 'ពិន្ទុ'},

    // --- Chat -----------------------------------------------------------
    'noConversations': {
      AppLang.en: 'No conversations',
      AppLang.km: 'គ្មានការសន្ទនា',
    },
    'all': {AppLang.en: 'All', AppLang.km: 'ទាំងអស់'},
    'unread': {AppLang.en: 'Unread', AppLang.km: 'មិនទាន់អាន'},
    'online': {AppLang.en: 'Online', AppLang.km: 'នៅលើបណ្តាញ'},
    'offline': {AppLang.en: 'Offline', AppLang.km: 'ក្រៅបណ្តាញ'},
    'messageField': {AppLang.en: 'Message', AppLang.km: 'សារ'},
    'today': {AppLang.en: 'Today', AppLang.km: 'ថ្ងៃនេះ'},

    // --- Provider detail ----------------------------------------------
    'tabInfo': {AppLang.en: 'Info', AppLang.km: 'ព័ត៌មាន'},
    'tabAchievements': {AppLang.en: 'Achievements', AppLang.km: 'សមិទ្ធផល'},
    'tabReviews': {AppLang.en: 'Reviews', AppLang.km: 'ការវាយតម្លៃ'},
    'rating': {AppLang.en: 'Rating', AppLang.km: 'ការវាយតម្លៃ'},
    'reviewsSuffix': {AppLang.en: 'Reviews', AppLang.km: 'ការវាយតម្លៃ'},
    'roleProfessional': {AppLang.en: 'Professional', AppLang.km: 'អ្នកជំនាញ'},
    'reviewOptions': {
      AppLang.en: 'Review options',
      AppLang.km: 'ជម្រើសការវាយតម្លៃ',
    },
    'translatingReview': {
      AppLang.en: 'Translating review…',
      AppLang.km: 'កំពុងបកប្រែការវាយតម្លៃ…',
    },
    'reviewLiked': {
      AppLang.en: 'Review liked',
      AppLang.km: 'បានចូលចិត្តការវាយតម្លៃ',
    },
    'calling': {AppLang.en: 'Calling', AppLang.km: 'កំពុងហៅ'},
    'chatOptions': {AppLang.en: 'Chat options', AppLang.km: 'ជម្រើសជជែក'},
    'about': {AppLang.en: 'About', AppLang.km: 'អំពី'},
    'openingHours': {AppLang.en: 'Opening Hours', AppLang.km: 'ម៉ោងបើក'},
    'service': {AppLang.en: 'Service', AppLang.km: 'សេវាកម្ម'},
    'messageBtn': {AppLang.en: 'Message', AppLang.km: 'ផ្ញើសារ'},
    'audioBtn': {AppLang.en: 'Audio', AppLang.km: 'ហៅជាសំឡេង'},
    'nearby': {AppLang.en: 'Nearby', AppLang.km: 'នៅជិត'},
    'tapForDirections': {
      AppLang.en: 'Tap for directions',
      AppLang.km: 'ចុចដើម្បីមើលទិសដៅ',
    },
    'jobCompletedSuffix': {
      AppLang.en: 'Job Completed',
      AppLang.km: 'ការងារបានបញ្ចប់',
    },
    'ratingCountSuffix': {AppLang.en: 'rating', AppLang.km: 'ការវាយតម្លៃ'},
    'booking': {AppLang.en: 'Booking', AppLang.km: 'កំពុងកក់'},

    // --- Active job / tracking ------------------------------------------
    'trackingDetails': {
      AppLang.en: 'Tracking Details',
      AppLang.km: 'ព័ត៌មានតាមដាន',
    },
    'trackingId': {AppLang.en: 'Tracking ID', AppLang.km: 'លេខតាមដាន'},
    'origin': {AppLang.en: 'Origin', AppLang.km: 'ចំណុចចេញ'},
    'destination': {AppLang.en: 'Destination', AppLang.km: 'ទិសដៅ'},
    'technicianLabel': {AppLang.en: 'Technician', AppLang.km: 'ជាង'},
    'rateLabel': {AppLang.en: 'Rate', AppLang.km: 'ពិន្ទុ'},
    'statusLabel': {AppLang.en: 'Status', AppLang.km: 'ស្ថានភាព'},
    'inTransit': {AppLang.en: 'In Transit', AppLang.km: 'កំពុងធ្វើដំណើរ'},
    'stepBooked': {AppLang.en: 'Booked', AppLang.km: 'បានកក់'},
    'stepBookedSub': {
      AppLang.en: 'Pending technician arrival',
      AppLang.km: 'រង់ចាំជាងមកដល់',
    },
    'stepInTransitSub': {AppLang.en: 'From SenSok', AppLang.km: 'ចេញពី សែនសុខ'},
    'stepProcessing': {AppLang.en: 'Processing', AppLang.km: 'កំពុងដំណើរការ'},
    'stepProcessingSub': {
      AppLang.en: 'In the process',
      AppLang.km: 'កំពុងអនុវត្ត',
    },
    'stepCompleted': {AppLang.en: 'Completed', AppLang.km: 'បានបញ្ចប់'},
    'liveTracking': {AppLang.en: 'Live Tracking', AppLang.km: 'តាមដានផ្ទាល់'},
    'nearYou': {AppLang.en: 'Near you', AppLang.km: 'នៅជិតអ្នក'},
    'viewProfile': {AppLang.en: 'View Profile', AppLang.km: 'មើលប្រវត្តិរូប'},
    'seeTranslation': {
      AppLang.en: 'See translation',
      AppLang.km: 'មើលការបកប្រែ',
    },
    'orderedPrefix': {AppLang.en: 'Ordered: ', AppLang.km: 'បានកម្ម៉ង់៖ '},
    'like': {AppLang.en: 'Like', AppLang.km: 'ចូលចិត្ត'},
    'getDirection': {AppLang.en: 'Get Direction', AppLang.km: 'យកទិសដៅ'},
    'directionsTitle': {AppLang.en: 'Directions', AppLang.km: 'ទិសដៅ'},
    'openInMapsApp': {
      AppLang.en: 'Open in Maps app',
      AppLang.km: 'បើកក្នុងកម្មវិធីផែនទី',
    },
    'routeUnavailable': {
      AppLang.en: 'Live route unavailable — showing a direct line.',
      AppLang.km: 'មិនអាចទាញផ្លូវផ្ទាល់បាន — បង្ហាញជាបន្ទាត់ត្រង់។',
    },
    'couldNotOpenMaps': {
      AppLang.en: 'Could not open a maps app',
      AppLang.km: 'មិនអាចបើកកម្មវិធីផែនទីបានទេ',
    },
    'bookNow': {AppLang.en: 'Book Now', AppLang.km: 'កក់ឥឡូវនេះ'},
    'bookingTitle': {AppLang.en: 'Book a service', AppLang.km: 'កក់សេវាកម្ម'},
    'bookingService': {AppLang.en: 'Service', AppLang.km: 'សេវាកម្ម'},
    'svcRepair': {AppLang.en: 'Repair', AppLang.km: 'ជួសជុល'},
    'svcClean': {AppLang.en: 'Clean', AppLang.km: 'សម្អាត'},
    'svcInstallation': {AppLang.en: 'Installation', AppLang.km: 'ដំឡើង'},
    'svcInspection': {AppLang.en: 'Inspection', AppLang.km: 'ត្រួតពិនិត្យ'},
    'bookingAddress': {AppLang.en: 'Service address', AppLang.km: 'អាសយដ្ឋានសេវាកម្ម'},
    'bookingNote': {AppLang.en: 'Note (optional)', AppLang.km: 'កំណត់ចំណាំ (ស្រេចចិត្ត)'},
    'bookingNoteHint': {
      AppLang.en: 'Anything the technician should know…',
      AppLang.km: 'អ្វីៗដែលជាងគួរដឹង…',
    },
    'pickDate': {AppLang.en: 'Pick a date', AppLang.km: 'ជ្រើសរើសកាលបរិច្ឆេទ'},
    'pickTime': {AppLang.en: 'Pick a time', AppLang.km: 'ជ្រើសរើសម៉ោង'},
    'confirmBooking': {AppLang.en: 'Confirm Booking', AppLang.km: 'បញ្ជាក់ការកក់'},
    'bookingDone': {AppLang.en: 'Booking requested', AppLang.km: 'បានស្នើសុំការកក់'},
    'bookingDoneBody': {
      AppLang.en: 'The technician will confirm shortly.',
      AppLang.km: 'ជាងនឹងបញ្ជាក់ក្នុងពេលឆាប់ៗ។',
    },

    // --- Live tracking: traffic on the route --------------------------
    'fromLabel': {AppLang.en: 'From', AppLang.km: 'ពី'},
    'minShort': {AppLang.en: 'min', AppLang.km: 'នាទី'},
    'kmShort': {AppLang.en: 'km', AppLang.km: 'គម'},
    'similarEta': {AppLang.en: 'Similar ETA', AppLang.km: 'ETA ស្រដៀងគ្នា'},
    'minLonger': {AppLang.en: 'min longer', AppLang.km: 'នាទីយូរជាង'},
    'trafficTitle': {AppLang.en: 'Traffic', AppLang.km: 'ចរាចរណ៍'},
    'trafficFree': {AppLang.en: 'Clear', AppLang.km: 'រលូន'},
    'trafficModerate': {AppLang.en: 'Moderate', AppLang.km: 'មធ្យម'},
    'trafficHeavy': {AppLang.en: 'Slow', AppLang.km: 'យឺត'},
    'trafficBlocked': {AppLang.en: 'Blocked', AppLang.km: 'ស្ទះ'},
    'trafficUnknown': {AppLang.en: 'No data', AppLang.km: 'គ្មានទិន្នន័យ'},
    'etaLabel': {AppLang.en: 'ETA', AppLang.km: 'មកដល់'},
    'arrived': {AppLang.en: 'Arrived', AppLang.km: 'មកដល់ហើយ'},
    'statusMovingFast': {
      AppLang.en: 'Moving fast · clear road',
      AppLang.km: 'ធ្វើដំណើរលឿន · ផ្លូវរលូន',
    },
    'statusSteady': {
      AppLang.en: 'Steady · moderate traffic',
      AppLang.km: 'ធម្មតា · ចរាចរណ៍មធ្យម',
    },
    'statusSlow': {
      AppLang.en: 'Slow · heavy traffic',
      AppLang.km: 'យឺត · ចរាចរណ៍ស្ទះ',
    },
    'statusBlocked': {
      AppLang.en: 'Road blocked — taking a detour',
      AppLang.km: 'ផ្លូវស្ទះ — កំពុងវាងផ្លូវ',
    },
    'statusNoData': {
      AppLang.en: 'No live traffic on this stretch',
      AppLang.km: 'គ្មានទិន្នន័យចរាចរណ៍លើផ្នែកនេះ',
    },
    'statusArrived': {
      AppLang.en: 'Technician has arrived',
      AppLang.km: 'ជាងបានមកដល់ហើយ',
    },

    // --- Profile -------------------------------------------------------------
    'profile': {AppLang.en: 'Profile', AppLang.km: 'ប្រវត្តិរូប'},
    'editProfile': {AppLang.en: 'Edit Profile', AppLang.km: 'កែសម្រួលប្រវត្តិរូប'},
    'edit': {AppLang.en: 'Edit', AppLang.km: 'កែសម្រួល'},
    'phone': {AppLang.en: 'Phone', AppLang.km: 'ទូរស័ព្ទ'},
    'email': {AppLang.en: 'Email', AppLang.km: 'អ៊ីមែល'},
    'address': {AppLang.en: 'Address', AppLang.km: 'អាសយដ្ឋាន'},
    'notSet': {AppLang.en: 'Not set', AppLang.km: 'មិនទាន់កំណត់'},
    'darkMode': {AppLang.en: 'Dark Mode', AppLang.km: 'របៀបងងឹត'},
    'language': {AppLang.en: 'Language', AppLang.km: 'ភាសា'},
    'notifications': {AppLang.en: 'Notifications', AppLang.km: 'ការជូនដំណឹង'},
    'preference': {AppLang.en: 'Preference', AppLang.km: 'ចំណូលចិត្ត'},
    'privacyPolicy': {
      AppLang.en: 'Privacy Policy',
      AppLang.km: 'គោលការណ៍ភាពឯកជន',
    },
    'helpAndSupport': {
      AppLang.en: 'Help and Support',
      AppLang.km: 'ជំនួយ និងការគាំទ្រ',
    },
    'logout': {AppLang.en: 'Logout', AppLang.km: 'ចាកចេញ'},

    // --- Edit Profile ------------------------------------------------------
    'fullName': {AppLang.en: 'Full Name', AppLang.km: 'ឈ្មោះពេញ'},
    'phoneNumber': {AppLang.en: 'Phone Number', AppLang.km: 'លេខទូរស័ព្ទ'},
    'dateOfBirth': {AppLang.en: 'Date of Birth', AppLang.km: 'ថ្ងៃខែឆ្នាំកំណើត'},
    'saveChange': {
      AppLang.en: 'Save Change',
      AppLang.km: 'រក្សាទុកការផ្លាស់ប្តូរ',
    },
    'saving': {AppLang.en: 'Saving…', AppLang.km: 'កំពុងរក្សាទុក…'},
    'selectDate': {AppLang.en: 'Select date', AppLang.km: 'ជ្រើសរើសកាលបរិច្ឆេទ'},
    'chooseOnMap': {AppLang.en: 'Choose on map', AppLang.km: 'ជ្រើសរើសលើផែនទី'},
    'useCurrentLocation': {
      AppLang.en: 'Use my current location',
      AppLang.km: 'ប្រើទីតាំងបច្ចុប្បន្នរបស់ខ្ញុំ',
    },
    'gettingLocation': {
      AppLang.en: 'Getting location…',
      AppLang.km: 'កំពុងទាញយកទីតាំង…',
    },
    'locationServiceOff': {
      AppLang.en: 'Turn on location services first',
      AppLang.km: 'សូមបើកសេវាកំណត់ទីតាំងជាមុនសិន',
    },
    'locationPermissionDenied': {
      AppLang.en: 'Location permission denied',
      AppLang.km: 'ការអនុញ្ញាតទីតាំងត្រូវបានបដិសេធ',
    },
    'locationFailed': {
      AppLang.en: "Couldn't get your location",
      AppLang.km: 'មិនអាចទាញយកទីតាំងបានទេ',
    },
    'pickLocation': {AppLang.en: 'Pick a location', AppLang.km: 'ជ្រើសរើសទីតាំង'},
    'tapMapToPick': {
      AppLang.en: 'Tap the map to drop a pin',
      AppLang.km: 'ចុចលើផែនទីដើម្បីដាក់ចំណុច',
    },
    'useThisLocation': {
      AppLang.en: 'Use this location',
      AppLang.km: 'ប្រើទីតាំងនេះ',
    },
  };
}
