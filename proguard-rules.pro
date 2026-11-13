# Keep AccessibilityService and BroadcastReceivers intact
-keep class com.oppo.checkin.service.CheckinAccessibilityService { *; }
-keep class com.oppo.checkin.scheduler.DailyAlarmReceiver { *; }
-keep class com.oppo.checkin.scheduler.SystemEventReceiver { *; }
