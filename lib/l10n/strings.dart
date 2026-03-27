// ═══════════════════════════════════════════════════════════════════
// Athar (أثر) — lib/l10n/strings.dart
// Complete localization table — EN + AR
// All keys from all 5 screens + widgets
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';

class S {
  static const Map<String, Map<String, String>> _strings = {
    // ══════════════════════════════════════════════════════════════════
    // ENGLISH
    // ══════════════════════════════════════════════════════════════════
    'en': {
      // ── App-wide ──────────────────────────────────────────────────
      'app_name': 'Athar',
      'app_tagline': 'Focus. Log. Leave a Mark.',

      // ── Bottom navigation ─────────────────────────────────────────
      'focus': 'Focus',
      'logs': 'Logs',
      'stats': 'Stats',
      'settings': 'Settings',

      // ── Shared / generic ──────────────────────────────────────────
      'done': 'Done',
      'btn_done': 'Done', // alias used by settings_screen
      'ok': 'OK',
      'close': 'Close',
      'saving': 'Saving…',
      'unit_minutes': 'min',
      'unit_hours': 'hrs',

      // ── Buttons ───────────────────────────────────────────────────
      'btn_start': 'Start',
      'btn_pause': 'Pause',
      'btn_resume': 'Resume',
      'btn_reset': 'Reset',
      'btn_save': 'Save',
      'btn_cancel': 'Cancel',
      'btn_discard': 'Discard',
      'btn_log_session': 'Log This Session',
      'btn_undo': 'Undo',
      'btn_delete': 'Delete',

      // ════════════════════════════════════════════════════════════════
      // FOCUS SCREEN
      // ════════════════════════════════════════════════════════════════
      'focus_title': 'Focus',
      'focus_idle_hint': 'Ready when you are',
      'focus_running_hint': 'Stay in the zone',
      'focus_paused_hint': 'Session paused',
      'focus_completed_title': 'Session Complete!',
      'focus_completed_hint': 'Great work. Log what you accomplished.',

      // ════════════════════════════════════════════════════════════════
      // INPUT SCREEN
      // ════════════════════════════════════════════════════════════════
      'input_title': 'Log Your Session',
      'input_task_label': 'Session Note',
      'input_task_hint': 'What did you accomplish?',
      'input_hint': 'What did you accomplish this session?',
      'input_tags_label': 'Quick Tags',
      'input_star_label': 'Star this session',
      'input_star_hint': 'Starred sessions appear in the bookmarks filter',
      'discard_title': 'Discard Note?',
      'discard_body': 'Your note will be permanently lost.',
      'discard_confirm': 'Discard',
      'input_discard_title': 'Discard Note?',
      'input_discard_body': 'Your note will be permanently lost.',
      'input_task_placeholder': 'e.g. Finished the auth module, read ch. 3…',
      'input_empty_warning': 'Please write at least a short note.',
      'input_header_cta': 'What did you accomplish this session?',
      'input_prompts_label': 'QUICK FILL',

      // ════════════════════════════════════════════════════════════════
      // LOG SCREEN
      // ════════════════════════════════════════════════════════════════
      'logs_title': 'Session Logs',
      'log_title': 'Session Logs',
      'log_empty_title': 'No sessions yet',
      'log_empty_subtitle': 'Complete a focus session to see your log here.',
      'log_empty_filter_title': 'No results found',
      'log_empty_filter_sub': 'Try adjusting your search or filter.',
      'log_delete_tooltip': 'Delete this entry',
      'log_delete_confirm': 'Delete this log entry?',
      'log_delete_yes': 'Delete',
      'log_delete_no': 'Keep',
      'log_duration_label': '{n} min',
      'log_stat_sessions': 'Sessions',
      'log_stat_focused': 'Focus Time',
      'log_stat_starred': 'Starred',
      'log_search_hint': 'Search sessions…',
      'log_filter_starred': 'Starred only',
      'log_deleted_snack': 'Session deleted',
      'log_undo': 'Undo',
      'filter_all': 'All',
      'filter_starred': 'Starred',
      'filter_this_week': 'This Week',

      // ════════════════════════════════════════════════════════════════
      // STATS SCREEN
      // ════════════════════════════════════════════════════════════════
      'stats_title': 'Stats',
      'stats_no_data': 'Complete focus sessions to see your stats here.',
      'stats_total_hours': 'Focus Hours',
      'stats_sessions': 'Sessions',
      'stats_avg_session': 'Avg Session',
      'stats_minutes_unit': 'min',
      'stats_hours_unit': 'hrs',
      'stats_today_label': 'Today',
      'stats_last_7_days': 'Last 7 Days',
      'stats_period_week': 'Week',
      'stats_period_month': 'Month',
      'stats_period_all': 'All',
      'stats_time_of_day': 'Focus Time of Day',
      'stats_records': 'Personal Records',
      'stats_best_day': 'Best Day of Week',
      'stats_all_time': 'All-Time Totals',
      'stats_legend_today': 'Today',
      'stats_legend_peak': 'Peak',
      'stats_legend_other': 'Other',
      // ✅ ADDED: previously missing keys
      'stats_weekly_chart': '7-Day Chart',
      'stats_heatmap': '28-Day Activity',
      'stats_best_session': 'Best Session',

      // ── Hero stat cards (stat_* prefix) ───────────────────────────
      'stat_sessions': 'Sessions',
      'stat_hours': 'Hours',
      'stat_starred': 'Starred',

      // ── Day abbreviations ─────────────────────────────────────────
      'day_mon': 'Mon',
      'day_tue': 'Tue',
      'day_wed': 'Wed',
      'day_thu': 'Thu',
      'day_fri': 'Fri',
      'day_sat': 'Sat',
      'day_sun': 'Sun',

      // ════════════════════════════════════════════════════════════════
      // SETTINGS SCREEN
      // ════════════════════════════════════════════════════════════════
      'settings_title': 'Settings',
      'settings_tagline': 'Focus. Log. Leave a Mark.',

      // ── Section headers ───────────────────────────────────────────
      'settings_section_focus': 'Focus',
      'settings_section_appearance': 'Appearance',
      'settings_section_notifications': 'Notifications',
      'settings_section_data': 'Data',
      'settings_section_about': 'About',

      // ── Appearance ────────────────────────────────────────────────
      'settings_preferences': 'Preferences',
      'settings_language': 'Language',
      'settings_language_en': 'English',
      'settings_language_ar': 'Arabic',
      'settings_theme': 'Theme',
      'settings_theme_system': 'System',
      'settings_theme_light': 'Light',
      'settings_theme_dark': 'Dark',
      'theme_system': 'System',
      'theme_light': 'Light',
      'theme_dark': 'Dark',

      // ── Focus duration ────────────────────────────────────────────
      'settings_focus_duration': 'Focus Duration',
      'settings_duration': 'Focus Duration',
      'settings_duration_hint': 'Applied to new sessions only',
      'settings_duration_picker_title': 'Focus Duration',
      'settings_duration_locked': 'Timer is running — stop to change',

      // ── Notifications ─────────────────────────────────────────────
      'settings_notifications': 'Notifications',
      'settings_notif_session_end': 'Session End Alert',
      'settings_notif_session_end_hint':
          'Notify when a focus session completes',
      'settings_notif_reminder': 'Daily Reminder',
      'settings_notif_reminder_hint':
          'Get a daily nudge to start a focus session',
      'settings_notif_vibrate': 'Vibrate on Complete',
      'settings_notify_complete': 'Session Complete Alert',
      'settings_notify_complete_sub': 'Notify when a focus session completes',
      'settings_daily_reminder': 'Daily Reminder',
      'settings_daily_reminder_sub':
          'Get a daily nudge to start a focus session',
      'settings_vibrate': 'Vibrate on Complete',
      'settings_vibrate_sub': 'Feel a haptic pulse when your session ends',

      // ── Data section ──────────────────────────────────────────────
      'settings_data': 'Data',
      'settings_export': 'Export Sessions',
      'settings_export_hint': 'Export your focus logs as a CSV file',
      'settings_export_soon': 'Export coming soon!',
      'settings_clear_all': 'Clear All Sessions',
      'settings_clear_all_hint': 'Permanently delete all focus logs',
      'settings_your_data': 'Your Data',
      'settings_clear_data': 'Clear All Data',
      'settings_clear_data_sub': 'Permanently delete all focus logs',
      'settings_clear_data_btn': 'Clear',
      'settings_clear_title': 'Clear All Sessions?',
      'settings_clear_body': 'All your sessions will be permanently deleted. '
          'This action cannot be undone.',
      'settings_clear_confirm': 'Clear All',
      'settings_clear_yes': 'Clear All',
      'settings_cleared_snack': 'All sessions cleared',

      // ── About ─────────────────────────────────────────────────────
      'settings_open_source': 'Open Source',
      'settings_about': 'About',
      'settings_version': 'Version',
      'settings_about_text': 'Athar helps you focus deeply and journal '
          'your progress — fully offline.',
    },

    // ══════════════════════════════════════════════════════════════════
    // ARABIC — Modern Standard Arabic, productivity register
    // ══════════════════════════════════════════════════════════════════
    'ar': {
      // ── App-wide ──────────────────────────────────────────────────
      'app_name': 'أثر',
      'app_tagline': 'ركّز. سجّل. اترك أثراً.',

      // ── Bottom navigation ─────────────────────────────────────────
      'focus': 'تركيز',
      'logs': 'السجلات',
      'stats': 'الإحصاء',
      'settings': 'الإعدادات',

      // ── Shared / generic ──────────────────────────────────────────
      'done': 'تم',
      'btn_done': 'تم',
      'ok': 'حسناً',
      'close': 'إغلاق',
      'saving': 'جارٍ الحفظ…',
      'unit_minutes': 'دقيقة',
      'unit_hours': 'ساعة',

      // ── Buttons ───────────────────────────────────────────────────
      'btn_start': 'ابدأ',
      'btn_pause': 'توقف',
      'btn_resume': 'استمر',
      'btn_reset': 'إعادة',
      'btn_save': 'حفظ',
      'btn_cancel': 'إلغاء',
      'btn_discard': 'تجاهل',
      'btn_log_session': 'سجّل هذه الجلسة',
      'btn_undo': 'تراجع',
      'btn_delete': 'حذف',

      // ════════════════════════════════════════════════════════════════
      // FOCUS SCREEN
      // ════════════════════════════════════════════════════════════════
      'focus_title': 'تركيز',
      'focus_idle_hint': 'جاهز حين تكون أنت جاهزاً',
      'focus_running_hint': 'ابقَ في المنطقة',
      'focus_paused_hint': 'الجلسة متوقفة مؤقتاً',
      'focus_completed_title': 'انتهت الجلسة!',
      'focus_completed_hint': 'عمل رائع. سجّل ما أنجزته.',

      // ════════════════════════════════════════════════════════════════
      // INPUT SCREEN
      // ════════════════════════════════════════════════════════════════
      'input_title': 'سجّل جلستك',
      'input_task_label': 'ملاحظة الجلسة',
      'input_task_hint': 'ماذا أنجزت؟',
      'input_hint': 'ماذا أنجزت في هذه الجلسة؟',
      'input_tags_label': 'تصنيفات سريعة',
      'input_star_label': 'تمييز هذه الجلسة',
      'input_star_hint': 'تظهر الجلسات المميزة في مرشح الإشارات المرجعية',
      'discard_title': 'تجاهل الملاحظة؟',
      'discard_body': 'ستُفقد ملاحظتك بشكل نهائي.',
      'discard_confirm': 'تجاهل',
      'input_discard_title': 'تجاهل الملاحظة؟',
      'input_discard_body': 'ستُفقد ملاحظتك بشكل نهائي.',
      'input_task_placeholder': 'مثال: أنهيت وحدة المصادقة، قرأت الفصل الثالث…',
      'input_empty_warning': 'الرجاء كتابة ملاحظة قصيرة على الأقل.',
      'input_header_cta': 'ما الذي أنجزته خلال هذه الجلسة؟',
      'input_prompts_label': 'تعبئة سريعة',

      // ════════════════════════════════════════════════════════════════
      // LOG SCREEN
      // ════════════════════════════════════════════════════════════════
      'logs_title': 'سجل الجلسات',
      'log_title': 'سجل الجلسات',
      'log_empty_title': 'لا توجد جلسات بعد',
      'log_empty_subtitle': 'أكمل جلسة تركيز لترى سجلك هنا.',
      'log_empty_filter_title': 'لا توجد نتائج',
      'log_empty_filter_sub': 'جرّب تعديل البحث أو المرشح.',
      'log_delete_tooltip': 'حذف هذا الإدخال',
      'log_delete_confirm': 'هل تريد حذف هذا الإدخال؟',
      'log_delete_yes': 'حذف',
      'log_delete_no': 'إبقاء',
      'log_duration_label': '{n} دقيقة',
      'log_stat_sessions': 'الجلسات',
      'log_stat_focused': 'وقت التركيز',
      'log_stat_starred': 'المميزة',
      'log_search_hint': 'ابحث في الجلسات…',
      'log_filter_starred': 'المميزة فقط',
      'log_deleted_snack': 'تم حذف الجلسة',
      'log_undo': 'تراجع',
      'filter_all': 'الكل',
      'filter_starred': 'المميزة',
      'filter_this_week': 'هذا الأسبوع',

      // ════════════════════════════════════════════════════════════════
      // STATS SCREEN
      // ════════════════════════════════════════════════════════════════
      'stats_title': 'الإحصاء',
      'stats_no_data': 'أكمل جلسات تركيز لترى إحصاءاتك هنا.',
      'stats_total_hours': 'ساعات التركيز',
      'stats_sessions': 'الجلسات',
      'stats_avg_session': 'متوسط الجلسة',
      'stats_minutes_unit': 'دقيقة',
      'stats_hours_unit': 'ساعة',
      'stats_today_label': 'اليوم',
      'stats_last_7_days': 'آخر ٧ أيام',
      'stats_period_week': 'الأسبوع',
      'stats_period_month': 'الشهر',
      'stats_period_all': 'الكل',
      'stats_time_of_day': 'وقت التركيز في اليوم',
      'stats_records': 'الأرقام القياسية',
      'stats_best_day': 'أفضل يوم في الأسبوع',
      'stats_all_time': 'إجمالي كل الوقت',
      'stats_legend_today': 'اليوم',
      'stats_legend_peak': 'الذروة',
      'stats_legend_other': 'أخرى',
      // ✅ ADDED: previously missing keys
      'stats_weekly_chart': 'مخطط ٧ أيام',
      'stats_heatmap': 'نشاط ٢٨ يوماً',
      'stats_best_session': 'أفضل جلسة',

      // ── Hero stat cards (stat_* prefix) ───────────────────────────
      'stat_sessions': 'الجلسات',
      'stat_hours': 'الساعات',
      'stat_starred': 'المميزة',

      // ── Day abbreviations ─────────────────────────────────────────
      'day_mon': 'إثن',
      'day_tue': 'ثلا',
      'day_wed': 'أرب',
      'day_thu': 'خمي',
      'day_fri': 'جمع',
      'day_sat': 'سبت',
      'day_sun': 'أحد',

      // ════════════════════════════════════════════════════════════════
      // SETTINGS SCREEN
      // ════════════════════════════════════════════════════════════════
      'settings_title': 'الإعدادات',
      'settings_tagline': 'ركّز. سجّل. اترك أثراً.',

      // ── Section headers ───────────────────────────────────────────
      'settings_section_focus': 'التركيز',
      'settings_section_appearance': 'المظهر',
      'settings_section_notifications': 'الإشعارات',
      'settings_section_data': 'البيانات',
      'settings_section_about': 'حول التطبيق',

      // ── Appearance ────────────────────────────────────────────────
      'settings_preferences': 'التفضيلات',
      'settings_language': 'اللغة',
      'settings_language_en': 'الإنجليزية',
      'settings_language_ar': 'العربية',
      'settings_theme': 'المظهر',
      'settings_theme_system': 'النظام',
      'settings_theme_light': 'فاتح',
      'settings_theme_dark': 'داكن',
      'theme_system': 'النظام',
      'theme_light': 'فاتح',
      'theme_dark': 'داكن',

      // ── Focus duration ────────────────────────────────────────────
      'settings_focus_duration': 'مدة التركيز',
      'settings_duration': 'مدة التركيز',
      'settings_duration_hint': 'يُطبَّق على الجلسات الجديدة فقط',
      'settings_duration_picker_title': 'مدة التركيز',
      'settings_duration_locked': 'المؤقت قيد التشغيل — أوقفه للتغيير',

      // ── Notifications ─────────────────────────────────────────────
      'settings_notifications': 'الإشعارات',
      'settings_notif_session_end': 'تنبيه نهاية الجلسة',
      'settings_notif_session_end_hint': 'إشعار عند اكتمال الجلسة',
      'settings_notif_reminder': 'تذكير يومي',
      'settings_notif_reminder_hint': 'تذكير يومي لبدء جلسة تركيز',
      'settings_notif_vibrate': 'اهتزاز عند الاكتمال',
      'settings_notify_complete': 'تنبيه نهاية الجلسة',
      'settings_notify_complete_sub': 'إشعار عند اكتمال الجلسة',
      'settings_daily_reminder': 'تذكير يومي',
      'settings_daily_reminder_sub': 'تذكير يومي لبدء جلسة تركيز',
      'settings_vibrate': 'اهتزاز عند الاكتمال',
      'settings_vibrate_sub': 'اهتزاز خفيف عند انتهاء الجلسة',

      // ── Data section ──────────────────────────────────────────────
      'settings_data': 'البيانات',
      'settings_export': 'تصدير الجلسات',
      'settings_export_hint': 'تصدير سجلاتك كملف CSV',
      'settings_export_soon': 'ميزة التصدير قادمة قريباً!',
      'settings_clear_all': 'حذف جميع الجلسات',
      'settings_clear_all_hint': 'حذف كل سجلات التركيز نهائياً',
      'settings_your_data': 'بياناتك',
      'settings_clear_data': 'حذف جميع البيانات',
      'settings_clear_data_sub': 'حذف كل سجلات التركيز نهائياً',
      'settings_clear_data_btn': 'حذف',
      'settings_clear_title': 'حذف جميع الجلسات؟',
      'settings_clear_body': 'سيتم حذف جميع جلساتك بشكل نهائي. '
          'هذا الإجراء لا يمكن التراجع عنه.',
      'settings_clear_confirm': 'حذف الكل',
      'settings_clear_yes': 'حذف الكل',
      'settings_cleared_snack': 'تم حذف جميع الجلسات',

      // ── About ─────────────────────────────────────────────────────
      'settings_open_source': 'مفتوح المصدر',
      'settings_about': 'حول التطبيق',
      'settings_version': 'الإصدار',
      'settings_about_text': 'أثر يساعدك على التركيز العميق وتوثيق تقدمك — '
          'بالكامل دون اتصال بالإنترنت.',
    },
  }; // end _strings

