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
    'completedWorkHistory': {
      AppLang.en: 'Completed work history',
      AppLang.km: 'ប្រវត្តិការងារដែលបានបញ្ចប់'
    },
    'workHistoryError': {
      AppLang.en: 'Could not load work history.',
      AppLang.km: 'មិនអាចផ្ទុកប្រវត្តិការងារបានទេ។'
    },
    'workHistoryMore': {AppLang.en: 'Load more', AppLang.km: 'ផ្ទុកបន្ថែម'},
    // --- Language screen -------------------------------------------------
    'chooseLanguage': {
      AppLang.en: 'Choose language',
      AppLang.km: 'ជ្រើសរើសភាសា'
    },
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
    'phoneNumbersTitle': {
      AppLang.en: 'Phone numbers',
      AppLang.km: 'លេខទូរស័ព្ទ'
    },
    'sendingCode': {
      AppLang.en: 'Sending code…',
      AppLang.km: 'កំពុងផ្ញើលេខកូដ…'
    },

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
      AppLang.km:
          'របៀបអភិវឌ្ឍន៍៖ លេខកូដត្រូវបានបំពេញឲ្យស្រាប់ (គ្មានសេវាផ្ញើ)។',
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
    'newPasswordTitle': {
      AppLang.en: 'New Password',
      AppLang.km: 'ពាក្យសម្ងាត់ថ្មី'
    },
    'newPasswordField': {
      AppLang.en: 'New Password',
      AppLang.km: 'ពាក្យសម្ងាត់ថ្មី'
    },
    'newPasswordHint': {
      AppLang.en:
          'Your new password must be different\nfrom previously used password',
      AppLang.km:
          'ពាក្យសម្ងាត់ថ្មីរបស់អ្នកត្រូវខុសពី\nពាក្យសម្ងាត់ដែលធ្លាប់ប្រើពីមុន',
    },

    // --- Dashboard -------------------------------------------------------
    'goodMorning': {AppLang.en: 'Good Morning!', AppLang.km: 'អរុណសួស្តី!'},
    'goodAfternoon': {AppLang.en: 'Good Afternoon!', AppLang.km: 'ទិវាសួស្តី!'},
    'goodEvening': {AppLang.en: 'Good Evening!', AppLang.km: 'សាយ័ណ្ហសួស្តី!'},
    'searchForService': {
      AppLang.en: 'Search for a service',
      AppLang.km: 'ស្វែងរកសេវាកម្ម',
    },
    'recentlySearched': {
      AppLang.en: 'Recently searched',
      AppLang.km: 'បានស្វែងរកថ្មីៗ'
    },
    'clearAll': {AppLang.en: 'Clear all', AppLang.km: 'សម្អាតទាំងអស់'},
    'browseByCategory': {
      AppLang.en: 'Browse by category',
      AppLang.km: 'រកមើលតាមប្រភេទ'
    },
    'noSearchResults': {
      AppLang.en: 'No technicians match your search',
      AppLang.km: 'រកមិនឃើញជាងដែលត្រូវនឹងការស្វែងរករបស់អ្នកទេ',
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
    'servicesTitle': {AppLang.en: 'Services', AppLang.km: 'សេវាកម្ម'},
    'topTechnicians': {AppLang.en: 'Top Technicians', AppLang.km: 'ជាងកំពូល'},
    'view': {AppLang.en: 'View', AppLang.km: 'មើល'},
    'promo10Title': {
      AppLang.en: 'Quick, easy booking',
      AppLang.km: 'ការកក់រហ័ស និងងាយស្រួល',
    },
    'promo10Subtitle': {
      AppLang.en: 'Browse services and book in minutes',
      AppLang.km: 'រកមើលសេវាកម្ម និងកក់ក្នុងរយៈពេលប៉ុន្មាននាទី',
    },
    'popularServices': {
      AppLang.en: 'Popular Services',
      AppLang.km: 'សេវាកម្មពេញនិយម',
    },
    'categories': {
      AppLang.en: 'Categories',
      AppLang.km: 'ប្រភេទសេវាកម្ម',
    },
    'commonFixesFastBooking': {
      AppLang.en: 'Common Fixes & Fast Booking',
      AppLang.km: 'ការជួសជុលទូទៅ និងការកក់រហ័ស',
    },
    'instantEstimates': {
      AppLang.en: 'Instant Estimates',
      AppLang.km: 'ការប៉ាន់ស្មានតម្លៃភ្លាមៗ',
    },
    'specialOffersBenefits': {
      AppLang.en: 'Special Offers & Benefits',
      AppLang.km: 'ការផ្ដល់ជូនពិសេស និងអត្ថប្រយោជន៍',
    },
    'seasonalService': {
      AppLang.en: 'SEASONAL SERVICE',
      AppLang.km: 'សេវាកម្មតាមរដូវកាល',
    },
    'whyCamFix': {
      AppLang.en: 'WHY CAM FIX',
      AppLang.km: 'ហេតុអ្វីជ្រើសរើស CAM FIX',
    },
    'acInspectionCare': {
      AppLang.en: 'AC Inspection & Care',
      AppLang.km: 'ការពិនិត្យ និងថែទាំម៉ាស៊ីនត្រជាក់',
    },
    'keepHomeCoolAc': {
      AppLang.en: 'Keep your home cool with professional AC maintenance.',
      AppLang.km: 'រក្សាគេហដ្ឋានរបស់អ្នកឱ្យត្រជាក់ជាមួយការថែទាំម៉ាស៊ីនត្រជាក់ជំនាញ។',
    },
    'builtOnRealReviews': {
      AppLang.en: 'Built on real reviews',
      AppLang.km: 'ផ្អែកលើការវាយតម្លៃពិតប្រាកដ',
    },
    'techniciansReviewedBefore': {
      AppLang.en: 'Technicians reviewed before approval',
      AppLang.km: 'ជាងទាំងអស់ត្រូវបានត្រួតពិនិត្យមុនអនុម័ត',
    },
    'ratingsFromRealJobs': {
      AppLang.en: 'Ratings from real completed jobs',
      AppLang.km: 'ពិន្ទុពីការងារជាក់ស្តែងដែលបានបញ្ចប់',
    },
    'trackBookingRealTime': {
      AppLang.en: 'Track your booking in real time',
      AppLang.km: 'តាមដានការកក់របស់អ្នកតាមពេលវេលាជាក់ស្តែង',
    },
    'findAcSpecialists': {
      AppLang.en: 'Find AC specialists',
      AppLang.km: 'ស្វែងរកជាងម៉ាស៊ីនត្រជាក់',
    },
    'exploreServices': {
      AppLang.en: 'Explore services',
      AppLang.km: 'ស្វែងរកសេវាកម្មផ្សេងៗ',
    },
    'leakingPipeRepair': {
      AppLang.en: 'Leaking Pipe Repair',
      AppLang.km: 'ជួសជុលបំពង់ទឹកលិច',
    },
    'acRefrigerantRecharge': {
      AppLang.en: 'AC Refrigerant Recharge',
      AppLang.km: 'បញ្ចូលហ្គាសម៉ាស៊ីនត្រជាក់',
    },
    'circuitBreakerTripping': {
      AppLang.en: 'Circuit Breaker Tripping',
      AppLang.km: 'ដោះស្រាយបញ្ហាដាច់ចរន្តអគ្គិសនី',
    },
    'drainUnclogging': {
      AppLang.en: 'Drain Unclogging',
      AppLang.km: 'បូម ឬបង្ហូរស្ទះលូទឹក',
    },
    'fromPrice': {
      AppLang.en: 'From',
      AppLang.km: 'ចាប់ពី',
    },
    'viewSpecialists': {
      AppLang.en: 'View specialists',
      AppLang.km: 'មើលជាងជំនាញ',
    },
    'verifiedTechniciansTitle': {
      AppLang.en: 'Verified technicians',
      AppLang.km: 'ជាងដែលមានការបញ្ជាក់ត្រឹមត្រូវ',
    },
    'verifiedTechniciansDesc': {
      AppLang.en: 'Every technician is reviewed before they can take jobs',
      AppLang.km: 'រាល់ជាងទាំងអស់សុទ្ធតែត្រូវបានត្រួតពិនិត្យ មុនពេលទទួលការងារ',
    },
    'startingPrice': {
      AppLang.en: 'STARTING',
      AppLang.km: 'ចាប់ផ្ដើមពី',
    },
    'book': {
      AppLang.en: 'Book',
      AppLang.km: 'កក់',
    },
    'whatNeedsFixingToday': {
      AppLang.en: 'What needs fixing in your home today?',
      AppLang.km: 'តើគេហដ្ឋានរបស់អ្នកត្រូវការជួសជុលអ្វីខ្លះថ្ងៃនេះ?',
    },
    'trackingCaps': {
      AppLang.en: 'TRACKING',
      AppLang.km: 'តាមដាន',
    },
    'trustAndSafety': {
      AppLang.en: 'Trust & Safety',
      AppLang.km: 'ទំនុកចិត្ត និងសុវត្ថិភាព',
    },
    'trustAndSafetyDesc': {
      AppLang.en:
          'Every technician goes through admin review before they can appear in the app or take jobs. Ratings you see come only from customers who completed a real booking with that technician.',
      AppLang.km:
          'ជាងទាំងអស់ត្រូវបានពិនិត្យផ្ទៀងផ្ទាត់ដោយអ្នកគ្រប់គ្រង មុនពេលអាចបង្ហាញខ្លួនក្នុងកម្មវិធី ឬទទួលការងារបាន។ ការវាយតម្លៃដែលអ្នកឃើញ គឺបានមកពីអតិថិជនពិតប្រាកដដែលបានកក់សេវាជាមួយជាងនោះប៉ុណ្ណោះ។',
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
    'howItWorksStep1Title': {
      AppLang.en: 'Choose service',
      AppLang.km: 'ជ្រើសរើសសេវា'
    },
    'howItWorksStep1Desc': {
      AppLang.en: 'Browse and find the service you need',
      AppLang.km: 'ស្វែងរកសេវាកម្មដែលអ្នកត្រូវការ',
    },
    'howItWorksStep2Title': {
      AppLang.en: 'Book a technician',
      AppLang.km: 'កក់ជាង'
    },
    'howItWorksStep2Desc': {
      AppLang.en: 'Pick a date & time that works for you',
      AppLang.km: 'ជ្រើសរើសកាលបរិច្ឆេទ និងម៉ោងសមស្រប',
    },
    'howItWorksStep3Title': {
      AppLang.en: 'Get it fixed',
      AppLang.km: 'ជួសជុលរួចរាល់'
    },
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
    'serviceGuarantee': {
      AppLang.en: 'Service Guarantee',
      AppLang.km: 'ការធានាសេវាកម្ម',
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
    'emergencySupportDesc': {
      AppLang.en: '24/7 support for immediate assistance',
      AppLang.km: 'ជំនួយ 24/7 សម្រាប់តម្រូវការបន្ទាន់',
    },
    'callSupport': {
      AppLang.en: 'Call support',
      AppLang.km: 'ទូរស័ព្ទទៅផ្នែកគាំទ្រ'
    },

    // --- Service categories -------------------------------------------
    'svcAllServices': {
      AppLang.en: 'All Services',
      AppLang.km: 'សេវាកម្មទាំងអស់'
    },
    'svcAllServicesDesc': {
      AppLang.en: 'Browse every category and find the right specialist.',
      AppLang.km: 'រកមើលគ្រប់ប្រភេទសេវាកម្ម និងស្វែងរកអ្នកជំនាញត្រឹមត្រូវ។',
    },
    'svcAirConditioner': {
      AppLang.en: 'Air Conditioner',
      AppLang.km: 'ម៉ាស៊ីនត្រជាក់',
    },
    'svcElectrical': {AppLang.en: 'Electrical', AppLang.km: 'អគ្គិសនី'},
    'svcApplianceRepair': {
      AppLang.en: 'Appliances',
      AppLang.km: 'ជួសជុលគ្រឿងប្រើប្រាស់',
    },
    'svcMotorcycle': {AppLang.en: 'Motorcycle', AppLang.km: 'ម៉ូតូ'},
    'svcCar': {AppLang.en: 'Car Repair', AppLang.km: 'ឡាន'},
    'svcWaterNetwork': {AppLang.en: 'Plumbing', AppLang.km: 'បណ្តាញទឹក'},
    'svcAirConditionerDesc': {
      AppLang.en:
          'Installation, cleaning, repair and gas refill for home and office AC units.',
      AppLang.km:
          'ការដំឡើង សម្អាត ជួសជុល និងបំពេញឧស្ម័នសម្រាប់ម៉ាស៊ីនត្រជាក់ផ្ទះ និងការិយាល័យ។',
    },
    'svcElectricalDesc': {
      AppLang.en:
          'Wiring, outlets, lighting and circuit breaker repairs from licensed electricians.',
      AppLang.km:
          'ជួសជុលខ្សែភ្លើង រន្ធភ្លើង ភ្លើងបំភ្លឺ និងកុងតាក់ដោយជាងអគ្គិសនីមានអាជ្ញាប័ណ្ណ។',
    },
    'svcApplianceRepairDesc': {
      AppLang.en:
          'Repair for washing machines, refrigerators, water heaters and other home appliances.',
      AppLang.km:
          'ជួសជុលម៉ាស៊ីនបោកគក់ ទូទឹកកក ម៉ាស៊ីនកម្ដៅទឹក និងគ្រឿងប្រើប្រាស់ក្នុងផ្ទះផ្សេងទៀត។',
    },
    'svcMotorcycleDesc': {
      AppLang.en:
          'On-demand motorcycle maintenance, tune-ups and roadside repair.',
      AppLang.km: 'ថែទាំ តម្លើងម៉ូតូ និងជួសជុលនៅតាមផ្លូវតាមតម្រូវការ។',
    },
    'svcCarDesc': {
      AppLang.en:
          'General car maintenance, diagnostics and mobile repair at your location.',
      AppLang.km:
          'ថែទាំរថយន្តទូទៅ វិនិច្ឆ័យបញ្ហា និងជួសជុលចល័តនៅកន្លែងរបស់អ្នក។',
    },
    'svcWaterNetworkDesc': {
      AppLang.en:
          'Pipe repair, leak detection, drain unclogging and water network installation.',
      AppLang.km: 'ជួសជុលបំពង់ទឹក រកជ្រាបទឹក ស្ទះទុយោ និងតម្លើងបណ្តាញទឹក។',
    },

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
    'activeNow': {AppLang.en: 'Active Now', AppLang.km: 'កំពុងសកម្ម'},
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
    'voiceNotAvailable': {
      AppLang.en: 'Voice messages aren\'t available yet',
      AppLang.km: 'សារសំឡេងមិនទាន់អាចប្រើបានទេ',
    },
    'cameraNotAvailable': {
      AppLang.en: 'Photo sharing isn\'t available yet',
      AppLang.km: 'ការចែករំលែករូបភាពមិនទាន់អាចប្រើបានទេ',
    },
    'emojiNotAvailable': {
      AppLang.en: 'Emoji picker isn\'t available yet',
      AppLang.km: 'ឧបករណ៍ជ្រើសរើសអារម្មណ៍មិនទាន់អាចប្រើបានទេ',
    },
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
    'noJobsCompletedYet': {
      AppLang.en: 'No jobs completed yet',
      AppLang.km: 'មិនទាន់មានការងារបានបញ្ចប់ទេ',
    },
    'ratingCountSuffix': {AppLang.en: 'rating', AppLang.km: 'ការវាយតម្លៃ'},
    'booking': {AppLang.en: 'Booking', AppLang.km: 'កំពុងកក់'},
    'personalizedService': {
      AppLang.en: 'Personalized service - get a quote',
      AppLang.km: 'សេវាកម្មផ្ទាល់ខ្លួន - ស្នើសុំតម្លៃ',
    },
    'startingAt': {AppLang.en: 'Starting at', AppLang.km: 'ចាប់ផ្តើមពី'},

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
    'priceFrom': {AppLang.en: 'From', AppLang.km: 'ចាប់ពី'},
    'bookingsSuffix': {AppLang.en: 'bookings', AppLang.km: 'ការកក់'},
    'finalPriceNote': {
      AppLang.en: 'final price depends on inspection, labor, parts and travel',
      AppLang.km:
          'តម្លៃចុងក្រោយអាស្រ័យលើការត្រួតពិនិត្យ ថ្លៃការងារ គ្រឿងបន្លាស់ និងការធ្វើដំណើរ',
    },
    'quoteTitle': {AppLang.en: 'Repair quote', AppLang.km: 'សម្រង់ថ្លៃជួសជុល'},
    'quoteRevisedTitle': {
      AppLang.en: 'Revised repair quote',
      AppLang.km: 'សម្រង់ថ្លៃដែលបានកែសម្រួល'
    },
    'quoteInspectionFee': {
      AppLang.en: 'Inspection',
      AppLang.km: 'ការត្រួតពិនិត្យ'
    },
    'quoteLaborCost': {AppLang.en: 'Labor', AppLang.km: 'ថ្លៃការងារ'},
    'quotePartsCost': {AppLang.en: 'Parts', AppLang.km: 'គ្រឿងបន្លាស់'},
    'quoteTravelFee': {AppLang.en: 'Travel', AppLang.km: 'ការធ្វើដំណើរ'},
    'quoteTotal': {AppLang.en: 'Total', AppLang.km: 'សរុប'},
    'quoteReasonLabel': {
      AppLang.en: 'Technician\'s note',
      AppLang.km: 'កំណត់ចំណាំរបស់ជាង'
    },
    'quoteAccept': {AppLang.en: 'Accept quote', AppLang.km: 'ទទួលយកសម្រង់ថ្លៃ'},
    'quoteReject': {AppLang.en: 'Decline', AppLang.km: 'បដិសេធ'},
    'quoteAcceptConfirmTitle': {
      AppLang.en: 'Accept this quote?',
      AppLang.km: 'ទទួលយកសម្រង់ថ្លៃនេះ?'
    },
    'quoteAcceptConfirmMessage': {
      AppLang.en: 'The technician will start the repair once you accept.',
      AppLang.km: 'ជាងនឹងចាប់ផ្តើមជួសជុលនៅពេលអ្នកទទួលយក។',
    },
    'quoteRejectConfirmTitle': {
      AppLang.en: 'Decline this quote?',
      AppLang.km: 'បដិសេធសម្រង់ថ្លៃនេះ?'
    },
    'quoteRejectConfirmMessage': {
      AppLang.en:
          'The technician can send a revised quote, or you can cancel the booking.',
      AppLang.km: 'ជាងអាចផ្ញើសម្រង់ថ្លៃថ្មី ឬអ្នកអាចលុបចោលការកក់។',
    },
    'quotePendingBanner': {
      AppLang.en: 'Your technician sent a quote — review it below.',
      AppLang.km: 'ជាងរបស់អ្នកបានផ្ញើសម្រង់ថ្លៃ — សូមពិនិត្យមើលខាងក្រោម។',
    },
    'quoteHistory': {
      AppLang.en: 'Quote history',
      AppLang.km: 'ប្រវត្តិសម្រង់ថ្លៃ'
    },
    'quoteStatusAccepted': {AppLang.en: 'Accepted', AppLang.km: 'បានទទួលយក'},
    'quoteStatusRejected': {AppLang.en: 'Declined', AppLang.km: 'បានបដិសេធ'},
    'quoteStatusRevised': {AppLang.en: 'Revised', AppLang.km: 'បានកែសម្រួល'},
    'quoteStatusPending': {
      AppLang.en: 'Awaiting your decision',
      AppLang.km: 'កំពុងរង់ចាំការសម្រេចចិត្តរបស់អ្នក'
    },
    'quoteAccepted': {
      AppLang.en: 'Quote accepted',
      AppLang.km: 'សម្រង់ថ្លៃត្រូវបានទទួលយក'
    },
    'quoteRejected': {
      AppLang.en: 'Quote declined',
      AppLang.km: 'សម្រង់ថ្លៃត្រូវបានបដិសេធ'
    },
    'rateTechnicianTitle': {
      AppLang.en: 'Rate your technician',
      AppLang.km: 'វាយតម្លៃជាងរបស់អ្នក'
    },
    'rateTechnicianPrompt': {
      AppLang.en: 'How was the service?',
      AppLang.km: 'សេវាកម្មនេះយ៉ាងណាដែរ?',
    },
    'reviewCommentHint': {
      AppLang.en: 'Share more about your experience (optional)',
      AppLang.km: 'ចែករំលែកបទពិសោធន៍របស់អ្នកបន្ថែម (មិនចាំបាច់)',
    },
    'submitReview': {
      AppLang.en: 'Submit review',
      AppLang.km: 'ដាក់ស្នើការវាយតម្លៃ'
    },
    'reviewRequired': {
      AppLang.en: 'Tap a star to rate your technician',
      AppLang.km: 'ចុចផ្កាយដើម្បីវាយតម្លៃជាងរបស់អ្នក',
    },
    'reviewSubmittedThanks': {
      AppLang.en: 'Thanks for your review!',
      AppLang.km: 'សូមអរគុណសម្រាប់ការវាយតម្លៃ!',
    },
    'yourReviewLabel': {
      AppLang.en: 'Your review',
      AppLang.km: 'ការវាយតម្លៃរបស់អ្នក'
    },
    'favorites': {AppLang.en: 'Favorites', AppLang.km: 'ចំណូលចិត្ត'},
    'favoritesEmpty': {
      AppLang.en: 'No saved technicians yet',
      AppLang.km: 'មិនទាន់មានជាងដែលបានរក្សាទុកទេ',
    },
    'favoritesEmptyHint': {
      AppLang.en:
          'Tap the heart on a technician you\'ve worked with to save them here.',
      AppLang.km:
          'ចុចរូបបេះដូងលើជាងដែលអ្នកធ្លាប់ធ្វើការជាមួយ ដើម្បីរក្សាទុកនៅទីនេះ។',
    },
    'addedToFavorites': {
      AppLang.en: 'Added to favorites',
      AppLang.km: 'បានបន្ថែមទៅចំណូលចិត្ត'
    },
    'removedFromFavorites': {
      AppLang.en: 'Removed from favorites',
      AppLang.km: 'បានដកចេញពីចំណូលចិត្ត'
    },
    'saveTechnicianTooltip': {
      AppLang.en: 'Save technician',
      AppLang.km: 'រក្សាទុកជាង'
    },
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
    'bookingAddress': {
      AppLang.en: 'Service address',
      AppLang.km: 'អាសយដ្ឋានសេវាកម្ម'
    },
    'bookingNote': {
      AppLang.en: 'Note (optional)',
      AppLang.km: 'កំណត់ចំណាំ (ស្រេចចិត្ត)'
    },
    'bookingNoteHint': {
      AppLang.en: 'Anything the technician should know…',
      AppLang.km: 'អ្វីៗដែលជាងគួរដឹង…',
    },
    'pickDate': {AppLang.en: 'Pick a date', AppLang.km: 'ជ្រើសរើសកាលបរិច្ឆេទ'},
    'pickTime': {AppLang.en: 'Pick a time', AppLang.km: 'ជ្រើសរើសម៉ោង'},
    'confirmBooking': {
      AppLang.en: 'Confirm Booking',
      AppLang.km: 'បញ្ជាក់ការកក់'
    },
    'bookingDone': {
      AppLang.en: 'Booking requested',
      AppLang.km: 'បានស្នើសុំការកក់'
    },
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
    'editProfile': {
      AppLang.en: 'Edit Profile',
      AppLang.km: 'កែសម្រួលប្រវត្តិរូប'
    },
    'edit': {AppLang.en: 'Edit', AppLang.km: 'កែសម្រួល'},
    'phone': {AppLang.en: 'Phone', AppLang.km: 'ទូរស័ព្ទ'},
    'email': {AppLang.en: 'Email', AppLang.km: 'អ៊ីមែល'},
    'address': {AppLang.en: 'Address', AppLang.km: 'អាសយដ្ឋាន'},
    'notSet': {AppLang.en: 'Not set', AppLang.km: 'មិនទាន់កំណត់'},
    'darkMode': {AppLang.en: 'Dark Mode', AppLang.km: 'របៀបងងឹត'},
    'language': {AppLang.en: 'Language', AppLang.km: 'ភាសា'},
    'languageOptionsDesc': {
      AppLang.en: 'English (US) / Khmer',
      AppLang.km: 'English (US) / ខ្មែរ',
    },
    'notifications': {AppLang.en: 'Notifications', AppLang.km: 'ការជូនដំណឹង'},
    'notificationsDesc': {
      AppLang.en: 'Get notified about your bookings and job updates',
      AppLang.km: 'ទទួលការជូនដំណឹងអំពីការកក់ និងស្ថានភាពការងាររបស់អ្នក',
    },
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
    'kilometers': {
      AppLang.en: 'Kilometers (km)',
      AppLang.km: 'គីឡូម៉ែត្រ (km)'
    },
    'miles': {AppLang.en: 'Miles (mi)', AppLang.km: 'ម៉ាយល៍ (mi)'},
    'defaultAddress': {
      AppLang.en: 'Default address',
      AppLang.km: 'អាសយដ្ឋានលំនាំដើម',
    },
    'defaultAddressHint': {
      AppLang.en:
          'Pre-fills new bookings so you don\'t have to pick it every time',
      AppLang.km:
          'បំពេញអាសយដ្ឋានជាមុនសម្រាប់ការកក់ថ្មី ដើម្បីកុំឲ្យត្រូវជ្រើសរើសម្តងទៀត',
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
      AppLang.km:
          'មានសំណួរអំពីទិន្នន័យរបស់អ្នក? ទាក់ទងមកយើងខ្ញុំតាម camfix098@gmail.com។',
    },

    // --- Edit Profile ------------------------------------------------------
    'fullName': {AppLang.en: 'Full Name', AppLang.km: 'ឈ្មោះពេញ'},
    'phoneNumber': {AppLang.en: 'Phone Number', AppLang.km: 'លេខទូរស័ព្ទ'},
    'phoneNumberHint': {AppLang.en: '97 123 4567', AppLang.km: '៩៧ ១២៣ ៤៥៦៧'},
    'dateOfBirth': {
      AppLang.en: 'Date of Birth',
      AppLang.km: 'ថ្ងៃខែឆ្នាំកំណើត'
    },
    'saveChange': {
      AppLang.en: 'Save Change',
      AppLang.km: 'រក្សាទុកការផ្លាស់ប្តូរ',
    },
    'saving': {AppLang.en: 'Saving…', AppLang.km: 'កំពុងរក្សាទុក…'},
    'selectDate': {
      AppLang.en: 'Select date',
      AppLang.km: 'ជ្រើសរើសកាលបរិច្ឆេទ'
    },
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
    'pickLocation': {
      AppLang.en: 'Pick a location',
      AppLang.km: 'ជ្រើសរើសទីតាំង'
    },
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
    'secAgo': {AppLang.en: 's ago', AppLang.km: 'វិនាទីមុន'},
    'minAgo': {AppLang.en: 'min ago', AppLang.km: 'នាទីមុន'},
    'hrAgo': {AppLang.en: 'h ago', AppLang.km: 'ម៉ោងមុន'},
    'dayAgo': {AppLang.en: 'd ago', AppLang.km: 'ថ្ងៃមុន'},
    'bookingFailed': {
      AppLang.en: "Couldn't send your booking",
      AppLang.km: 'មិនអាចផ្ញើការកក់របស់អ្នកបានទេ',
    },

    // --- Booking sheet: Immediate vs Scheduled ---------------------------
    'bookingWhen': {AppLang.en: 'When', AppLang.km: 'ពេលណា'},
    'bookingAvailableTime': {
      AppLang.en: 'Available Time',
      AppLang.km: 'ពេលវេលាទំនេរ'
    },
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

    // --- Booking sheet: Appointment vs Self Drop -------------------------
    'bookingType': {AppLang.en: 'Booking Type', AppLang.km: 'ប្រភេទការកក់'},
    'appointment': {AppLang.en: 'Appointment', AppLang.km: 'ណាត់ជួប'},
    'appointmentSub': {
      AppLang.en: 'Technician comes to you',
      AppLang.km: 'ជាងមករកអ្នក',
    },
    'selfDrop': {AppLang.en: 'Self Drop', AppLang.km: 'យកទៅដាក់ខ្លួនឯង'},
    'selfDropSub': {
      AppLang.en: 'You bring it to the shop',
      AppLang.km: 'អ្នកយកវាទៅហាង',
    },
    'selfDropUnavailable': {
      AppLang.en: 'Self Drop is only available with a registered technician.',
      AppLang.km: 'យកទៅដាក់ខ្លួនឯង អាចធ្វើបានតែជាមួយជាងដែលបានចុះឈ្មោះប៉ុណ្ណោះ។',
    },
    'dropOffLocation': {
      AppLang.en: 'Drop-Off Location',
      AppLang.km: 'ទីតាំងដាក់'
    },
    'directions': {AppLang.en: 'Directions', AppLang.km: 'ផ្លូវទៅ'},
    'arrivalTime': {AppLang.en: 'Arrival Time', AppLang.km: 'ពេលមកដល់'},
    'arriveNow': {AppLang.en: 'Now', AppLang.km: 'ឥឡូវនេះ'},
    'arriveInOneHour': {AppLang.en: 'In 1 hour', AppLang.km: 'ក្នុង ១ ម៉ោង'},
    'arriveAfternoon': {AppLang.en: 'This afternoon', AppLang.km: 'រសៀលនេះ'},
    'arriveTomorrowAfternoon': {
      AppLang.en: 'Tomorrow 2 PM',
      AppLang.km: 'ថ្ងៃស្អែក ម៉ោង ២ រសៀល',
    },
    'arriveCustom': {AppLang.en: 'Pick a time', AppLang.km: 'ជ្រើសម៉ោង'},
    'feesTitle': {
      AppLang.en: 'Deposit & Waiver',
      AppLang.km: 'ប្រាក់កក់ និងការលើកលែង'
    },
    'benchFee': {
      AppLang.en: 'Diagnostic fee (paid at drop-off)',
      AppLang.km: 'ថ្លៃពិនិត្យ (បង់ពេលដាក់)',
    },
    'travelFeeWaived': {AppLang.en: 'Travel fee', AppLang.km: 'ថ្លៃធ្វើដំណើរ'},
    'waived': {AppLang.en: 'Waived', AppLang.km: 'លើកលែង'},
    'homeVisitFrom': {
      AppLang.en: 'Home visit from',
      AppLang.km: 'មកផ្ទះ ចាប់ពី'
    },
    'selfDropFrom': {
      AppLang.en: 'Self Drop from',
      AppLang.km: 'យកទៅដាក់ ចាប់ពី'
    },
    'visitType': {AppLang.en: 'Visit Type', AppLang.km: 'ប្រភេទសេវា'},
    'confirmSelfDrop': {
      AppLang.en: 'Confirm Self Drop-Off Booking',
      AppLang.km: 'បញ្ជាក់ការកក់ យកទៅដាក់ខ្លួនឯង',
    },
    'stepDispatched': {AppLang.en: 'Dispatched', AppLang.km: 'បានបញ្ជូន'},
    'inLabel': {AppLang.en: 'In', AppLang.km: 'ក្នុង'},
    'waitingForTechnicianShort': {
      AppLang.en: 'Finding a technician',
      AppLang.km: 'កំពុងស្វែងរកជាង',
    },
    'trackLiveMap': {AppLang.en: 'Track Live Map', AppLang.km: 'តាមដានលើផែនទី'},
    'stepReadyForDropOff': {
      AppLang.en: 'Ready for drop-off',
      AppLang.km: 'រួចរាល់សម្រាប់ការយកមកដាក់',
    },
    'stepItemReceived': {
      AppLang.en: 'Item received',
      AppLang.km: 'បានទទួលរបស់'
    },
    'selfDropBringInfo': {
      AppLang.en: 'Bring your item to the shop at',
      AppLang.km: 'សូមយករបស់របស់អ្នកទៅហាងនៅ',
    },
    'selfDropReceivedInfo': {
      AppLang.en:
          'The technician has your item and will send a quote after inspection.',
      AppLang.km: 'ជាងបានទទួលរបស់អ្នក ហើយនឹងផ្ញើសម្រង់ថ្លៃបន្ទាប់ពីពិនិត្យ។',
    },
    'feeSelfDropBench': {
      AppLang.en:
          'Your item has already been inspected, so the diagnostic fee shown at booking applies.',
      AppLang.km:
          'របស់របស់អ្នកត្រូវបានពិនិត្យរួចហើយ ដូច្នេះថ្លៃពិនិត្យដែលបានបង្ហាញពេលកក់ត្រូវអនុវត្ត។',
    },
    'selfDropHowItWorks': {
      AppLang.en:
          'Bring the item to the technician at the time you choose. The final repair price is quoted after inspection.',
      AppLang.km:
          'យករបស់ទៅជាងតាមពេលដែលអ្នកជ្រើស។ តម្លៃជួសជុលចុងក្រោយនឹងត្រូវបានប្រាប់បន្ទាប់ពីពិនិត្យ។',
    },

    // --- Booking tracking screen ------------------------------------------
    'pending': {AppLang.en: 'Pending', AppLang.km: 'កំពុងរង់ចាំ'},
    'stepPending': {AppLang.en: 'Pending', AppLang.km: 'កំពុងរង់ចាំ'},
    'stepAccepted': {AppLang.en: 'Accepted', AppLang.km: 'បានទទួល'},
    'stepOnTheWay': {AppLang.en: 'On the way', AppLang.km: 'កំពុងធ្វើដំណើរមក'},
    'stepArrived': {AppLang.en: 'Arrived', AppLang.km: 'បានមកដល់'},
    'stepQuotePending': {
      AppLang.en: 'Quote review',
      AppLang.km: 'ពិនិត្យសម្រង់ថ្លៃ'
    },
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
    'scheduledFor': {
      AppLang.en: 'Scheduled for',
      AppLang.km: 'បានកំណត់សម្រាប់'
    },
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
      AppLang.en:
          'Cancelling this close to your scheduled time includes a fee.',
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

    // --- Payment ----------------------------------------------------------
    'payNow': {
      AppLang.en: 'Pay Now',
      AppLang.km: 'បង់ប្រាក់ឥឡូវនេះ',
    },
    'paymentSummaryTitle': {
      AppLang.en: 'Payment Summary',
      AppLang.km: 'សេចក្តីសង្ខេបការទូទាត់'
    },
    'costBreakdown': {
      AppLang.en: 'COST BREAKDOWN',
      AppLang.km: 'ការបំបែកតម្លៃ'
    },
    'baseServiceFee': {
      AppLang.en: 'Base Service Fee',
      AppLang.km: 'ថ្លៃសេវាមូលដ្ឋាន'
    },
    'standardPartsLabor': {
      AppLang.en: 'Standard Parts & Labor',
      AppLang.km: 'គ្រឿងបន្លាស់ និងកម្លាំងពលកម្ម'
    },
    'platformProcessing': {
      AppLang.en: 'Platform Processing',
      AppLang.km: 'ថ្លៃដំណើរការវេទិកា'
    },
    'taxes85': {AppLang.en: 'Taxes (8.5%)', AppLang.km: 'ពន្ធ (៨.៥%)'},

    // --- Quote line items + KHQR --------------------------------------------
    'inspectionSummary': {
      AppLang.en: 'Inspection Summary',
      AppLang.km: 'សេចក្ដីសង្ខេបការត្រួតពិនិត្យ'
    },
    'techRecommended': {AppLang.en: 'Tech Recommended', AppLang.km: 'ជាងណែនាំ'},
    'quotedWork': {AppLang.en: 'Quoted work', AppLang.km: 'ការងារដែលបានប៉ាន់'},
    'itemIncluded': {AppLang.en: 'Included', AppLang.km: 'រួមបញ្ចូល'},
    'itemSkipped': {AppLang.en: 'Skipped', AppLang.km: 'មិនយក'},
    'alwaysIncluded': {
      AppLang.en: 'ALWAYS INCLUDED',
      AppLang.km: 'រួមបញ្ចូលជានិច្ច',
    },
    'feesWord': {AppLang.en: 'Fees', AppLang.km: 'ថ្លៃសេវា'},
    'confirmWord': {AppLang.en: 'Confirm', AppLang.km: 'បញ្ជាក់'},
    'declineWholeQuote': {
      AppLang.en: 'Decline this quote',
      AppLang.km: 'បដិសេធសម្រង់ថ្លៃនេះ',
    },
    'customizeQuoteNote': {
      AppLang.en:
          'Tick only the items you want done. Unticked items will not be performed or charged.',
      AppLang.km:
          'ធីកតែការងារដែលអ្នកចង់ឱ្យធ្វើ។ ការងារដែលមិនបានធីក នឹងមិនត្រូវធ្វើ ឬគិតថ្លៃទេ។',
    },
    'khqrTitle': {AppLang.en: 'KHQR (Bakong)', AppLang.km: 'KHQR (បាគង)'},
    'khqrSubtitle': {
      AppLang.en: 'Scan with ABA, ACLEDA or any Bakong app',
      AppLang.km: 'ស្កេនជាមួយ ABA, ACLEDA ឬកម្មវិធីបាគងណាមួយ',
    },
    'scanWithBanking': {
      AppLang.en: 'Scan with Mobile Banking',
      AppLang.km: 'ស្កេនជាមួយកម្មវិធីធនាគារ',
    },
    'khqrBanksHint': {
      AppLang.en: 'Works with any Bakong member bank app',
      AppLang.km: 'ប្រើបានជាមួយកម្មវិធីធនាគារសមាជិកបាគងទាំងអស់',
    },
    'khqrWaiting': {
      AppLang.en: 'Waiting for your payment - confirmed automatically',
      AppLang.km: 'កំពុងរង់ចាំការទូទាត់ - បញ្ជាក់ដោយស្វ័យប្រវត្តិ',
    },
    'khqrExpired': {
      AppLang.en: 'This QR expired. Generate a new one to pay.',
      AppLang.km: 'QR នេះផុតកំណត់ហើយ។ សូមបង្កើតថ្មីដើម្បីបង់។',
    },
    'newQr': {AppLang.en: 'New QR', AppLang.km: 'QR ថ្មី'},
    'copyKhqr': {AppLang.en: 'Copy KHQR code', AppLang.km: 'ចម្លងកូដ KHQR'},
    'khqrCopied': {
      AppLang.en: 'KHQR code copied',
      AppLang.km: 'បានចម្លងកូដ KHQR'
    },
    'bakongKhqrTab': {AppLang.en: 'Bakong KHQR', AppLang.km: 'Bakong KHQR'},
    'abaMobileTab': {AppLang.en: 'ABA Mobile', AppLang.km: 'ABA Mobile'},
    'acledaPayTab': {AppLang.en: 'ACLEDA Pay', AppLang.km: 'ACLEDA Pay'},
    'downloadQr': {AppLang.en: 'Download QR', AppLang.km: 'ទាញយក QR'},
    'paywayLink': {
      AppLang.en: 'PayWay - Payment Link',
      AppLang.km: 'PayWay - តំណទូទាត់',
    },
    'autoVerifying': {
      AppLang.en: 'Auto-verifying payment status...',
      AppLang.km: 'កំពុងផ្ទៀងផ្ទាត់ការទូទាត់ដោយស្វ័យប្រវត្តិ...',
    },
    'directPay': {AppLang.en: 'DIRECT PAY', AppLang.km: 'ទូទាត់ផ្ទាល់'},
    'scanPayDone': {
      AppLang.en: 'Scan. Pay. Done.',
      AppLang.km: 'ស្កេន. បង់ប្រាក់. រួចរាល់.',
    },
    'memberOfKhqr': {
      AppLang.en: 'Member of KHQR',
      AppLang.km: 'សមាជិកនៃ KHQR',
    },
    'openAbaApp': {
      AppLang.en: 'Open ABA Mobile',
      AppLang.km: 'បើកកម្មវិធី ABA Mobile',
    },
    'openAcledaApp': {
      AppLang.en: 'Open ACLEDA Mobile',
      AppLang.km: 'បើកកម្មវិធី ACLEDA',
    },
    'confirmPaymentPrompt': {
      AppLang.en: 'Have you completed the payment in your banking app?',
      AppLang.km: 'តើអ្នកបានបញ្ចប់ការបង់ប្រាក់ក្នុងកម្មវិធីធនាគារហើយឬនៅ?',
    },
    'confirmPaid': {
      AppLang.en: 'Yes, I have paid',
      AppLang.km: 'បាទ/ចាស បានបង់រួចហើយ',
    },

    // --- Tracking technician (redesign) -------------------------------------
    'trackingTechnician': {
      AppLang.en: 'Tracking technician',
      AppLang.km: 'តាមដានជាង'
    },
    'stageWaiting': {
      AppLang.en: 'Waiting Acceptance',
      AppLang.km: 'រង់ចាំការទទួលយក'
    },
    'stageTraveling': {
      AppLang.en: 'Technician Traveling',
      AppLang.km: 'ជាងកំពុងធ្វើដំណើរ'
    },
    'stageArrived': {AppLang.en: 'Arrived', AppLang.km: 'បានមកដល់'},
    'stageDiagnose': {
      AppLang.en: 'Diagnose & Inspection',
      AppLang.km: 'វិភាគ និងត្រួតពិនិត្យ'
    },
    'stageRepair': {
      AppLang.en: 'Repair in Progress',
      AppLang.km: 'កំពុងជួសជុល'
    },
    'stageComplete': {
      AppLang.en: 'Work Complete',
      AppLang.km: 'ការងារបានបញ្ចប់'
    },
    'stageReview': {
      AppLang.en: 'Review & Rating',
      AppLang.km: 'មតិ និងការវាយតម្លៃ'
    },
    'stageWaitingDesc': {AppLang.en: 'You booked', AppLang.km: 'អ្នកបានកក់'},
    'stageTravelingDesc': {
      AppLang.en: 'is on the way to your address',
      AppLang.km: 'កំពុងធ្វើដំណើរមកអាសយដ្ឋានរបស់អ្នក',
    },
    'stageArrivedDesc': {
      AppLang.en: 'Technician arrived at your location',
      AppLang.km: 'ជាងបានមកដល់ទីតាំងរបស់អ្នក',
    },
    'stageDiagnoseDesc': {
      AppLang.en: 'Technician inspects and sends you an itemized quote',
      AppLang.km: 'ជាងត្រួតពិនិត្យ ហើយផ្ញើសម្រង់ថ្លៃលម្អិតមកអ្នក',
    },
    'stageRepairDesc': {
      AppLang.en: 'Work starts once you accept the quote',
      AppLang.km: 'ការងារចាប់ផ្តើមពេលអ្នកទទួលយកសម្រង់ថ្លៃ',
    },
    'stageCompleteDesc': {
      AppLang.en: 'Technician marks the job complete',
      AppLang.km: 'ជាងសម្គាល់ថាការងារបានបញ្ចប់',
    },
    'stageReviewDesc': {
      AppLang.en: 'Rate your technician and leave a comment',
      AppLang.km: 'វាយតម្លៃជាងរបស់អ្នក ហើយផ្តល់មតិ',
    },
    'notYetAccepted': {
      AppLang.en: 'Not yet accepted',
      AppLang.km: 'មិនទាន់ទទួលយក'
    },
    'bookingAccepted': {
      AppLang.en: 'Booking accepted',
      AppLang.km: 'ការកក់ត្រូវបានទទួលយក'
    },
    'liveWord': {AppLang.en: 'Live', AppLang.km: 'ផ្ទាល់'},
    'statusCaps': {AppLang.en: 'STATUS', AppLang.km: 'ស្ថានភាព'},
    'acceptedYourBooking': {
      AppLang.en: 'accepted your booking',
      AppLang.km: 'បានទទួលយកការកក់របស់អ្នក',
    },
    'technicianHasArrived': {
      AppLang.en: 'Technician has arrived',
      AppLang.km: 'ជាងបានមកដល់ហើយ',
    },
    'liveServiceTracking': {
      AppLang.en: 'LIVE SERVICE TRACKING',
      AppLang.km: 'តាមដានសេវាផ្ទាល់',
    },
    'arrivingIn': {AppLang.en: 'Arriving in', AppLang.km: 'មកដល់ក្នុង'},
    'jobDoneWord': {AppLang.en: 'job done', AppLang.km: 'ការងារបានធ្វើ'},
    'upNextState': {AppLang.en: 'Up next', AppLang.km: 'បន្ទាប់'},
    'jobsDoneWord': {AppLang.en: 'jobs done', AppLang.km: 'ការងារបានធ្វើ'},
    'quoteReviewTitle': {
      AppLang.en: 'Technician Quotation Review',
      AppLang.km: 'ពិនិត្យសម្រង់ថ្លៃរបស់ជាង',
    },
    'quoteReviewSub': {
      AppLang.en: 'Review the itemized quote and decide to proceed',
      AppLang.km: 'ពិនិត្យសម្រង់ថ្លៃលម្អិត ហើយសម្រេចចិត្តបន្ត',
    },
    'actionRequired': {
      AppLang.en: 'Action Required',
      AppLang.km: 'ត្រូវការសកម្មភាព'
    },
    'serviceProgress': {
      AppLang.en: 'Service Progress',
      AppLang.km: 'វឌ្ឍនភាពសេវា'
    },
    'serviceProgressSub': {
      AppLang.en: 'Every step of this booking, as it happens',
      AppLang.km: 'គ្រប់ជំហាននៃការកក់នេះ',
    },
    'doneState': {AppLang.en: 'Done', AppLang.km: 'រួចរាល់'},
    'inProgressState': {AppLang.en: 'In progress', AppLang.km: 'កំពុងដំណើរការ'},
    'pendingState': {AppLang.en: 'Pending', AppLang.km: 'កំពុងរង់ចាំ'},

    // --- Sign-in animation --------------------------------------------------
    'welcomeBack': {
      AppLang.en: 'Welcome back',
      AppLang.km: 'សូមស្វាគមន៍ការត្រឡប់មកវិញ'
    },
    'signedInLoading': {
      AppLang.en: 'Signed in • getting things ready…',
      AppLang.km: 'បានចូល • កំពុងរៀបចំ…',
    },

    // --- Booking page (Appointment | Self Drop) ---------------------------
    'openNow': {AppLang.en: 'Open now', AppLang.km: 'កំពុងបើក'},
    'closedNow': {AppLang.en: 'Closed', AppLang.km: 'បិទ'},
    'untilWord': {AppLang.en: 'until', AppLang.km: 'ដល់'},
    'opensWord': {AppLang.en: 'opens', AppLang.km: 'បើកនៅ'},
    'nearbyWord': {AppLang.en: 'Nearby', AppLang.km: 'នៅជិត'},
    'changeWord': {AppLang.en: 'Change', AppLang.km: 'ប្ដូរ'},
    'saveWord': {AppLang.en: 'Save', AppLang.km: 'សន្សំ'},
    'travelFeeBySelfDrop': {
      AppLang.en: 'travel fee by self dropping',
      AppLang.km: 'ថ្លៃធ្វើដំណើរ ដោយយកមកដាក់ខ្លួនឯង',
    },
    'benchFeePaidAtCounter': {
      AppLang.en:
          'You only pay the diagnostic fee at the counter when you drop the item off',
      AppLang.km: 'អ្នកបង់តែថ្លៃពិនិត្យនៅកន្លែងទទួល ពេលអ្នកយករបស់មកដាក់',
    },
    'noTravelFeeSelfDrop': {
      AppLang.en:
          'No travel fee is charged when you bring the item in yourself.',
      AppLang.km: 'មិនគិតថ្លៃធ្វើដំណើរ ពេលអ្នកយករបស់មកដាក់ខ្លួនឯង។',
    },
    'arrivalTimeWindow': {
      AppLang.en: 'Arrival Time Window',
      AppLang.km: 'ពេលមកដល់'
    },
    'depositBreakdownCaps': {
      AppLang.en: 'DEPOSIT & WAIVER BREAKDOWN',
      AppLang.km: 'ការបំបែកប្រាក់កក់ និងការលើកលែង',
    },
    'selfDropTravelWaiver': {
      AppLang.en: 'Self Drop travel waiver',
      AppLang.km: 'លើកលែងថ្លៃធ្វើដំណើរ',
    },
    'totalDepositDue': {
      AppLang.en: 'Total Deposit Due',
      AppLang.km: 'ប្រាក់កក់សរុប'
    },
    'payableAtCounter': {
      AppLang.en: 'Payable at the counter when you drop off',
      AppLang.km: 'បង់នៅកន្លែងទទួល ពេលអ្នកយកមកដាក់',
    },
    'arriveImmediately': {AppLang.en: 'Immediately', AppLang.km: 'ភ្លាមៗ'},
    'headOverNow': {AppLang.en: 'Head over now', AppLang.km: 'ចេញដំណើរឥឡូវនេះ'},
    'aroundWord': {AppLang.en: 'Around', AppLang.km: 'ប្រហែល'},
    'customSlot': {AppLang.en: 'Custom Slot', AppLang.km: 'ជ្រើសម៉ោងខ្លួនឯង'},
    'selectTime': {AppLang.en: 'Select time', AppLang.km: 'ជ្រើសម៉ោង'},
    'totalEstimated': {
      AppLang.en: 'Total Estimated',
      AppLang.km: 'តម្លៃប៉ាន់ស្មានសរុប'
    },
    'travelFeeWaivedShort': {
      AppLang.en: 'Travel fee',
      AppLang.km: 'ថ្លៃធ្វើដំណើរ'
    },
    'confirmDropOff': {
      AppLang.en: 'Confirm Drop-off Booking',
      AppLang.km: 'បញ្ជាក់ការកក់យកមកដាក់',
    },

    // --- Provider Achievements (select a service) ------------------------
    'doneWord': {AppLang.en: 'done', AppLang.km: 'បានធ្វើ'},
    'selectedWord': {AppLang.en: 'Selected', AppLang.km: 'បានជ្រើស'},
    'bookingWord': {AppLang.en: 'Booking', AppLang.km: 'កក់'},
    'estWord': {AppLang.en: 'Est.', AppLang.km: 'ប្រហែល'},
    'continueWithSelected': {
      AppLang.en: 'Continue with Selected',
      AppLang.km: 'បន្តជាមួយសេវាដែលបានជ្រើស',
    },

    // --- Profile (redesign) ----------------------------------------------
    'statRepairs': {AppLang.en: 'Repairs', AppLang.km: 'ការជួសជុល'},
    'statSaved': {AppLang.en: 'Saved', AppLang.km: 'បានរក្សាទុក'},
    'statAllTime': {AppLang.en: 'All time', AppLang.km: 'គ្រប់ពេល'},
    'accountPreferencesCaps': {
      AppLang.en: 'ACCOUNT & PREFERENCES',
      AppLang.km: 'គណនី និងចំណូលចិត្ត',
    },
    'supportTrustCaps': {
      AppLang.en: 'SUPPORT & TRUST',
      AppLang.km: 'ជំនួយ និងទំនុកចិត្ត'
    },
    'pushNotifications': {
      AppLang.en: 'Push Notifications',
      AppLang.km: 'ការជូនដំណឹង'
    },
    'appLanguage': {AppLang.en: 'App Language', AppLang.km: 'ភាសាកម្មវិធី'},
    'darkModeDesc': {
      AppLang.en: 'Easier on the eyes at night',
      AppLang.km: 'ស្រួលភ្នែកពេលយប់'
    },
    'preferenceDesc': {
      AppLang.en: 'Default address and distance units',
      AppLang.km: 'អាសយដ្ឋានលំនាំដើម និងឯកតាចម្ងាយ',
    },
    'helpCenter': {AppLang.en: 'Help Center', AppLang.km: 'មជ្ឈមណ្ឌលជំនួយ'},
    'helpCenterDesc': {
      AppLang.en: 'Contact us or browse common questions',
      AppLang.km: 'ទាក់ទងយើង ឬមើលសំណួរញឹកញាប់',
    },
    'trustShield': {
      AppLang.en: 'CAMFIX Trust & Shield',
      AppLang.km: 'ទំនុកចិត្ត និងសុវត្ថិភាព CAMFIX'
    },
    'trustShieldDesc': {
      AppLang.en: 'How we keep bookings safe • Privacy',
      AppLang.km: 'របៀបយើងរក្សាសុវត្ថិភាពការកក់ • ឯកជនភាព',
    },
    'trustPointReview': {
      AppLang.en:
          'Every technician is reviewed by our admin team before they can appear in the app or take jobs.',
      AppLang.km:
          'ជាងគ្រប់រូបត្រូវបានពិនិត្យដោយក្រុមអ្នកគ្រប់គ្រងមុនពេលពួកគេអាចបង្ហាញក្នុងកម្មវិធី ឬទទួលការងារ។',
    },
    'trustPointRatings': {
      AppLang.en:
          'Ratings come only from customers who completed a real booking with that technician.',
      AppLang.km:
          'ការវាយតម្លៃមកពីអតិថិជនដែលបានបញ្ចប់ការកក់ពិតប្រាកដជាមួយជាងនោះប៉ុណ្ណោះ។',
    },
    'trustPointQuotes': {
      AppLang.en:
          'You see an itemized quote and accept it before any repair work starts.',
      AppLang.km:
          'អ្នកឃើញសម្រង់ថ្លៃលម្អិត ហើយទទួលយកវាមុនពេលការងារជួសជុលចាប់ផ្តើម។',
    },
    'trustPointChat': {
      AppLang.en:
          'Chats are private to you and the technician on that booking.',
      AppLang.km: 'ការជជែកគឺឯកជនសម្រាប់អ្នក និងជាងនៃការកក់នោះប៉ុណ្ណោះ។',
    },

    // --- Real per-booking chat -------------------------------------------
    'messageNotSent': {
      AppLang.en: 'Message not sent',
      AppLang.km: 'សារមិនត្រូវបានផ្ញើ'
    },
    'yesterday': {AppLang.en: 'Yesterday', AppLang.km: 'ម្សិលមិញ'},
    'chatEmptyHint': {
      AppLang.en:
          'No messages yet. Say hello to your technician about this booking.',
      AppLang.km: 'មិនទាន់មានសារទេ។ ផ្ញើសារទៅជាងរបស់អ្នកអំពីការកក់នេះ។',
    },
    'bookingHash': {AppLang.en: 'Booking #', AppLang.km: 'ការកក់ #'},
    'call': {AppLang.en: 'Call', AppLang.km: 'ហៅ'},
    'seen': {AppLang.en: 'Seen', AppLang.km: 'បានឃើញ'},
    'noConversationsYet': {
      AppLang.en:
          'No conversations yet. Once a technician takes your booking, you can chat with them here.',
      AppLang.km:
          'មិនទាន់មានការសន្ទនាទេ។ ពេលជាងទទួលការកក់របស់អ្នក អ្នកអាចជជែកជាមួយពួកគេនៅទីនេះ។',
    },
    'chatStartPrompt': {
      AppLang.en: 'Tap to start chatting',
      AppLang.km: 'ចុចដើម្បីចាប់ផ្តើមជជែក'
    },
    'youPrefix': {AppLang.en: 'You:', AppLang.km: 'អ្នក៖'},
    'messageTechnician': {
      AppLang.en: 'Message technician',
      AppLang.km: 'ផ្ញើសារទៅជាង'
    },
    'chatNeedsBooking': {
      AppLang.en:
          'Book this technician first - chat opens once they have your booking.',
      AppLang.km:
          'សូមកក់ជាងនេះជាមុនសិន - ការជជែកនឹងបើកពេលពួកគេមានការកក់របស់អ្នក។',
    },

    // --- Total Spend / service history -----------------------------------
    'totalSpendTitle': {AppLang.en: 'Total Spend', AppLang.km: 'ការចំណាយសរុប'},
    'serviceHistory': {
      AppLang.en: 'Service History',
      AppLang.km: 'ប្រវត្តិសេវា'
    },
    'serviceHistorySub': {
      AppLang.en: 'Track all your maintenance and repair records in one place.',
      AppLang.km: 'តាមដានកំណត់ត្រាថែទាំ និងជួសជុលទាំងអស់របស់អ្នកនៅកន្លែងតែមួយ។',
    },
    'totalSpentCaps': {AppLang.en: 'TOTAL SPENT', AppLang.km: 'ចំណាយសរុប'},
    'jobsDoneCaps': {AppLang.en: 'JOBS DONE', AppLang.km: 'ការងារបានបញ្ចប់'},
    'spendingBreakdown': {
      AppLang.en: 'Spending & Category Breakdown',
      AppLang.km: 'ការចំណាយតាមប្រភេទ',
    },
    'spendingBreakdownSub': {
      AppLang.en: 'Swipe to see totals per category',
      AppLang.km: 'អូសដើម្បីមើលសរុបតាមប្រភេទ',
    },
    'categoryWord': {AppLang.en: 'category', AppLang.km: 'ប្រភេទ'},
    'categoriesWord': {AppLang.en: 'categories', AppLang.km: 'ប្រភេទ'},
    'overviewCaps': {AppLang.en: 'OVERVIEW', AppLang.km: 'ទិដ្ឋភាពទូទៅ'},
    'acrossWord': {AppLang.en: 'Across', AppLang.km: 'ពី'},
    'paidServices': {AppLang.en: 'paid services', AppLang.km: 'សេវាដែលបានបង់'},
    'ofTotalSpending': {
      AppLang.en: 'of total spending',
      AppLang.km: 'នៃការចំណាយសរុប'
    },
    'bookingHistory': {
      AppLang.en: 'Booking History',
      AppLang.km: 'ប្រវត្តិការកក់'
    },
    'bookingHistorySub': {
      AppLang.en: 'Manage and track your service history.',
      AppLang.km: 'គ្រប់គ្រង និងតាមដានប្រវត្តិសេវារបស់អ្នក។',
    },
    'activeTab': {AppLang.en: 'Active', AppLang.km: 'សកម្ម'},
    'completedTab': {AppLang.en: 'Completed', AppLang.km: 'បានបញ្ចប់'},
    'allFilter': {AppLang.en: 'All', AppLang.km: 'ទាំងអស់'},
    'sortNewest': {AppLang.en: 'Newest', AppLang.km: 'ថ្មីបំផុត'},
    'sortOldest': {AppLang.en: 'Oldest', AppLang.km: 'ចាស់បំផុត'},
    'sortHighLow': {AppLang.en: '\$ High-Low', AppLang.km: '\$ ខ្ពស់-ទាប'},
    'sortLowHigh': {AppLang.en: '\$ Low-High', AppLang.km: '\$ ទាប-ខ្ពស់'},
    'dateWord': {AppLang.en: 'Date', AppLang.km: 'កាលបរិច្ឆេទ'},
    'amountWord': {AppLang.en: 'Amount', AppLang.km: 'ចំនួន'},
    'noActiveBookings': {
      AppLang.en: 'No active bookings right now.',
      AppLang.km: 'មិនមានការកក់សកម្មទេ។',
    },
    'noPastBookings': {
      AppLang.en: 'No completed bookings yet.',
      AppLang.km: 'មិនទាន់មានការកក់ដែលបានបញ្ចប់ទេ។',
    },
    'invoiceCaps': {AppLang.en: 'INVOICE', AppLang.km: 'វិក្កយបត្រ'},
    'paidVia': {AppLang.en: 'Paid via', AppLang.km: 'បង់តាម'},
    'viewInvoice': {AppLang.en: 'View Invoice', AppLang.km: 'មើលវិក្កយបត្រ'},
    'trackWord': {AppLang.en: 'Track', AppLang.km: 'តាមដាន'},
    'statusCancelled': {AppLang.en: 'Cancelled', AppLang.km: 'បានបោះបង់'},

    // --- Booking receipt --------------------------------------------------
    'bookingReceipt': {
      AppLang.en: 'Booking Receipt',
      AppLang.km: 'បង្កាន់ដៃការកក់'
    },
    'dateWindow': {
      AppLang.en: 'Date & Time',
      AppLang.km: 'កាលបរិច្ឆេទ និងម៉ោង'
    },
    'serviceAddress': {
      AppLang.en: 'Service Address',
      AppLang.km: 'អាសយដ្ឋានសេវា'
    },
    'paymentBreakdown': {
      AppLang.en: 'PAYMENT BREAKDOWN',
      AppLang.km: 'ការបំបែកការទូទាត់',
    },
    'subtotal': {AppLang.en: 'Subtotal', AppLang.km: 'សរុបរង'},
    'paidBadge': {AppLang.en: 'Paid', AppLang.km: 'បានបង់'},
    'unpaidBadge': {AppLang.en: 'Unpaid', AppLang.km: 'មិនទាន់បង់'},
    'receiptCopied': {
      AppLang.en: 'Receipt copied - paste it anywhere to share',
      AppLang.km: 'បានចម្លងបង្កាន់ដៃ - បិទភ្ជាប់ដើម្បីចែករំលែក',
    },
    'viewReceipt': {AppLang.en: 'View Receipt', AppLang.km: 'មើលបង្កាន់ដៃ'},
    'approvedTechnician': {
      AppLang.en: 'Approved Technician',
      AppLang.km: 'ជាងដែលបានអនុម័ត',
    },
    'receiptNoQuote': {
      AppLang.en:
          'No accepted quote yet - the breakdown appears once you accept the technician\'s quote.',
      AppLang.km:
          'មិនទាន់មានសម្រង់ថ្លៃដែលបានទទួលយក - ការបំបែកនឹងបង្ហាញបន្ទាប់ពីអ្នកទទួលយកសម្រង់ថ្លៃរបស់ជាង។',
    },
    'paidOn': {AppLang.en: 'Paid on', AppLang.km: 'បានបង់នៅ'},
    'completedOn': {AppLang.en: 'Completed', AppLang.km: 'បានបញ្ចប់'},
    'totalAmount': {
      AppLang.en: 'Total Amount',
      AppLang.km: 'ចំនួនទឹកប្រាក់សរុប'
    },
    'pay': {AppLang.en: 'Pay', AppLang.km: 'ទូទាត់'},
    'paymentMethodTitle': {
      AppLang.en: 'Payment Method',
      AppLang.km: 'វិធីទូទាត់'
    },
    'choosePaymentMethod': {
      AppLang.en: 'CHOOSE PAYMENT METHOD',
      AppLang.km: 'ជ្រើសរើសវិធីទូទាត់'
    },
    'choosePaymentMethodHint': {
      AppLang.en: 'Select your preferred way to pay for the service.',
      AppLang.km: 'ជ្រើសរើសវិធីដែលអ្នកចង់ប្រើដើម្បីទូទាត់ថ្លៃសេវា។',
    },
    'localBank': {
      AppLang.en: 'AC / ABA Local Bank',
      AppLang.km: 'AC / ABA ធនាគារក្នុងស្រុក',
    },
    'localBankSubtitle': {
      AppLang.en: 'Pay with your banking app via KHQR',
      AppLang.km: 'បង់ប្រាក់តាមកម្មវិធីធនាគាររបស់អ្នកតាម KHQR',
    },
    'localBankUnavailable': {
      AppLang.en:
          'Local bank payment is currently unavailable. Please try again later.',
      AppLang.km:
          'ការបង់ប្រាក់តាមធនាគារក្នុងស្រុកមិនអាចប្រើបាននៅពេលនេះទេ។ សូមព្យាយាមម្តងទៀតនៅពេលក្រោយ។',
    },
    'applePay': {AppLang.en: 'Apple Pay', AppLang.km: 'Apple Pay'},
    'applePaySubtitle': {
      AppLang.en: 'Fast and secure checkout',
      AppLang.km: 'ការទូទាត់រហ័ស និងសុវត្ថិភាព'
    },
    'creditDebitCard': {
      AppLang.en: 'Credit or Debit Card',
      AppLang.km: 'កាតឥណទាន ឬឥណពន្ធ'
    },
    'creditDebitCardSubtitle': {
      AppLang.en: 'Visa, Mastercard, AMEX',
      AppLang.km: 'Visa, Mastercard, AMEX'
    },
    'cardEndingIn': {
      AppLang.en: 'Card ending in',
      AppLang.km: 'កាតបញ្ចប់ដោយលេខ'
    },
    'paypalWallet': {
      AppLang.en: 'PayPal / Digital Wallet',
      AppLang.km: 'PayPal / កាបូបឌីជីថល'
    },
    'paypalWalletSubtitle': {
      AppLang.en: 'Secure external wallet payment',
      AppLang.km: 'ការទូទាត់ដោយកាបូបខាងក្រៅដែលមានសុវត្ថិភាព'
    },
    'paymentsSecureNote': {
      AppLang.en: 'Payments are secure and encrypted.',
      AppLang.km: 'ការទូទាត់មានសុវត្ថិភាព និងបានអ៊ិនគ្រីប។'
    },
    'paymentWallet': {
      AppLang.en: 'Payment & Wallet',
      AppLang.km: 'ការទូទាត់ និងកាបូប'
    },
    'assetsBound': {
      AppLang.en: 'Assets bound',
      AppLang.km: 'វិធីទូទាត់ដែលបានភ្ជាប់'
    },
    'cash': {AppLang.en: 'Cash', AppLang.km: 'សាច់ប្រាក់'},
    'cashSubtitle': {
      AppLang.en: 'Pay the technician directly',
      AppLang.km: 'ទូទាត់ដោយផ្ទាល់ជាមួយជាង'
    },
    'expires': {AppLang.en: 'Expires', AppLang.km: 'ផុតកំណត់'},
    'addCardHint': {
      AppLang.en: 'Tap to add a card',
      AppLang.km: 'ចុចដើម្បីបន្ថែមកាត'
    },
    'addNewCardLink': {
      AppLang.en: 'Add new Credit & Debit Card',
      AppLang.km: 'បន្ថែមកាតឥណទាន ឬឥណពន្ធថ្មី'
    },
    'addCreditDebitCard': {
      AppLang.en: 'Add Credit/Debit card',
      AppLang.km: 'បន្ថែមកាតឥណទាន/ឥណពន្ធ'
    },
    'defaultLabel': {AppLang.en: 'Default', AppLang.km: 'លំនាំដើម'},
    'confirmPayment': {
      AppLang.en: 'Confirm Payment',
      AppLang.km: 'បញ្ជាក់ការទូទាត់'
    },
    'addNewCardTitle': {
      AppLang.en: 'Add New Card',
      AppLang.km: 'បន្ថែមកាតថ្មី'
    },
    'cardholderName': {
      AppLang.en: 'Cardholder Name',
      AppLang.km: 'ឈ្មោះម្ចាស់កាត'
    },
    'cardholderNameHint': {
      AppLang.en: 'Enter full name',
      AppLang.km: 'បញ្ចូលឈ្មោះពេញ'
    },
    'cardNumber': {AppLang.en: 'Card Number', AppLang.km: 'លេខកាត'},
    'expiryDate': {
      AppLang.en: 'Expiry Date',
      AppLang.km: 'កាលបរិច្ឆេទផុតកំណត់'
    },
    'yourName': {AppLang.en: 'YOUR NAME', AppLang.km: 'ឈ្មោះរបស់អ្នក'},
    'cardHolderRequired': {
      AppLang.en: 'Enter the cardholder name',
      AppLang.km: 'សូមបញ្ចូលឈ្មោះម្ចាស់កាត'
    },
    'cardNumberInvalid': {
      AppLang.en: 'Enter a valid 16-digit card number',
      AppLang.km: 'សូមបញ្ចូលលេខកាត ១៦ខ្ទង់ដែលត្រឹមត្រូវ'
    },
    'cardExpiryInvalid': {
      AppLang.en: 'Enter a valid expiry date (MM/YY)',
      AppLang.km: 'សូមបញ្ចូលកាលបរិច្ឆេទផុតកំណត់ត្រឹមត្រូវ (ខែ/ឆ្នាំ)'
    },
    'cardCvvInvalid': {
      AppLang.en: 'Enter a valid CVV',
      AppLang.km: 'សូមបញ្ចូល CVV ត្រឹមត្រូវ'
    },
    'addCard': {AppLang.en: 'Add Card', AppLang.km: 'បន្ថែមកាត'},
    'cardEncryptionNote': {
      AppLang.en: 'PCI-DSS compliant 256-bit encryption',
      AppLang.km: 'អ៊ិនគ្រីប 256-bit អនុលោមតាម PCI-DSS'
    },
    'paymentSuccessfulTitle': {
      AppLang.en: 'Payment Successful',
      AppLang.km: 'ការទូទាត់បានជោគជ័យ'
    },
    'paymentSuccessfulBody': {
      AppLang.en: 'Your transaction has been processed successfully.',
      AppLang.km: 'ប្រតិបត្តិការរបស់អ្នកត្រូវបានដំណើរការដោយជោគជ័យ។',
    },
    'serviceId': {AppLang.en: 'Service ID', AppLang.km: 'លេខសម្គាល់សេវា'},
    'amountPaid': {
      AppLang.en: 'Amount Paid',
      AppLang.km: 'ចំនួនទឹកប្រាក់បានទូទាត់'
    },
    'dateTime': {AppLang.en: 'Date & Time', AppLang.km: 'កាលបរិច្ឆេទ និងម៉ោង'},
    'paymentMethodLabel': {
      AppLang.en: 'Payment Method',
      AppLang.km: 'វិធីទូទាត់'
    },
    'downloadReceipt': {
      AppLang.en: 'Download Receipt',
      AppLang.km: 'ទាញយកបង្កាន់ដៃ'
    },
    'returnToHome': {
      AppLang.en: 'Return to Home',
      AppLang.km: 'ត្រឡប់ទៅទំព័រដើម'
    },
    'receiptTitle': {AppLang.en: 'Receipt', AppLang.km: 'បង្កាន់ដៃ'},
    'promoCodeHint': {AppLang.en: 'Promo Code', AppLang.km: 'កូដប្រូម៉ូសិន'},
    'apply': {AppLang.en: 'Apply', AppLang.km: 'អនុវត្ត'},
    'promoCodeEmpty': {
      AppLang.en: 'Enter a promo code first',
      AppLang.km: 'សូមបញ្ចូលកូដប្រូម៉ូសិនជាមុន'
    },
    'promoCodeNoneAvailable': {
      AppLang.en: 'No promo codes are available right now',
      AppLang.km: 'មិនមានកូដប្រូម៉ូសិននៅពេលនេះទេ',
    },
    'noPaymentMethodYet': {
      AppLang.en: 'No payment method added yet',
      AppLang.km: 'មិនទាន់មានវិធីទូទាត់ទេ'
    },
    'editCard': {AppLang.en: 'Edit', AppLang.km: 'កែសម្រួល'},
  };
}
