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
  static String jobStatus(String code, {bool selfDrop = false}) {
    // Self Drop reuses the same statuses, but nobody travels: ON_THE_WAY
    // means "accepted, waiting for the customer" and ARRIVED means the item
    // has been handed over at the shop.
    if (selfDrop && code == 'ON_THE_WAY') return t('statusAwaitingDropOff');
    if (selfDrop && code == 'ARRIVED') return t('statusItemReceived');
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

  /// Localised label for a preset opening-hours option (see
  /// [kOpeningHoursOptions]). Falls back to the raw string for a custom
  /// (freely typed) value.
  static String openingHoursOption(String english) {
    const keys = {
      'Everyday, 8:00 AM – 6:00 PM': 'hoursEveryday8to6',
      'Everyday, 24 Hours': 'hoursEveryday24',
      'Monday – Friday, 8:00 AM – 6:00 PM': 'hoursMonFri8to6',
      'Monday – Saturday, 8:00 AM – 6:00 PM': 'hoursMonSat8to6',
      'Monday – Saturday, 6:00 AM – 11:00 PM': 'hoursMonSat6to11',
      'Monday – Sunday, 7:00 AM – 9:00 PM': 'hoursMonSun7to9',
    };
    final key = keys[english];
    return key == null ? english : t(key);
  }

  static const Map<String, Map<AppLang, String>> _map = {
    'faceFrameHint': {
      AppLang.en: 'Keep your face centered',
      AppLang.km: 'ដាក់មុខរបស់អ្នកនៅចំកណ្តាល',
    },
    'reviewFacePhoto': {
      AppLang.en: 'Review your photo',
      AppLang.km: 'ពិនិត្យរូបថតរបស់អ្នក',
    },
    'confirmPhoneTitle': {
      AppLang.en: 'Verify your number',
      AppLang.km: 'ផ្ទៀងផ្ទាត់លេខទូរស័ព្ទ',
    },
    'otpTryAgain': {
      AppLang.en: 'Could not verify right now. Please try again.',
      AppLang.km: 'មិនអាចផ្ទៀងផ្ទាត់ឥឡូវនេះបានទេ។ សូមសាកល្បងម្តងទៀត។',
    },
    'smsCodeIntro': {
      AppLang.en: 'Enter the 6-digit code sent by SMS to',
      AppLang.km: 'បញ្ចូលលេខកូដ ៦ ខ្ទង់ដែលបានផ្ញើតាម SMS ទៅ',
    },
    'changePhoneNumber': {
      AppLang.en: 'Change phone number',
      AppLang.km: 'ប្តូរលេខទូរស័ព្ទ',
    },
    'verifyAndRegister': {
      AppLang.en: 'Verify & create account',
      AppLang.km: 'ផ្ទៀងផ្ទាត់ និងបង្កើតគណនី',
    },
    'noSmsYet': {
      AppLang.en: 'Didn’t receive a code?',
      AppLang.km: 'មិនបានទទួលលេខកូដមែនទេ?',
    },
    'sendingSms': {AppLang.en: 'Sending code…', AppLang.km: 'កំពុងផ្ញើលេខកូដ…'},
    'otpPrivate': {
      AppLang.en: 'Keep your verification code private.',
      AppLang.km: 'សូមរក្សាលេខកូដផ្ទៀងផ្ទាត់ជាសម្ងាត់។',
    },
    'continueVerification': {
      AppLang.en: 'Next: Verify identity',
      AppLang.km: 'បន្ទាប់៖ ផ្ទៀងផ្ទាត់អត្តសញ្ញាណ',
    },
    'verifyIdentityTitle': {
      AppLang.en: 'Verify identity',
      AppLang.km: 'ផ្ទៀងផ្ទាត់អត្តសញ្ញាណ',
    },
    'verificationStep': {
      AppLang.en: 'STEP 2 OF 3',
      AppLang.km: 'ជំហានទី ២ នៃ ៣',
    },
    'verificationStep3': {
      AppLang.en: 'STEP 3 OF 3',
      AppLang.km: 'ជំហានទី ៣ នៃ ៣',
    },
    'verifyIdentityIntro': {
      AppLang.en:
          'Add your ID card and take a clear face photo to complete registration.',
      AppLang.km:
          'បញ្ចូលអត្តសញ្ញាណប័ណ្ណ និងថតរូបមុខឱ្យច្បាស់ ដើម្បីបញ្ចប់ការចុះឈ្មោះ។',
    },
    'facePhotoTitle': {AppLang.en: 'Face photo', AppLang.km: 'រូបថតមុខ'},
    'facePhotoHelp': {
      AppLang.en:
          'Face the camera in good light. Keep your whole face visible and remove sunglasses or a mask.',
      AppLang.km:
          'បែរមុខទៅកាមេរ៉ានៅកន្លែងមានពន្លឺល្អ។ បង្ហាញមុខទាំងមូល ហើយដោះវ៉ែនតាខ្មៅ ឬម៉ាស់ចេញ។',
    },
    'openFaceCamera': {AppLang.en: 'Open camera', AppLang.km: 'បើកកាមេរ៉ា'},
    'captureFacePhoto': {AppLang.en: 'Take face photo', AppLang.km: 'ថតរូបមុខ'},
    'retakeFacePhoto': {AppLang.en: 'Retake photo', AppLang.km: 'ថតរូបឡើងវិញ'},
    'useFacePhoto': {AppLang.en: 'Use this photo', AppLang.km: 'ប្រើរូបថតនេះ'},
    'retryCamera': {
      AppLang.en: 'Try camera again',
      AppLang.km: 'សាកល្បងកាមេរ៉ាម្តងទៀត',
    },
    'cameraUnavailable': {
      AppLang.en:
          'Camera unavailable. Allow camera access in your browser or device settings, then try again. On the web, use HTTPS or localhost.',
      AppLang.km:
          'មិនអាចបើកកាមេរ៉ាបាន។ សូមអនុញ្ញាតការប្រើកាមេរ៉ាក្នុងការកំណត់ រួចសាកល្បងម្តងទៀត។ លើគេហទំព័រ សូមប្រើ HTTPS ឬ localhost។',
    },
    'verifyByEmailInstead': {
      AppLang.en: 'Verify by email instead',
      AppLang.km: 'ផ្ទៀងផ្ទាត់តាមអ៊ីមែលជំនួសវិញ',
    },
    'verifyByEmailTitle': {
      AppLang.en: 'Or verify by email',
      AppLang.km: 'ឬផ្ទៀងផ្ទាត់តាមអ៊ីមែល',
    },
    'verifyByEmailHelp': {
      AppLang.en:
          "Don't want to take a face photo? We'll send a 6-digit code to {email} instead.",
      AppLang.km:
          'មិនចង់ថតរូបមុខទេឬ? យើងនឹងផ្ញើលេខកូដ៦ខ្ទង់ទៅ {email} ជំនួសវិញ។',
    },
    'verifyByEmailCodeSent': {
      AppLang.en: 'Enter the 6-digit code sent to {email}.',
      AppLang.km: 'បញ្ចូលលេខកូដ៦ខ្ទង់ដែលបានផ្ញើទៅ {email}។',
    },
    'sendEmailCode': {AppLang.en: 'Send code', AppLang.km: 'ផ្ញើលេខកូដ'},
    'resendEmailCode': {
      AppLang.en: 'Resend code',
      AppLang.km: 'ផ្ញើលេខកូដម្តងទៀត',
    },
    'emailCodeLabel': {AppLang.en: '6-digit code', AppLang.km: 'លេខកូដ៦ខ្ទង់'},
    'useFacePhotoInstead': {
      AppLang.en: 'Use face photo instead',
      AppLang.km: 'ប្រើរូបថតមុខជំនួសវិញ',
    },
    'cameraCaptureFailed': {
      AppLang.en: 'Could not take the photo. Please try again.',
      AppLang.km: 'មិនអាចថតរូបបាន។ សូមសាកល្បងម្តងទៀត។',
    },
    'photoTooLarge': {
      AppLang.en: 'Each photo must be no larger than 5 MB.',
      AppLang.km: 'រូបថតនីមួយៗមិនត្រូវលើស 5 MB។',
    },
    'identityReviewNote': {
      AppLang.en:
          'Only admins can view these verification photos. Your account stays pending until an admin reviews your ID and face photo.',
      AppLang.km:
          'មានតែអ្នកគ្រប់គ្រងប៉ុណ្ណោះដែលអាចមើលរូបផ្ទៀងផ្ទាត់ទាំងនេះ។ គណនីរបស់អ្នករង់ចាំរហូតដល់អ្នកគ្រប់គ្រងពិនិត្យអត្តសញ្ញាណប័ណ្ណ និងរូបមុខ។',
    },
    'submitIdentity': {
      AppLang.en: 'Submit for verification',
      AppLang.km: 'បញ្ជូនសម្រាប់ផ្ទៀងផ្ទាត់',
    },
    'idCardTitle': {AppLang.en: 'Identity card', AppLang.km: 'អត្តសញ្ញាណប័ណ្ណ'},
    'idCardHelp': {
      AppLang.en:
          'Upload a clear photo of your ID card for admin review (JPEG or PNG, up to 5 MB).',
      AppLang.km:
          'សូមបញ្ចូលរូបថតអត្តសញ្ញាណប័ណ្ណច្បាស់សម្រាប់អ្នកគ្រប់គ្រងពិនិត្យ (JPEG ឬ PNG ទំហំអតិបរមា 5 MB)។',
    },
    'selectIdCard': {
      AppLang.en: 'Select ID card',
      AppLang.km: 'ជ្រើសរើសអត្តសញ្ញាណប័ណ្ណ',
    },
    'replaceIdCard': {
      AppLang.en: 'Replace ID card',
      AppLang.km: 'ប្តូររូបអត្តសញ្ញាណប័ណ្ណ',
    },
    'idCardRequired': {
      AppLang.en: 'Please select your ID card photo.',
      AppLang.km: 'សូមជ្រើសរើសរូបថតអត្តសញ្ញាណប័ណ្ណរបស់អ្នក។',
    },
    'idCardTooLarge': {
      AppLang.en: 'ID card photo must be no larger than 5 MB.',
      AppLang.km: 'រូបថតអត្តសញ្ញាណប័ណ្ណមិនត្រូវលើស 5 MB។',
    },
    'idCardInvalid': {
      AppLang.en: 'Please choose a valid JPEG or PNG image.',
      AppLang.km: 'សូមជ្រើសរើសរូបភាព JPEG ឬ PNG ដែលត្រឹមត្រូវ។',
    },
    // --- Common -----------------------------------------------------------
    'appName': {AppLang.en: 'CAM FIX', AppLang.km: 'CAM FIX'},
    'technician': {AppLang.en: 'Technician', AppLang.km: 'ជាងជួសជុល'},
    'camfixTechnician': {
      AppLang.en: 'CAM FIX Technician',
      AppLang.km: 'ជាង CAM FIX',
    },
    'cancel': {AppLang.en: 'Cancel', AppLang.km: 'បោះបង់'},
    'save': {AppLang.en: 'Save', AppLang.km: 'រក្សាទុក'},
    'delete': {AppLang.en: 'Delete', AppLang.km: 'លុប'},

    // --- Service listings ---------------------------------------------------
    'myServices': {AppLang.en: 'My Services', AppLang.km: 'សេវាកម្មរបស់ខ្ញុំ'},
    'addService': {AppLang.en: 'Add Service', AppLang.km: 'បន្ថែមសេវាកម្ម'},
    'editService': {AppLang.en: 'Edit Service', AppLang.km: 'កែសម្រួលសេវាកម្ម'},
    'noServicesYet': {
      AppLang.en:
          "You haven't added any services yet. Add one so customers can see and book it directly.",
      AppLang.km:
          'អ្នកមិនទាន់បានបន្ថែមសេវាកម្មណាមួយទេ។ សូមបន្ថែមមួយ ដើម្បីឱ្យអតិថិជនអាចមើល និងកក់វាបាន។',
    },
    'deleteServiceTitle': {
      AppLang.en: 'Delete this service?',
      AppLang.km: 'លុបសេវាកម្មនេះឬ?',
    },
    'serviceTitleLabel': {
      AppLang.en: 'Service title',
      AppLang.km: 'ចំណងជើងសេវាកម្ម',
    },
    'servicePriceLabel': {AppLang.en: 'Price', AppLang.km: 'តម្លៃ'},
    'serviceFeaturesLabel': {
      AppLang.en: 'What\'s included (optional)',
      AppLang.km: 'អ្វីដែលរួមបញ្ចូល (ស្រេចចិត្ត)',
    },
    'serviceFeaturesHint': {
      AppLang.en: 'One item per line, e.g.\nRefrigerant Check\nFilter Cleaning',
      AppLang.km: 'មួយបន្ទាត់ក្នុងមួយធាតុ',
    },
    'serviceTitleRequired': {
      AppLang.en: 'Enter a service title',
      AppLang.km: 'សូមបញ្ចូលចំណងជើងសេវាកម្ម',
    },
    'servicePriceInvalid': {
      AppLang.en: 'Enter a valid price',
      AppLang.km: 'សូមបញ្ចូលតម្លៃត្រឹមត្រូវ',
    },
    'jobsCompletedSuffix': {AppLang.en: 'completed', AppLang.km: 'បានបញ្ចប់'},
    'edit': {AppLang.en: 'Edit', AppLang.km: 'កែសម្រួល'},
    'changePhoto': {AppLang.en: 'Change photo', AppLang.km: 'ប្តូររូបភាព'},
    'takePhoto': {AppLang.en: 'Take photo', AppLang.km: 'ថតរូប'},
    'chooseFromGallery': {
      AppLang.en: 'Choose from gallery',
      AppLang.km: 'ជ្រើសរើសពីវិចិត្រសាល',
    },
    'removePhoto': {AppLang.en: 'Remove photo', AppLang.km: 'លុបរូបភាព'},
    'getStartedBannerTitle': {
      AppLang.en: 'Post your banner',
      AppLang.km: 'ប្រកាសផ្ទាំងផ្សាយរបស់អ្នក',
    },
    'getStartedBannerIntro': {
      AppLang.en:
          "A banner puts you in front of customers on the app's home screen. Add a photo and a short headline to stand out.",
      AppLang.km:
          'ផ្ទាំងផ្សាយជួយឱ្យអតិថិជនឃើញអ្នកនៅលើអេក្រង់ដើមកម្មវិធី។ បន្ថែមរូបថត និងចំណងជើងខ្លីៗដើម្បីលេចធ្លោ។',
    },
    'bannerImageRequired': {
      AppLang.en: 'Add a photo for your banner',
      AppLang.km: 'សូមបន្ថែមរូបថតសម្រាប់ផ្ទាំងផ្សាយ',
    },
    'bannerHeadlineLabel': {
      AppLang.en: 'Headline (optional)',
      AppLang.km: 'ចំណងជើង (ស្រេចចិត្ត)',
    },
    'bannerHeadlineHint': {
      AppLang.en: 'e.g. 20% off AC servicing this week',
      AppLang.km: 'ឧ. បញ្ចុះតម្លៃ ២០% លើសេវាម៉ាស៊ីនត្រជាក់សប្តាហ៍នេះ',
    },
    'postBanner': {AppLang.en: 'Post banner', AppLang.km: 'ប្រកាសផ្ទាំងផ្សាយ'},
    'removeBanner': {AppLang.en: 'Remove banner', AppLang.km: 'លុបផ្ទាំងផ្សាយ'},
    'getStartedBannerPromptTitle': {
      AppLang.en: 'Get started: post a banner',
      AppLang.km: 'ចាប់ផ្តើម៖ ប្រកាសផ្ទាំងផ្សាយ',
    },
    'getStartedBannerPromptBody': {
      AppLang.en: 'Get noticed by customers on the app home screen.',
      AppLang.km: 'ធ្វើឱ្យអតិថិជនកត់សម្គាល់អ្នកនៅលើអេក្រង់ដើមកម្មវិធី។',
    },
    'signOut': {AppLang.en: 'Sign out', AppLang.km: 'ចាកចេញ'},
    'email': {AppLang.en: 'Email', AppLang.km: 'អ៊ីមែល'},
    'password': {AppLang.en: 'Password', AppLang.km: 'ពាក្យសម្ងាត់'},
    'phone': {AppLang.en: 'Phone', AppLang.km: 'ទូរស័ព្ទ'},
    'phoneNumber': {AppLang.en: 'Phone number', AppLang.km: 'លេខទូរស័ព្ទ'},
    'firstName': {AppLang.en: 'First name', AppLang.km: 'នាមខ្លួន'},
    'lastName': {AppLang.en: 'Last name', AppLang.km: 'នាមត្រកូល'},
    'serviceCategory': {
      AppLang.en: 'Service category',
      AppLang.km: 'ប្រភេទសេវាកម្ម',
    },
    'serviceArea': {AppLang.en: 'Service area', AppLang.km: 'តំបន់សេវាកម្ម'},
    'languageName': {AppLang.en: 'ខ្មែរ', AppLang.km: 'English'},
    'continueBtn': {AppLang.en: 'Continue', AppLang.km: 'បន្ត'},

    // --- Language screen -------------------------------------------------
    'chooseLanguage': {
      AppLang.en: 'Choose language',
      AppLang.km: 'ជ្រើសរើសភាសា',
    },
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
    'loginTitle': {
      AppLang.en: 'Technician sign in',
      AppLang.km: 'ការចូលរបស់ជាង',
    },
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
    'createAccount': {
      AppLang.en: 'Create an account',
      AppLang.km: 'បង្កើតគណនី',
    },

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
    'phoneSignInFooter': {
      AppLang.en:
          'Secure technician verification. SMS carrier rates may apply.',
      AppLang.km:
          'ការផ្ទៀងផ្ទាត់ជាងប្រកបដោយសុវត្ថិភាព។ អត្រាតម្លៃសារ SMS អាចនឹងត្រូវអនុវត្ត។',
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
      AppLang.en:
          'Send and enter the verification code sent to your phone first',
      AppLang.km:
          'សូមផ្ញើ និងបញ្ចូលលេខកូដផ្ទៀងផ្ទាត់ដែលបានផ្ញើទៅទូរស័ព្ទរបស់អ្នកសិន',
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
    'createAccountTitle': {
      AppLang.en: 'Create account',
      AppLang.km: 'បង្កើតគណនី',
    },
    'registerIntro': {
      AppLang.en: 'An admin reviews new technicians before you can take jobs.',
      AppLang.km: 'អ្នកគ្រប់គ្រងពិនិត្យជាងថ្មីមុនពេលអ្នកអាចទទួលការងារបាន។',
    },
    'passwordMin8': {
      AppLang.en: 'Password (min 8 characters)',
      AppLang.km: 'ពាក្យសម្ងាត់ (យ៉ាងតិច ៨ តួអក្សរ)',
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
    'refresh': {AppLang.en: 'Refresh', AppLang.km: 'ផ្ទុកឡើងវិញ'},
    'tooltipProfile': {AppLang.en: 'Profile', AppLang.km: 'ប្រវត្តិរូប'},
    'tooltipNotifications': {
      AppLang.en: 'Notifications',
      AppLang.km: 'ការជូនដំណឹង',
    },
    'onlineSharingLocation': {
      AppLang.en: "You're online — sharing your location",
      AppLang.km: 'អ្នកកំពុងអនឡាញ — កំពុងចែករំលែកទីតាំងរបស់អ្នក',
    },
    'offline': {
      AppLang.en: "You're offline",
      AppLang.km: 'អ្នកកំពុងក្រៅបណ្តាញ',
    },
    'noActiveJobs': {
      AppLang.en: 'No active jobs right now.',
      AppLang.km: 'មិនមានការងារកំពុងដំណើរការទេឥឡូវនេះ។',
    },
    'noPastJobs': {
      AppLang.en: 'No past jobs yet.',
      AppLang.km: 'មិនទាន់មានការងារពីមុនទេ។',
    },
    'noActiveJobsSubtitle': {
      AppLang.en:
          'New incoming requests in your service area will appear here.',
      AppLang.km: 'សំណើថ្មីៗនៅក្នុងតំបន់សេវាកម្មរបស់អ្នកនឹងបង្ហាញនៅទីនេះ។',
    },
    'technicianActivity': {
      AppLang.en: 'Technician Activity',
      AppLang.km: 'សកម្មភាពជាង',
    },
    'viewDispatch': {AppLang.en: 'View dispatch', AppLang.km: 'មើលការចាត់តាំង'},
    'approvedTechnicianBadge': {
      AppLang.en: 'Approved Technician',
      AppLang.km: 'ជាងដែលបានអនុម័ត',
    },

    // --- Job detail -------------------------------------------------------
    'job': {AppLang.en: 'Job', AppLang.km: 'ការងារ'},
    'jobHash': {AppLang.en: 'Job #', AppLang.km: 'ការងារ #'},
    'declineJobQ': {
      AppLang.en: 'Decline this job?',
      AppLang.km: 'បដិសេធការងារនេះ?',
    },
    'declineJobBody': {
      AppLang.en: 'It will go back to the dispatcher to reassign.',
      AppLang.km: 'វានឹងត្រឡប់ទៅអ្នកចាត់ចែងវិញដើម្បីចាត់តាំងឡើងវិញ។',
    },
    'decline': {AppLang.en: 'Decline', AppLang.km: 'បដិសេធ'},
    'customer': {AppLang.en: 'Customer', AppLang.km: 'អតិថិជន'},
    'address': {AppLang.en: 'Address', AppLang.km: 'អាសយដ្ឋាន'},
    'description': {AppLang.en: 'Description', AppLang.km: 'ការពិពណ៌នា'},
    'onMyWay': {AppLang.en: 'Accept', AppLang.km: 'ទទួលយក'},
    'iveArrived': {AppLang.en: "I've arrived", AppLang.km: 'ខ្ញុំបានមកដល់'},
    'startJob': {AppLang.en: 'Start job', AppLang.km: 'ចាប់ផ្តើមការងារ'},
    'sendQuote': {AppLang.en: 'Send quote', AppLang.km: 'ផ្ញើសម្រង់ថ្លៃ'},
    'sendRevisedQuote': {
      AppLang.en: 'Send revised quote',
      AppLang.km: 'ផ្ញើសម្រង់ថ្លៃថ្មី',
    },
    'quoteFormTitle': {
      AppLang.en: 'Repair quote',
      AppLang.km: 'សម្រង់ថ្លៃជួសជុល',
    },
    'quoteFormIntro': {
      AppLang.en:
          'Break down the cost — the customer sees exactly this before they accept.',
      AppLang.km: 'បំបែកតម្លៃ — អតិថិជននឹងឃើញព័ត៌មាននេះពិតប្រាកដមុននឹងទទួលយក។',
    },
    'quoteFormInspection': {
      AppLang.en: 'Inspection fee',
      AppLang.km: 'ថ្លៃត្រួតពិនិត្យ',
    },
    'quoteFormLabor': {AppLang.en: 'Labor cost', AppLang.km: 'ថ្លៃការងារ'},
    'quoteFormParts': {
      AppLang.en: 'Parts cost',
      AppLang.km: 'ថ្លៃគ្រឿងបន្លាស់',
    },
    'quoteFormTravel': {AppLang.en: 'Travel fee', AppLang.km: 'ថ្លៃធ្វើដំណើរ'},
    'quoteSelfDropNote': {
      AppLang.en:
          'Self Drop: no travel fee. The inspection fee is the diagnostic fee the customer was shown when booking.',
      AppLang.km:
          'យកមកដាក់ខ្លួនឯង៖ គ្មានថ្លៃធ្វើដំណើរ។ ថ្លៃត្រួតពិនិត្យ គឺជាថ្លៃពិនិត្យដែលអតិថិជនបានឃើញពេលកក់។',
    },
    'seen': {AppLang.en: 'Seen', AppLang.km: 'បានឃើញ'},
    'quoteItemsTitle': {AppLang.en: 'Line items', AppLang.km: 'មុខការងារ'},
    'quoteItemsHint': {
      AppLang.en:
          'Add each job separately - the customer ticks which ones to do.',
      AppLang.km:
          'បន្ថែមការងារនីមួយៗដាច់ដោយឡែក - អតិថិជនធីកជ្រើសការងារដែលចង់ធ្វើ។',
    },
    'quoteItemTitle': {AppLang.en: 'Item', AppLang.km: 'មុខការងារ'},
    'quoteItemNote': {
      AppLang.en: 'Details (optional)',
      AppLang.km: 'ព័ត៌មានលម្អិត (មិនចាំបាច់)'
    },
    'quoteItemRecommended': {
      AppLang.en: 'Recommended extra',
      AppLang.km: 'ការងារបន្ថែមដែលណែនាំ'
    },
    'quoteItemRecommendedHint': {
      AppLang.en: 'Not required - left unticked for the customer by default',
      AppLang.km: 'មិនចាំបាច់ - មិនធីកតាមលំនាំដើមសម្រាប់អតិថិជន',
    },
    'quoteAddItem': {AppLang.en: 'Add item', AppLang.km: 'បន្ថែមមុខការងារ'},
    'quoteItemInvalid': {
      AppLang.en: 'Every item needs a name and a price of 0 or more.',
      AppLang.km: 'មុខការងារនីមួយៗត្រូវមានឈ្មោះ និងតម្លៃចាប់ពី 0 ឡើង។',
    },
    'approvedWorkTitle': {
      AppLang.en: 'Work approved by the customer',
      AppLang.km: 'ការងារដែលអតិថិជនបានយល់ព្រម',
    },
    'addPhoto': {AppLang.en: 'Photo', AppLang.km: 'រូបថត'},
    'chat': {AppLang.en: 'Chat', AppLang.km: 'ជជែក'},
    'messageCustomer': {
      AppLang.en: 'Message the customer',
      AppLang.km: 'ផ្ញើសារទៅអតិថិជន'
    },
    'chatEmptyTech': {
      AppLang.en:
          'No messages yet. Send the customer an update about this job.',
      AppLang.km: 'មិនទាន់មានសារទេ។ ផ្ញើព័ត៌មានថ្មីអំពីការងារនេះទៅអតិថិជន។',
    },
    'typeMessage': {AppLang.en: 'Type a message', AppLang.km: 'វាយសារ'},
    'selfDropJob': {AppLang.en: 'Self Drop', AppLang.km: 'យកមកដាក់ខ្លួនឯង'},
    'selfDropJobBody': {
      AppLang.en: 'The customer brings the item to your shop.',
      AppLang.km: 'អតិថិជននឹងយករបស់មកហាងរបស់អ្នក។',
    },
    'expectedArrival': {
      AppLang.en: 'Expected arrival',
      AppLang.km: 'ពេលមកដល់ដែលរំពឹងទុក',
    },
    'diagnosticFee': {AppLang.en: 'Diagnostic fee', AppLang.km: 'ថ្លៃពិនិត្យ'},
    'itemReceived': {AppLang.en: 'Item received', AppLang.km: 'បានទទួលរបស់'},
    'statusAwaitingDropOff': {
      AppLang.en: 'Awaiting drop-off',
      AppLang.km: 'រង់ចាំការយកមកដាក់',
    },
    'statusItemReceived': {
      AppLang.en: 'Item received',
      AppLang.km: 'បានទទួលរបស់',
    },
    'quoteFormReason': {
      AppLang.en: 'What did you find? (optional)',
      AppLang.km: 'អ្នករកឃើញអ្វី? (មិនចាំបាច់)',
    },
    'quoteFormReasonHint': {
      AppLang.en: 'e.g. compressor damaged, needs a new part',
      AppLang.km: 'ឧ. ម៉ាស៊ីនខូច ត្រូវការគ្រឿងបន្លាស់ថ្មី',
    },
    'quoteFormTotal': {AppLang.en: 'Total', AppLang.km: 'សរុប'},
    'quoteFormSubmit': {
      AppLang.en: 'Send to customer',
      AppLang.km: 'ផ្ញើទៅអតិថិជន',
    },
    'quoteSentSuccess': {
      AppLang.en: 'Quote sent',
      AppLang.km: 'សម្រង់ថ្លៃត្រូវបានផ្ញើ',
    },
    'waitingForCustomerDecision': {
      AppLang.en: 'Waiting for the customer to accept or decline your quote.',
      AppLang.km: 'កំពុងរង់ចាំអតិថិជនទទួលយក ឬបដិសេធសម្រង់ថ្លៃរបស់អ្នក។',
    },
    'quoteWasDeclinedInfo': {
      AppLang.en:
          'The customer declined your last quote. Send a revised one, or decline the job.',
      AppLang.km:
          'អតិថិជនបានបដិសេធសម្រង់ថ្លៃចុងក្រោយរបស់អ្នក។ សូមផ្ញើសម្រង់ថ្លៃថ្មី ឬបដិសេធការងារនេះ។',
    },
    'markComplete': {
      AppLang.en: 'Mark complete',
      AppLang.km: 'សម្គាល់ថាបានបញ្ចប់',
    },
    'noActionsForJob': {
      AppLang.en: 'No actions available for this job',
      AppLang.km: 'មិនមានសកម្មភាពសម្រាប់ការងារនេះទេ',
    },
    'couldNotOpen': {
      AppLang.en: 'Could not open',
      AppLang.km: 'មិនអាចបើកបានទេ',
    },

    // --- Profile --------------------------------------------------------------
    'myProfile': {AppLang.en: 'My profile', AppLang.km: 'ប្រវត្តិរូបរបស់ខ្ញុំ'},
    'name': {AppLang.en: 'Name', AppLang.km: 'ឈ្មោះ'},
    'category': {AppLang.en: 'Category', AppLang.km: 'ប្រភេទ'},
    'about': {AppLang.en: 'About', AppLang.km: 'អំពី'},
    'openingHours': {AppLang.en: 'Opening hours', AppLang.km: 'ម៉ោងបើក'},
    'hoursEveryday8to6': {
      AppLang.en: 'Everyday, 8:00 AM – 6:00 PM',
      AppLang.km: 'រាល់ថ្ងៃ ៨:០០ព្រឹក – ៦:០០ល្ងាច',
    },
    'hoursEveryday24': {
      AppLang.en: 'Everyday, 24 Hours',
      AppLang.km: 'រាល់ថ្ងៃ ២៤ម៉ោង',
    },
    'hoursMonFri8to6': {
      AppLang.en: 'Monday – Friday, 8:00 AM – 6:00 PM',
      AppLang.km: 'ចន្ទ – សុក្រ ៨:០០ព្រឹក – ៦:០០ល្ងាច',
    },
    'hoursMonSat8to6': {
      AppLang.en: 'Monday – Saturday, 8:00 AM – 6:00 PM',
      AppLang.km: 'ចន្ទ – សៅរ៍ ៨:០០ព្រឹក – ៦:០០ល្ងាច',
    },
    'hoursMonSat6to11': {
      AppLang.en: 'Monday – Saturday, 6:00 AM – 11:00 PM',
      AppLang.km: 'ចន្ទ – សៅរ៍ ៦:០០ព្រឹក – ១១:០០យប់',
    },
    'hoursMonSun7to9': {
      AppLang.en: 'Monday – Sunday, 7:00 AM – 9:00 PM',
      AppLang.km: 'ចន្ទ – អាទិត្យ ៧:០០ព្រឹក – ៩:០០យប់',
    },
    'hoursCustom': {AppLang.en: 'Custom…', AppLang.km: 'កំណត់ដោយខ្លួនឯង…'},
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
    'pickOnMap': {AppLang.en: 'Pick on map', AppLang.km: 'ជ្រើសរើសលើផែនទី'},

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
    'statusONTHEWAY': {
      AppLang.en: 'On the way',
      AppLang.km: 'កំពុងធ្វើដំណើរមក',
    },
    'statusARRIVED': {AppLang.en: 'Arrived', AppLang.km: 'បានមកដល់'},
    'statusQUOTEPENDING': {
      AppLang.en: 'Quote sent',
      AppLang.km: 'បានផ្ញើសម្រង់ថ្លៃ',
    },
    'statusINPROGRESS': {
      AppLang.en: 'In progress',
      AppLang.km: 'កំពុងដំណើរការ',
    },
    'statusCOMPLETED': {AppLang.en: 'Completed', AppLang.km: 'បានបញ្ចប់'},
    'statusREQUESTED': {AppLang.en: 'Requested', AppLang.km: 'បានស្នើសុំ'},
    'statusCANCELLED': {AppLang.en: 'Cancelled', AppLang.km: 'បានលុបចោល'},

    // --- Approval / account status (Profile "Status" row) ---------------
    'apPENDING': {AppLang.en: 'Pending', AppLang.km: 'កំពុងរង់ចាំ'},
    'apAPPROVED': {AppLang.en: 'Approved', AppLang.km: 'បានអនុម័ត'},
    'apREJECTED': {AppLang.en: 'Rejected', AppLang.km: 'បានបដិសេធ'},
    'acACTIVE': {AppLang.en: 'Active', AppLang.km: 'សកម្ម'},
    'acSUSPENDED': {AppLang.en: 'Suspended', AppLang.km: 'ត្រូវបានផ្អាក'},
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