  // ════════════════════════════════════════════════════════════════
  // CORE HELPERS
  // ════════════════════════════════════════════════════════════════

  /// Returns the localized string for [key].
  /// Falls back: active lang → English → raw key (never crashes).
  static String of(BuildContext context, String key) {
    final lang =
        Provider.of<AppState>(context, listen: false).locale.languageCode;
    return _strings[lang]?[key] ?? _strings['en']?[key] ?? key;
  }

  /// Returns a localized string with named placeholder substitution.
  /// Example: S.fmt(ctx, 'log_duration_label', {'n': '25'}) → '25 min'
  static String fmt(
    BuildContext context,
    String key,
    Map<String, String> args,
  ) {
    String value = of(context, key);
    for (final entry in args.entries) {
      value = value.replaceAll('{${entry.key}}', entry.value);
    }
    return value;
  }

  // ════════════════════════════════════════════════════════════════
  // DIRECTION UTILITIES
  // ════════════════════════════════════════════════════════════════

  static const _rtlLangs = {'ar', 'he', 'fa', 'ur', 'ps'};

  /// Returns true when the current locale is right-to-left.
  static bool isRTL(BuildContext context) {
    final lang =
        Provider.of<AppState>(context, listen: false).locale.languageCode;
    return _rtlLangs.contains(lang);
  }

  /// Returns the [TextDirection] for the current locale.
  static TextDirection dir(BuildContext context) =>
      isRTL(context) ? TextDirection.rtl : TextDirection.ltr;

  // ════════════════════════════════════════════════════════════════
  // DAY LABEL
  // ════════════════════════════════════════════════════════════════

  static const Map<int, String> _dayKeys = {
    DateTime.monday: 'day_mon',
    DateTime.tuesday: 'day_tue',
    DateTime.wednesday: 'day_wed',
    DateTime.thursday: 'day_thu',
    DateTime.friday: 'day_fri',
    DateTime.saturday: 'day_sat',
    DateTime.sunday: 'day_sun',
  };

  /// Returns a localized 3-letter day abbreviation for a [DateTime].
  static String dayLabel(BuildContext context, DateTime date) =>
      of(context, _dayKeys[date.weekday] ?? 'day_sun');
}
