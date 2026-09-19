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
    'trackBooking': {AppLang.en: 'Track booking', AppLang.km: 'តាមដានការកក់'},
    'successful': {AppLang.en: 'Successful', AppLang.km: 'ជោគជ័យ'},
    'seeAll': {AppLang.en: 'See All', AppLang.km: 'មើលទាំងអស់'},
    'or': {AppLang.en: 'or', AppLang.km: 'ឬ'},
    'search': {AppLang.en: 'Search', AppLang.km: 'ស្វែងរក'},
    'ok': {AppLang.en: 'OK', AppLang.km: 'យល់ព្រម'},
    'retry': {AppLang.en: 'Retry', AppLang.km: 'ព្យាយាមម្តងទៀត'},
    'noTechniciansNearby': {
      AppLang.en: 'No technicians online near you right now.',
      AppLang.km: 'មិនមានជាងនៅជិតអ្នកទេឥឡូវនេះ។'
    },
    'locationUnknown': {
      AppLang.en: 'Location not shared',
      AppLang.km: 'មិនបានចែករំលែកទីតាំង'
    },
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

    // --- Dashboard v2 (home page redesign) --------------------------------
    'heroAcTitle': {
      AppLang.en: 'Cool Comfort, Fast Service',
      AppLang.km: 'ត្រជាក់ស្រួល សេវាកម្មលឿន',
    },
    'heroGeneralTitle': {
      AppLang.en: 'On-demand home services, anytime',
      AppLang.km: 'សេវាកម្មតាមផ្ទះ គ្រប់ពេលវេលា',
    },
    'topTechnicians': {AppLang.en: 'Top Technicians', AppLang.km: 'ជាងកំពូល'},
    'view': {AppLang.en: 'View', AppLang.km: 'មើល'},
    'promo10Title': {
      AppLang.en: '10% off your first repair',
      AppLang.km: 'បញ្ចុះតម្លៃ១០% លើការជួសជុលលើកទីមួយ',
    },
    'promo10Subtitle': {
      AppLang.en: 'Use code WELCOME10',
      AppLang.km: 'ប្រើកូដ WELCOME10',
    },
    'popularServices': {
      AppLang.en: 'Popular Services',
      AppLang.km: 'សេវាកម្មពេញនិយម',
    },
    'servicePackages': {
      AppLang.en: 'Service Packages',
      AppLang.km: 'កញ្ចប់សេវាកម្ម',
    },
    'homeCareBundle': {
      AppLang.en: 'Home Care Bundle',
      AppLang.km: 'កញ្ចប់ថែទាំផ្ទះ',
    },
    'homeCareBundleDesc': {
      AppLang.en: 'AC + Plumbing + Electrical',
      AppLang.km: 'ម៉ាស៊ីនត្រជាក់ + បំពង់ទឹក + អគ្គិសនី',
    },
    'vehicleCheckup': {
      AppLang.en: 'Vehicle Checkup',
      AppLang.km: 'ត្រួតពិនិត្យយានយន្ត',
    },
    'vehicleCheckupDesc': {
      AppLang.en: 'Diagnostics + Oil Change',
      AppLang.km: 'វិនិច្ឆ័យ + ប្តូរប្រេង',
    },
    'save20': {AppLang.en: 'Save 20%', AppLang.km: 'សន្សំ២០%'},
    'save15': {AppLang.en: 'Save 15%', AppLang.km: 'សន្សំ១៥%'},
    'availableNearYou': {
      AppLang.en: 'Available Near You',
      AppLang.km: 'នៅជិតអ្នកដែលទំនេរ',
    },
    'howItWorks': {AppLang.en: 'How It Works', AppLang.km: 'របៀបប្រើប្រាស់'},
    'howItWorksStep1Title': {AppLang.en: 'Choose service', AppLang.km: 'ជ្រើសរើសសេវា'},
    'howItWorksStep1Desc': {
      AppLang.en: 'Browse and find the service you need',
      AppLang.km: 'ស្វែងរកសេវាកម្មដែលអ្នកត្រូវការ',
    },
    'howItWorksStep2Title': {AppLang.en: 'Book a technician', AppLang.km: 'កក់ជាង'},
    'howItWorksStep2Desc': {
      AppLang.en: 'Pick a date & time that works for you',
      AppLang.km: 'ជ្រើសរើសកាលបរិច្ឆេទ និងម៉ោងសមស្រប',
    },
    'howItWorksStep3Title': {AppLang.en: 'Get it fixed', AppLang.km: 'ជួសជុលរួចរាល់'},
    'howItWorksStep3Desc': {
      AppLang.en: 'Relax while our experts do the job',
      AppLang.km: 'សម្រាក ខណៈអ្នកជំនាញធ្វើការងារ',
    },
    'whatCustomersSay': {
      AppLang.en: 'What Customers Say',
      AppLang.km: 'អតិថិជនប្រសាសន៍ថា',
    },
    'aCamfixCustomer': {
      AppLang.en: 'A CamFix customer',
      AppLang.km: 'អតិថិជន CamFix',
    },
    'guaranteeVerifiedTechs': {
      AppLang.en: 'Verified technicians',
      AppLang.km: 'ជាងបានផ្ទៀងផ្ទាត់',
    },
    'guaranteeSecureBooking': {
      AppLang.en: 'Secure booking',
      AppLang.km: 'ការកក់មានសុវត្ថិភាព',
    },
    'guarantee7DaySupport': {
      AppLang.en: '7-day support',
      AppLang.km: 'គាំទ្រ៧ថ្ងៃ',
    },
    'yourRecentBooking': {
      AppLang.en: 'Your Recent Booking',
      AppLang.km: 'ការកក់ថ្មីៗរបស់អ្នក',
    },
    'bookAgain': {AppLang.en: 'Book again', AppLang.km: 'កក់ម្តងទៀត'},
    'needEmergencyHelp': {
      AppLang.en: 'Need emergency help?',
      AppLang.km: 'ត្រូវការជំនួយបន្ទាន់?',
    },
    'callSupport': {AppLang.en: 'Call support', AppLang.km: 'ទូរស័ព្ទទៅផ្នែកគាំទ្រ'},

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
    'navChat': {AppLang.en: 'Messages', AppLang.km: 'សារ'},
    'navProfile': {AppLang.en: 'Account', AppLang.km: 'គណនី'},

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
    'you': {AppLang.en: 'You', AppLang.km: 'អ្នក'},
    'online': {AppLang.en: 'Online', AppLang.km: 'នៅលើបណ្តាញ'},
    'offline': {AppLang.en: 'Offline', AppLang.km: 'ក្រៅបណ្តាញ'},
    'messageField': {AppLang.en: 'Message', AppLang.km: 'សារ'},
    'sayHello': {
      AppLang.en: 'No messages yet - say hello!',
      AppLang.km: 'មិនទាន់មានសារទេ - សូមសួរសុខទុក្ខ!',
    },
    'bookFirstToChat': {
      AppLang.en: 'Book this technician first to start chatting.',
      AppLang.km: 'សូមកក់ជាងនេះជាមុនសិន ដើម្បីចាប់ផ្តើមជជែក។',
    },
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
    'startingFrom': {AppLang.en: 'Starting from', AppLang.km: 'ចាប់ផ្តើមពី'},
    'finalPriceNote': {
      AppLang.en: 'final price depends on inspection, labor, parts and travel',
      AppLang.km: 'តម្លៃចុងក្រោយអាស្រ័យលើការត្រួតពិនិត្យ ថ្លៃការងារ គ្រឿងបន្លាស់ និងការធ្វើដំណើរ',
    },
    'quoteTitle': {AppLang.en: 'Repair quote', AppLang.km: 'សម្រង់ថ្លៃជួសជុល'},
    'quoteRevisedTitle': {AppLang.en: 'Revised repair quote', AppLang.km: 'សម្រង់ថ្លៃដែលបានកែសម្រួល'},
    'quoteInspectionFee': {AppLang.en: 'Inspection', AppLang.km: 'ការត្រួតពិនិត្យ'},
    'quoteLaborCost': {AppLang.en: 'Labor', AppLang.km: 'ថ្លៃការងារ'},
    'quotePartsCost': {AppLang.en: 'Parts', AppLang.km: 'គ្រឿងបន្លាស់'},
    'quoteTravelFee': {AppLang.en: 'Travel', AppLang.km: 'ការធ្វើដំណើរ'},
    'quoteTotal': {AppLang.en: 'Total', AppLang.km: 'សរុប'},
    'quoteReasonLabel': {AppLang.en: 'Technician\'s note', AppLang.km: 'កំណត់ចំណាំរបស់ជាង'},
    'quoteAccept': {AppLang.en: 'Accept quote', AppLang.km: 'ទទួលយកសម្រង់ថ្លៃ'},
    'quoteReject': {AppLang.en: 'Decline', AppLang.km: 'បដិសេធ'},
    'quoteAcceptConfirmTitle': {AppLang.en: 'Accept this quote?', AppLang.km: 'ទទួលយកសម្រង់ថ្លៃនេះ?'},
    'quoteAcceptConfirmMessage': {
      AppLang.en: 'The technician will start the repair once you accept.',
      AppLang.km: 'ជាងនឹងចាប់ផ្តើមជួសជុលនៅពេលអ្នកទទួលយក។',
    },
    'quoteRejectConfirmTitle': {AppLang.en: 'Decline this quote?', AppLang.km: 'បដិសេធសម្រង់ថ្លៃនេះ?'},
    'quoteRejectConfirmMessage': {
      AppLang.en: 'The technician can send a revised quote, or you can cancel the booking.',
      AppLang.km: 'ជាងអាចផ្ញើសម្រង់ថ្លៃថ្មី ឬអ្នកអាចលុបចោលការកក់។',
    },
    'quotePendingBanner': {
      AppLang.en: 'Your technician sent a quote — review it below.',
      AppLang.km: 'ជាងរបស់អ្នកបានផ្ញើសម្រង់ថ្លៃ — សូមពិនិត្យមើលខាងក្រោម។',
    },
    'quoteHistory': {AppLang.en: 'Quote history', AppLang.km: 'ប្រវត្តិសម្រង់ថ្លៃ'},
    'quoteStatusAccepted': {AppLang.en: 'Accepted', AppLang.km: 'បានទទួលយក'},
    'quoteStatusRejected': {AppLang.en: 'Declined', AppLang.km: 'បានបដិសេធ'},
    'quoteStatusRevised': {AppLang.en: 'Revised', AppLang.km: 'បានកែសម្រួល'},
    'quoteStatusPending': {AppLang.en: 'Awaiting your decision', AppLang.km: 'កំពុងរង់ចាំការសម្រេចចិត្តរបស់អ្នក'},
    'quoteAccepted': {AppLang.en: 'Quote accepted', AppLang.km: 'សម្រង់ថ្លៃត្រូវបានទទួលយក'},
    'quoteRejected': {AppLang.en: 'Quote declined', AppLang.km: 'សម្រង់ថ្លៃត្រូវបានបដិសេធ'},
    'rateTechnicianTitle': {AppLang.en: 'Rate your technician', AppLang.km: 'វាយតម្លៃជាងរបស់អ្នក'},
    'rateTechnicianPrompt': {
      AppLang.en: 'How was the service?',
      AppLang.km: 'សេវាកម្មនេះយ៉ាងណាដែរ?',
    },
    'reviewCommentHint': {
      AppLang.en: 'Share more about your experience (optional)',
      AppLang.km: 'ចែករំលែកបទពិសោធន៍របស់អ្នកបន្ថែម (មិនចាំបាច់)',
    },
    'submitReview': {AppLang.en: 'Submit review', AppLang.km: 'ដាក់ស្នើការវាយតម្លៃ'},
    'reviewRequired': {
      AppLang.en: 'Tap a star to rate your technician',
      AppLang.km: 'ចុចផ្កាយដើម្បីវាយតម្លៃជាងរបស់អ្នក',
    },
    'reviewSubmittedThanks': {
      AppLang.en: 'Thanks for your review!',
      AppLang.km: 'សូមអរគុណសម្រាប់ការវាយតម្លៃ!',
    },
    'yourReviewLabel': {AppLang.en: 'Your review', AppLang.km: 'ការវាយតម្លៃរបស់អ្នក'},
    'favorites': {AppLang.en: 'Favorites', AppLang.km: 'ចំណូលចិត្ត'},
    'favoritesEmpty': {
      AppLang.en: 'No saved technicians yet',
      AppLang.km: 'មិនទាន់មានជាងដែលបានរក្សាទុកទេ',
    },
    'favoritesEmptyHint': {
      AppLang.en: 'Tap the heart on a technician you\'ve worked with to save them here.',
      AppLang.km: 'ចុចរូបបេះដូងលើជាងដែលអ្នកធ្លាប់ធ្វើការជាមួយ ដើម្បីរក្សាទុកនៅទីនេះ។',
    },
    'addedToFavorites': {AppLang.en: 'Added to favorites', AppLang.km: 'បានបន្ថែមទៅចំណូលចិត្ត'},
    'removedFromFavorites': {AppLang.en: 'Removed from favorites', AppLang.km: 'បានដកចេញពីចំណូលចិត្ត'},
    'saveTechnicianTooltip': {AppLang.en: 'Save technician', AppLang.km: 'រក្សាទុកជាង'},
    'camfixUser': {AppLang.en: 'CAM FIX user', AppLang.km: 'អ្នកប្រើ CAM FIX'},
    'noReviewsYet': {
      AppLang.en: 'No reviews yet',
      AppLang.km: 'មិនទាន់មានការវាយតម្លៃទេ',
    },
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
    'miShort': {AppLang.en: 'mi', AppLang.km: 'ម៉ាយល៍'},
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
    'logoutConfirmTitle': {AppLang.en: 'Log out?', AppLang.km: 'ចាកចេញ?'},
    'logoutConfirmMessage': {
      AppLang.en: 'Are you sure you want to log out of your account?',
      AppLang.km: 'តើអ្នកប្រាកដថាចង់ចាកចេញពីគណនីរបស់អ្នកមែនទេ?',
    },
    'helpSupportIntro': {
      AppLang.en: 'Need help? Reach out to us anytime.',
      AppLang.km: 'ត្រូវការជំនួយ? សូមទាក់ទងមកយើងខ្ញុំបានគ្រប់ពេល។',
    },
    'callUs': {AppLang.en: 'Call us', AppLang.km: 'ហៅមកយើងខ្ញុំ'},
    'emailUs': {AppLang.en: 'Email us', AppLang.km: 'អ៊ីមែលមកយើងខ្ញុំ'},
    'couldNotOpenEmail': {
      AppLang.en: 'Could not open an email app',
      AppLang.km: 'មិនអាចបើកកម្មវិធីអ៊ីមែលបានទេ',
    },
    'distanceUnit': {AppLang.en: 'Distance unit', AppLang.km: 'ឯកតារយៈចម្ងាយ'},
    'kilometers': {AppLang.en: 'Kilometers (km)', AppLang.km: 'គីឡូម៉ែត្រ (km)'},
    'miles': {AppLang.en: 'Miles (mi)', AppLang.km: 'ម៉ាយល៍ (mi)'},
    'defaultAddress': {
      AppLang.en: 'Default address',
      AppLang.km: 'អាសយដ្ឋានលំនាំដើម',
    },
    'defaultAddressHint': {
      AppLang.en: 'Pre-fills new bookings so you don\'t have to pick it every time',
      AppLang.km: 'បំពេញអាសយដ្ឋានជាមុនសម្រាប់ការកក់ថ្មី ដើម្បីកុំឲ្យត្រូវជ្រើសរើសម្តងទៀត',
    },
    'setOnMap': {AppLang.en: 'Set on map', AppLang.km: 'កំណត់លើផែនទី'},
    'clear': {AppLang.en: 'Clear', AppLang.km: 'សម្អាត'},
    'enableNotifications': {
      AppLang.en: 'Enable notifications',
      AppLang.km: 'បើកការជូនដំណឹង',
    },
    'privacyIntro': {
      AppLang.en:
          'This page explains what information CAM FIX collects and how it is used. It is a plain-language summary, not a formal legal document.',
      AppLang.km:
          'ទំព័រនេះពន្យល់អំពីព័ត៌មានដែល CAM FIX ប្រមូល និងរបៀបប្រើប្រាស់វា។ វាគ្រាន់តែជាសេចក្តីសង្ខេបសាមញ្ញ មិនមែនជាឯកសារផ្លូវការទេ។',
    },
    'privacyCollectTitle': {
      AppLang.en: 'Information we collect',
      AppLang.km: 'ព័ត៌មានដែលយើងប្រមូល',
    },
    'privacyCollectBody': {
      AppLang.en:
          'Your name, phone number, and email when you create an account; your location when you book a service or a technician shares their live position; and details of the bookings you make (service type, address, notes, status).',
      AppLang.km:
          'ឈ្មោះ លេខទូរស័ព្ទ និងអ៊ីមែលរបស់អ្នកនៅពេលបង្កើតគណនី; ទីតាំងរបស់អ្នកនៅពេលកក់សេវា ឬនៅពេលជាងចែករំលែកទីតាំងផ្ទាល់; និងព័ត៌មានលម្អិតនៃការកក់ (ប្រភេទសេវា អាសយដ្ឋាន កំណត់ចំណាំ ស្ថានភាព)។',
    },
    'privacyUseTitle': {
      AppLang.en: 'How we use it',
      AppLang.km: 'របៀបយើងប្រើប្រាស់វា',
    },
    'privacyUseBody': {
      AppLang.en:
          'To match you with a technician, show live tracking during a job, send booking/status notifications, and provide customer support.',
      AppLang.km:
          'ដើម្បីផ្គូផ្គងអ្នកជាមួយជាង បង្ហាញការតាមដានផ្ទាល់អំឡុងពេលធ្វើការងារ ផ្ញើការជូនដំណឹងអំពីការកក់/ស្ថានភាព និងផ្តល់ការគាំទ្រអតិថិជន។',
    },
    'privacySharingTitle': {
      AppLang.en: 'Sharing',
      AppLang.km: 'ការចែករំលែក',
    },
    'privacySharingBody': {
      AppLang.en:
          'Your name, phone number, and job address are shared with the technician assigned to your booking so they can complete the job. We do not sell your information.',
      AppLang.km:
          'ឈ្មោះ លេខទូរស័ព្ទ និងអាសយដ្ឋានការងាររបស់អ្នកត្រូវបានចែករំលែកជាមួយជាងដែលទទួលបន្ទុកការកក់របស់អ្នក ដើម្បីឲ្យពួកគេអាចបំពេញការងារបាន។ យើងមិនលក់ព័ត៌មានរបស់អ្នកទេ។',
    },
    'privacyChoicesTitle': {
      AppLang.en: 'Your choices',
      AppLang.km: 'ជម្រើសរបស់អ្នក',
    },
    'privacyChoicesBody': {
      AppLang.en:
          'You can edit your profile, turn notifications on or off, and clear your saved default address at any time from Profile settings.',
      AppLang.km:
          'អ្នកអាចកែប្រែប្រវត្តិរូបរបស់អ្នក បើក/បិទការជូនដំណឹង និងលុបអាសយដ្ឋានលំនាំដើមដែលបានរក្សាទុកបានគ្រប់ពេលពីការកំណត់ប្រវត្តិរូប។',
    },
    'privacyContactTitle': {
      AppLang.en: 'Contact us',
      AppLang.km: 'ទាក់ទងយើងខ្ញុំ',
    },
    'privacyContactBody': {
      AppLang.en: 'Questions about your data? Reach us at camfix098@gmail.com.',
      AppLang.km: 'មានសំណួរអំពីទិន្នន័យរបស់អ្នក? ទាក់ទងមកយើងខ្ញុំតាម camfix098@gmail.com។',
    },

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
    'searchLocationHint': {
      AppLang.en: 'Search for a place or address',
      AppLang.km: 'ស្វែងរកកន្លែង ឬអាសយដ្ឋាន',
    },
    'tapMapToPick': {
      AppLang.en: 'Tap the map to drop a pin',
      AppLang.km: 'ចុចលើផែនទីដើម្បីដាក់ចំណុច',
    },
    'useThisLocation': {
      AppLang.en: 'Use this location',
      AppLang.km: 'ប្រើទីតាំងនេះ',
    },

    // --- Notifications screen --------------------------------------------
    'notificationsEmpty': {
      AppLang.en: 'No notifications yet',
      AppLang.km: 'មិនទាន់មានការជូនដំណឹងទេ',
    },
    'markAllRead': {
      AppLang.en: 'Mark all read',
      AppLang.km: 'សម្គាល់ថាបានអានទាំងអស់',
    },
    'justNow': {AppLang.en: 'just now', AppLang.km: 'អម្បាញ់មិញ'},
    'minAgo': {AppLang.en: 'min ago', AppLang.km: 'នាទីមុន'},
    'hrAgo': {AppLang.en: 'h ago', AppLang.km: 'ម៉ោងមុន'},
    'dayAgo': {AppLang.en: 'd ago', AppLang.km: 'ថ្ងៃមុន'},
    'bookingFailed': {
      AppLang.en: "Couldn't send your booking",
      AppLang.km: 'មិនអាចផ្ញើការកក់របស់អ្នកបានទេ',
    },

    // --- Booking sheet: Immediate vs Scheduled ---------------------------
    'bookingWhen': {AppLang.en: 'When', AppLang.km: 'ពេលណា'},
    'bookNowChip': {AppLang.en: 'Book now', AppLang.km: 'កក់ឥឡូវនេះ'},
    'bookNowChipSub': {
      AppLang.en: 'A technician is dispatched right away',
      AppLang.km: 'ជាងនឹងត្រូវបានចាត់ចែងភ្លាមៗ',
    },
    'scheduleChip': {AppLang.en: 'Schedule', AppLang.km: 'កំណត់ពេលវេលា'},
    'scheduleChipSub': {
      AppLang.en: 'Pick a day and time',
      AppLang.km: 'ជ្រើសរើសថ្ងៃ និងម៉ោង',
    },

    // --- Booking tracking screen ------------------------------------------
    'pending': {AppLang.en: 'Pending', AppLang.km: 'កំពុងរង់ចាំ'},
    'stepPending': {AppLang.en: 'Pending', AppLang.km: 'កំពុងរង់ចាំ'},
    'stepAccepted': {AppLang.en: 'Accepted', AppLang.km: 'បានទទួល'},
    'stepOnTheWay': {AppLang.en: 'On the way', AppLang.km: 'កំពុងធ្វើដំណើរមក'},
    'stepArrived': {AppLang.en: 'Arrived', AppLang.km: 'បានមកដល់'},
    'stepQuotePending': {AppLang.en: 'Quote review', AppLang.km: 'ពិនិត្យសម្រង់ថ្លៃ'},
    'stepInProgress': {AppLang.en: 'In progress', AppLang.km: 'កំពុងដំណើរការ'},
    'waitingForTechnician': {
      AppLang.en: 'Waiting for a technician to accept your booking…',
      AppLang.km: 'កំពុងរង់ចាំជាងទទួលយកការកក់របស់អ្នក…',
    },
    'technicianAcceptedInfo': {
      AppLang.en: "Technician accepted your booking. They'll head out soon.",
      AppLang.km: 'ជាងបានទទួលការកក់របស់អ្នកហើយ។ ពួកគេនឹងចេញដំណើរឆាប់ៗនេះ។',
    },
    'technicianArrivedInfo': {
      AppLang.en: 'Technician has arrived at your location',
      AppLang.km: 'ជាងបានមកដល់ទីតាំងរបស់អ្នកហើយ',
    },
    'jobInProgressInfo': {
      AppLang.en: 'Your technician is working on it',
      AppLang.km: 'ជាងរបស់អ្នកកំពុងធ្វើការលើវា',
    },
    'jobCompletedInfo': {
      AppLang.en: 'Job completed — thanks for using CAM FIX!',
      AppLang.km: 'ការងារបានបញ្ចប់ — សូមអរគុណដែលបានប្រើ CAM FIX!',
    },
    'bookingCancelledInfo': {
      AppLang.en: 'This booking was cancelled',
      AppLang.km: 'ការកក់នេះត្រូវបានលុបចោល',
    },
    'noLocationSet': {
      AppLang.en: 'No map location saved for this address',
      AppLang.km: 'មិនមានទីតាំងផែនទីសម្រាប់អាសយដ្ឋាននេះទេ',
    },
    'awayFromYou': {AppLang.en: 'away', AppLang.km: 'ពីអ្នក'},
    'callTechnician': {AppLang.en: 'Call', AppLang.km: 'ហៅទូរស័ព្ទ'},
    'couldNotCall': {
      AppLang.en: 'Could not start the call',
      AppLang.km: 'មិនអាចហៅទូរស័ព្ទបានទេ',
    },
    'scheduledFor': {AppLang.en: 'Scheduled for', AppLang.km: 'បានកំណត់សម្រាប់'},
    'descriptionLabel': {AppLang.en: 'Details', AppLang.km: 'ព័ត៌មានលម្អិត'},
    'estimatedFee': {
      AppLang.en: 'Estimated cancellation fee',
      AppLang.km: 'ថ្លៃសេវាប៉ាន់ស្មានករណីលុបចោល',
    },
    'cancelBooking': {AppLang.en: 'Cancel booking', AppLang.km: 'លុបចោលការកក់'},
    'cancelBookingQ': {
      AppLang.en: 'Cancel this booking?',
      AppLang.km: 'លុបចោលការកក់នេះមែនទេ?',
    },
    'keepBooking': {AppLang.en: 'Keep booking', AppLang.km: 'រក្សាការកក់'},
    'cancelFailed': {
      AppLang.en: "Couldn't cancel this booking",
      AppLang.km: 'មិនអាចលុបចោលការកក់នេះបានទេ',
    },
    'feeFlat': {
      AppLang.en: 'A small cancellation fee applies to every booking.',
      AppLang.km: 'ថ្លៃសេវាលុបចោលបន្តិចត្រូវបានអនុវត្តចំពោះការកក់ទាំងអស់។',
    },
    'feeOnTheWay': {
      AppLang.en:
          'Your technician is already on the way, so cancelling now includes a small fee.',
      AppLang.km:
          'ជាងរបស់អ្នកកំពុងធ្វើដំណើរមកហើយ ដូច្នេះការលុបចោលឥឡូវនេះរួមបញ្ចូលថ្លៃសេវាបន្តិច។',
    },
    'feeScheduledTime': {
      AppLang.en: 'Cancelling this close to your scheduled time includes a fee.',
      AppLang.km: 'ការលុបចោលក្បែរពេលវេលាដែលបានកំណត់ រួមបញ្ចូលថ្លៃសេវា។',
    },
    'feeDistance': {
      AppLang.en:
          'Your technician already travelled toward you, so the fee reflects the distance covered.',
      AppLang.km:
          'ជាងរបស់អ្នកបានធ្វើដំណើរមករកអ្នកហើយ ដូច្នេះថ្លៃសេវាឆ្លុះបញ្ចាំងពីចម្ងាយដែលបានធ្វើដំណើរ។',
    },
    'feeNotCancellable': {
      AppLang.en: 'This booking can no longer be cancelled.',
      AppLang.km: 'ការកក់នេះលែងអាចលុបចោលបានទៀតហើយ។',
    },
  };
}
