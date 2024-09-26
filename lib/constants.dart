class Constants {
  static const int FIX_SETTLE_TIMEOUT_SECONDS = 3;

  static const int HIT_TEST_INTERVAL = 27;

  static const int    CROSS_SIZE  = 6;
  static const double MARKER_SIZE = 6.0;

  static const String defaultTitle = "Course Walk Companion";
  static const String freeAppTitle = "CWC - Free";
  static const String paidAppTitle = "CWC - Paid";
  static const String appTitleStem = "Course";

  static const String UPLOAD_WALK_COUNTRY_KEY = "upload_country_name";
  static const String UPLOAD_WALK_NAME_KEY    = "upload_walk_name";
  static const String UPLOAD_WALK_USER_KEY    = "upload_walk_user";
  static const String UPLOAD_WALK_EMAIL_KEY   = "upload_walk_email";
  static const String UPLOAD_WALK_CLASS_KEY   = "upload_walk_class";
  static const String DEVICE_UUID             = "device_uuid";

  static const String WALK_UPLOAD_URL  = "http://wamm.me.uk/cwc/walk_upload.php";
  static const String IMAGE_UPLOAD_URL = "http://wamm.me.uk/cwc/image_upload.php";

  static const String WALK_WINDOW_TITLE         = "Select a walk";
  static const String PHOTO_WINDOW_TITLE        = "Take a picture";
  static const String PHOTO_PREVIEW_TITLE       = "Preview";
  static const String RENAME_DIALOG_TITLE       = "Rename";
  static const String ERROR_DIALOG_TITLE        = "ERROR";
  static const String INFORMATION_DIALOG_TITLE  = "Information";
  static const String OPTIMUM_TIME_DIALOG_TITLE = "Optimum Time";
  static const String UPLOAD_WALK_DIALOG_TITLE  = "Upload Walk";
  static const String GPS_STATUS_DIALOG_TITLE   = "GPS Status";

  static const String PROMPT_AWAIT_GPS            = "Await GPS";
  static const String PROMPT_START_TRACKING       = "Start";
  static const String PROMPT_STOP_TRACKING        = "Stop";
  static const String PROMPT_PAUSE                = "Pause";
  static const String PROMPT_RESUME               = "Resume";
  static const String PROMPT_CAMERA               = "Camera";
  static const String PROMPT_LOAD                 = "Load";
  static const String PROMPT_RENAME               = "Rename";
  static const String PROMPT_DELETE               = "Delete";
  static const String PROMPT_NAME                 = "Name";
  static const String PROMPT_OK                   = "OK";
  static const String PROMPT_CANCEL               = "Cancel";
  static const String PROMPT_YES                  = "Yes";
  static const String PROMPT_NO                   = "No";
  static const String PROMPT_OPTIMUM_TIME         = "Optimum time";
  static const String PROMPT_SET                  = "Set";
  static const String PROMPT_OPTIMUM_TIME_MINUTES = "Minutes";
  static const String PROMPT_OPTIMUM_TIME_SECONDS = "Seconds";
  static const String PROMPT_UPLOAD_WALK_USER     = "Uploaded by";
  static const String PROMPT_UPLOAD_WALK_EMAIL    = "Email";
  static const String PROMPT_UPLOAD_WALK_COUNTRY  = "Country";
  static const String PROMPT_UPLOAD_WALK_NAME     = "Course name";
  static const String PROMPT_UPLOAD_WALK_CLASS    = "Class";
  static const String PROMPT_UPLOAD               = "Upload";

  static const String PROMPT_DELETE_WALK    = "Are you sure you want to delete this walk?";

  static const String PROMPT_LATITUDE  = "Latitude";
  static const String PROMPT_LONGITUDE = "Longitude";

  static const String MENU_PROMPT_DEBUG_WALKS   = "Debug Walks";
  static const String MENU_PROMPT_DEBUG         = "Debug";
  static const String MENU_PROMPT_GPS_STATUS    = "GPS Status";
  static const String MENU_PROMPT_CLEAR_DISPLAY = "Clear Display";
  static const String MENU_PROMPT_OPTIMUM_TIME  = "Optimum Time";
  static const String MENU_PROMPT_GALLERY       = "Gallery";
  static const String MENU_PROMPT_WALKS         = "Walks";
  static const String MENU_PROMPT_MAPS          = "Maps";
  static const String MENU_PROMPT_UPLOAD        = "Upload walk";
  static const String MENU_PROMPT_LOGIN         = "Login";
  static const String MENU_PROMPT_LOGOUT        = "Logout";

  static const Set<String> MENU_CHOICES = { MENU_PROMPT_DEBUG_WALKS,
                                            MENU_PROMPT_DEBUG,
                                            MENU_PROMPT_CLEAR_DISPLAY,
                                            MENU_PROMPT_GALLERY,
                                            MENU_PROMPT_WALKS,
                                            MENU_PROMPT_MAPS,
                                            MENU_PROMPT_UPLOAD,
                                            MENU_PROMPT_LOGIN };

  // static const int DEBUG_WALKS_SELECTED   = 0;
  // static const int DEBUG_SELECTED         = 1;
  // static const int CLEAR_DISPLAY_SELECTED = 2;
  // static const int OPTIMUM_TIME_SELECTED  = 3;
  // static const int GALLERY_SELECTED       = 4;
  // static const int WALKS_SELECTED         = 5;
  // static const int MAPS_SELECTED          = 6;

  static const String STATE_STARTUP_AWAIT_PERMISSIONS     = "startup_await_permissions";
  static const String STATE_STARTUP_AWAIT_VALID_FIX       = "startup_await_valid_fix";
  static const String STATE_STARTUP_AWAIT_FIX_SETTLE      = "startup_await_fix_settle";
  static const String STATE_IDLE                          = "idle";
  static const String STATE_WALK_LOADED_AWAIT_VALID_FIX   = "walk_loaded_await_valid_fix";
  static const String STATE_WALK_LOADED_AWAIT_FIX_SETTLE  = "walk_loaded_await_fix_settle";
  static const String STATE_WALK_LOADED                   = "walk_loaded";
  static const String STATE_TRACKING                      = "tracking";
  static const String STATE_TRACKING_PAUSED               = "paused";
  static const String STATE_AWAIT_TRACKING_STOP_TIMEOUT   = "await_stop";
  static const String STATE_NEW_WALK_LOADING              = "new_walk_loading";
  static const String STATE_WALK_LOADING                  = "walk_loading";
  static const String STATE_WALK_LOADING_AWAIT_VALID_FIX  = "walk_loading_await_valid_fix";
  static const String STATE_WALK_LOADING_AWAIT_FIX_SETTLE = "walk_loading_await_fix_settle";
  static const String STATE_WALK_LOADED_AWAIT_PERMISSIONS = "walk_loaded_await_permissions";
  static const String STATE_IDLE_AWAIT_PERMISSIONS        = "idle_await_permissions";
  

  static const String EVENT_STARTUP = "startup";

  static const String EVENT_GPS_GRANTED            = "gps_granted";
  static const String EVENT_GPS_DENIED             = "gps_denied";
  static const String EVENT_GPS_PERMANENTLY_DENIED = "gps_permanently_denied";

  static const String EVENT_FIX_SETTLE_TIMEOUT       = "gps_fix_settle_timeout";
  static const String EVENT_GPS_FIX                  = "gps_fix";
  static const String EVENT_GPS_COORDS               = "gps_coords";

  static const String EVENT_START_TRACKING           = "start_tracking";
  static const String EVENT_PAUSE_TRACKING           = "pause_tracking";
  static const String EVENT_RESUME_TRACKING          = "resume_tracking";
  static const String EVENT_STOP_TRACKING_PRESSED    = "stop_tracking_pressed";
  static const String EVENT_STOP_TRACKING_RELEASED   = "stop_tracking_released";
  static const String EVENT_STOP_TRACKING_TIMEOUT    = "stop_tracking_timeout";
  static const String EVENT_SHOW_CAMERA              = "camera";
  static const String EVENT_PHOTO_TAKEN              = "photo_taken";

  static const String EVENT_DEBUG                    = "debug";
  static const String EVENT_CREATE_DEBUG_WALKS       = "debug_walks";
  static const String EVENT_SHOW_GPS_STATUS_DIALOG   = "show_gps_status";
  static const String EVENT_CLEAR_DISPLAY            = "clear_display";
  static const String EVENT_SHOW_OPTIMUM_TIME_DIALOG = "show_optimum_time";
  static const String EVENT_SET_OPTIMUM_TIME         = "set_optimum_time";
  static const String EVENT_SHOW_GALLERY             = "show_gallery";
  static const String EVENT_DISPLAY_WALKS            = "walks";
  static const String EVENT_LOAD_WALK                = "load_walk";
  static const String EVENT_TOGGLE_MAPS              = "toggle_maps";
  static const String EVENT_SHOW_UPLOAD_WALK_DIALOG  = "show_upload_walk";
  static const String EVENT_UPLOAD_WALK              = "upload_walk";

  static const String EVENT_WALK_LOADED              = "walk_loaded";

  static const String EVENT_SWITCH_TO_BACKGROUND     = "background";
  static const String EVENT_SWITCH_TO_FOREGROUND     = "foreground";

  static const String EVENT_LOCATION_GRANTED         = "location_granted";
  static const String EVENT_LOCATION_NOT_YET_GRANTED = "location_denied";
  static const String EVENT_LOCATION_DENIED          = "location_problems";

  static const String EVENT_LOGIN  = "login";
  static const String EVENT_LOGOUT = "logout";

  static const String ERR_WALK_NAME_INVALID            = "Walk name must not be blank or empty.";
  static const String ERR_OPTIMUM_TIME_INVALID         = "Both minutes and seconds must be entered.";
  static const String ERR_OPTIMUM_TIME_MINUTES_INVALID = "The minute value cannot be negative.";
  static const String ERR_OPTIMUM_TIME_SECONDS_INVALID = "The seconds value must be between 0 and 59.";

  static const String ERR_USERNAME_AND_PASSWORD_MUST_BE_SPECIFIED = "The username and password must be specified";

  static const String ERR_WALK_NAME_AND_USER_MUST_BE_SET = "The course name and the user must be specified.";
  static const String ERR_CANT_UPLOAD_WALK               = "The course walk cannot be uploaded - please report to admin@wamm.me.uk.";
  static const String ERR_NO_CONNECTIVITY                = "The course walk cannot be uploaded as there is no internet connectivity. Please try again later.";

  static const String INFO_WALK_UPLOADED_OK = "The walk was uploaded successfully.";

  static const String REQUEST_LOCATION_PERMISSIONS_BEFORE_GRANTED_TITLE = 'Location Permissions';
  static const String REQUEST_LOCATION_PERMISSIONS_AFTER_GRANTED_TITLE  = 'Location Permissions Removed';
  static const String REQUEST_LOCATION_PERMISSIONS_WHEN_TRACKING_TITLE  = 'Tracking Stopped';
  static const String REQUEST_LOCATION_PERMISSIONS_TEXT =
      'In order for this application to function, it requires '
      'location tracking to be enabled, precise accuracy to be '
      'turned on, and access to all location functions. '
      'Press the SETTINGS button to open the settings window '
      'then enable all these features to continue.';
}
