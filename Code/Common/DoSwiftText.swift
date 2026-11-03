//
//  DoSwiftText.swift
//  DoSwift
//
//  Created by moonShadow on 2026/11/03
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import Foundation

extension DO {

    /// User-facing copy: one `NSLocalizedString` per property, key stable, English as `value`
    /// so a missing table falls back to real text instead of leaking keys.
    ///
    /// Table: `Resources/{en,zh-Hans}.lproj/Localizable.strings`, source language `en`.
    /// Arguments go through `format`; use `%1$@`-style positions when there are several.
    ///
    /// Not here: dev logs and assertions, selectors and keys, queue labels, number/unit
    /// templates, SQL, raw KVC value renderings.
    ///
    /// Apple API names, protocol names, units and acronyms stay English in both languages.
    enum Text {}
}

extension DO.Text {

    /// Looks up `key`; `fallback` is the English text used when the table is missing.
    static func string(_ key: String, _ fallback: String) -> String {
        return NSLocalizedString(key, tableName: nil, bundle: DO.resourceBundle, value: fallback, comment: "")
    }

    /// Localized format string, then `String(format:)`.
    static func format(_ key: String, _ fallback: String, _ args: CVarArg...) -> String {
        return String(format: string(key, fallback), arguments: args)
    }
}

extension DO.Text {

    enum Common {
        static let cancel = DO.Text.string("common.cancel", "Cancel")
        static let ok = DO.Text.string("common.ok", "OK")
        static let delete = DO.Text.string("common.delete", "Delete")
        static let clear = DO.Text.string("common.clear", "Clear")
        static let settings = DO.Text.string("common.settings", "Settings")
        static let custom = DO.Text.string("common.custom", "Custom")
        static let startCapture = DO.Text.string("common.start_capture", "Start Capture")
        static let stopCapture = DO.Text.string("common.stop_capture", "Stop Capture")
    }
}

extension DO.Text {

    enum AppInfo {
        static let title = DO.Text.string("appinfo.title", "App Info")
        static let copyJSON = DO.Text.string("appinfo.copy_json", "Copy JSON")
        static let applicationSection = DO.Text.string("appinfo.section.application", "Application")
        static let rowBundleIdentifier = DO.Text.string("appinfo.row.bundle_id", "Bundle ID")
        static let rowVersion = DO.Text.string("appinfo.row.version", "Version")
        static let rowBuild = DO.Text.string("appinfo.row.build", "Build")
        static let rowDisplayName = DO.Text.string("appinfo.row.display_name", "Display Name")
        static let rowBuildConfiguration = DO.Text.string("appinfo.row.build_configuration", "Build Configuration")
        static let rowDistribution = DO.Text.string("appinfo.row.distribution", "Distribution")
        static let rowRuntimeForm = DO.Text.string("appinfo.row.runtime_form", "Runtime Form")
        static let rowExecutableTimestamp = DO.Text.string("appinfo.row.executable_timestamp", "Executable Timestamp")
        static let developmentSigned = DO.Text.string("appinfo.distribution.development", "Development / Enterprise")
        static let simulator = DO.Text.string("appinfo.runtime.simulator", "Simulator")
        static let deviceOnMac = DO.Text.string("appinfo.runtime.device_mac", "Device · Mac")
        static let device = DO.Text.string("appinfo.runtime.device", "Device")
        static let authoritySection = DO.Text.string("appinfo.section.authority", "Permissions")
        static let location = DO.Text.string("appinfo.authority.location", "Location")
        static let notification = DO.Text.string("appinfo.authority.notification", "Notifications")
        static let camera = DO.Text.string("appinfo.authority.camera", "Camera")
        static let microphone = DO.Text.string("appinfo.authority.microphone", "Microphone")
        static let photo = DO.Text.string("appinfo.authority.photo", "Photos")
        static let contacts = DO.Text.string("appinfo.authority.contacts", "Contacts")
        static let calendar = DO.Text.string("appinfo.authority.calendar", "Calendar")
        static let reminder = DO.Text.string("appinfo.authority.reminder", "Reminders")
        static let bluetooth = DO.Text.string("appinfo.authority.bluetooth", "Bluetooth")
        static let tracking = DO.Text.string("appinfo.authority.tracking", "Tracking")
        static let cellular = DO.Text.string("appinfo.authority.cellular", "Cellular Data")
        static let stateNotDetermined = DO.Text.string("appinfo.state.not_determined", "Not Determined")
        static let stateRestricted = DO.Text.string("appinfo.state.restricted", "Restricted")
        static let stateDenied = DO.Text.string("appinfo.state.denied", "Denied")
        static let stateGranted = DO.Text.string("appinfo.state.granted", "Authorized")
        static let stateAlways = DO.Text.string("appinfo.state.always", "Always Allow")
        static let stateWhenInUse = DO.Text.string("appinfo.state.when_in_use", "While Using")
        static let stateLimited = DO.Text.string("appinfo.state.limited", "Limited")
        static let stateWriteOnly = DO.Text.string("appinfo.state.write_only", "Write Only")
        static let stateUnavailable = DO.Text.string("appinfo.state.unavailable", "Not Applicable")
        static let stateUnknown = DO.Text.string("appinfo.state.unknown", "Unknown")
        static let cellularRestrictedToWifi = DO.Text.string("appinfo.cellular.restricted_wifi", "Restricted (Wi-Fi Only)")
        static let cellularUnrestricted = DO.Text.string("appinfo.cellular.unrestricted", "Unrestricted")
        static let deviceSection = DO.Text.string("appinfo.section.device", "Device")
        static let rowModel = DO.Text.string("appinfo.row.model", "Model")
        static let rowSystemVersion = DO.Text.string("appinfo.row.system_version", "System Version")
        static let rowScreen = DO.Text.string("appinfo.row.screen", "Screen")
        static let rowDeviceName = DO.Text.string("appinfo.row.device_name", "Device Name")
        static let runtimeSection = DO.Text.string("appinfo.section.runtime", "Runtime")
        static let rowTopViewController = DO.Text.string("appinfo.row.top_view_controller", "Top View Controller")
        static let rowLanguageAndRegion = DO.Text.string("appinfo.row.language_region", "Language & Region")
        static let rowTimeZone = DO.Text.string("appinfo.row.time_zone", "Time Zone")
        static let rowThermalState = DO.Text.string("appinfo.row.thermal_state", "Thermal State")
        static let rowLowPowerMode = DO.Text.string("appinfo.row.low_power_mode", "Low Power Mode")
        static let rowVendorIdentifier = DO.Text.string("appinfo.row.vendor_identifier", "Vendor Identifier")
        static let enabled = DO.Text.string("appinfo.toggle.on", "On")
        static let disabled = DO.Text.string("appinfo.toggle.off", "Off")
        static let thermalNominal = DO.Text.string("appinfo.thermal.nominal", "Nominal")
        static let thermalFair = DO.Text.string("appinfo.thermal.fair", "Fair")
        static let thermalSerious = DO.Text.string("appinfo.thermal.serious", "Serious")
        static let thermalCritical = DO.Text.string("appinfo.thermal.critical", "Critical")
        static let thermalUnknown = DO.Text.string("appinfo.thermal.unknown", "Unknown")
    }
}

extension DO.Text {

    enum Sandbox {
        static let title = DO.Text.string("sandbox.title", "Sandbox")
        static let rootName = DO.Text.string("sandbox.root_name", "Sandbox")
        static let preview = DO.Text.string("sandbox.action.preview", "Preview")
        static let share = DO.Text.string("sandbox.action.share", "Share")
        static let copyPath = DO.Text.string("sandbox.action.copy_path", "Copy Path")
        static let actionFailed = DO.Text.string("sandbox.action.failed", "Action Failed")
        static let noTables = DO.Text.string("sandbox.database.no_tables", "No readable tables.")
        static let noRows = DO.Text.string("sandbox.database.no_rows", "No data.")
        static func dataTables(_ count: Int) -> String {
            return DO.Text.format("sandbox.database.tables", "Tables (%d)", count)
        }
        static func row(_ index: Int) -> String {
            return DO.Text.format("sandbox.database.row", "Row %d", index + 1)
        }
        static func recordCount(_ count: Int) -> String {
            return DO.Text.format("sandbox.database.record_count", "%d records", count)
        }
        static func truncated(maxRows: Int) -> String {
            return DO.Text.format("sandbox.database.truncated", "Showing the first %d only.", maxRows)
        }
        static func blobPlaceholder(_ bytes: Int32) -> String {
            return DO.Text.format("sandbox.database.blob", "<BLOB, %d bytes>", bytes)
        }
    }
}

extension DO.Text {

    enum Trend {
        static let lineChart = DO.Text.string("trend.style.line", "Line Chart")
        static let singleLineText = DO.Text.string("trend.style.text", "Single Line")
    }
}

extension DO.Text {

    enum Perf {
        static let title = DO.Text.string("perf.title", "Performance")
        static let fps = DO.Text.string("perf.metric.fps", "FPS")
        static let cpu = DO.Text.string("perf.metric.cpu", "CPU")
        static let memory = DO.Text.string("perf.metric.memory", "Memory")
        static let toggleDetect = DO.Text.string("perf.settings.track", "Track")
        static let memoryMetric = DO.Text.string("perf.settings.memory_metric", "Metric")
        static let memoryMetricFooter = DO.Text.string("perf.settings.memory_metric_footer", "The two metrics measure different things: footprint is what the system kills on, heap only covers malloc. Switching clears captured data.")
        static let memoryMetricAlert = DO.Text.string("perf.settings.memory_metric_alert", "Memory Metric")
        static let displaySection = DO.Text.string("perf.settings.display", "Display")
        static let displayFooter = DO.Text.string("perf.settings.display_footer", "Both styles read the same data. Switching style keeps all history.")
        static let floatingStyle = DO.Text.string("perf.settings.floating_style", "Overlay Style")
        static let closeFloating = DO.Text.string("perf.settings.close_floating", "Close Overlay")
        static let longPressTip = DO.Text.string("perf.settings.long_press_tip", "Long-press the overlay to open this page again.")
        static let cannotDisableLast = DO.Text.string("perf.settings.keep_one", "Keep at least one metric.")
        static func current(_ value: String) -> String {
            return DO.Text.format("perf.current", "Current: %@", value)
        }
        static func thresholdAbove(range: String, value: Int) -> String {
            return DO.Text.format("perf.threshold.above", "%1$@ · above %2$d turns red", range, value)
        }
        static func thresholdBelow(range: String, value: Int) -> String {
            return DO.Text.format("perf.threshold.below", "%1$@ · below %2$d turns red", range, value)
        }
        static let memoryFootprint = DO.Text.string("perf.memory.footprint", "Footprint")
        static let memoryHeap = DO.Text.string("perf.memory.heap", "Heap")
        static let overview = DO.Text.string("perf.report.overview", "Overview")
        static let scopeAll = DO.Text.string("perf.report.scope_all", "All")
        static let total = DO.Text.string("perf.report.total", "Total")
        static let average = DO.Text.string("perf.report.average", "Average")
        static let peak = DO.Text.string("perf.report.peak", "Peak")
        static let graphics = DO.Text.string("perf.report.graphics", "Graphics")
        static let media = DO.Text.string("perf.report.media", "Media")
        static let network = DO.Text.string("perf.report.network", "Network")
        static let rest = DO.Text.string("perf.report.rest", "Other")
        static let averageUsage = DO.Text.string("perf.report.average_usage", "Average Usage")
        static let accumulatedCPUTime = DO.Text.string("perf.report.cpu_time", "Total CPU Time")
        static let averageFPS = DO.Text.string("perf.report.average_fps", "Average FPS")
        static let slowFrames = DO.Text.string("perf.report.slow_frames", "Slow Frames")
        static let frozenFrames = DO.Text.string("perf.report.frozen_frames", "Frozen Frames")
        static let totalFrames = DO.Text.string("perf.report.total_frames", "Total Frames")
        static func seconds(_ total: Int) -> String {
            return DO.Text.format("perf.duration.seconds", "%d s", total)
        }
        static func minutesAndSeconds(_ total: Int) -> String {
            return DO.Text.format("perf.duration.minutes_seconds", "%d m %02d s", total / 60, total % 60)
        }
    }
}

extension DO.Text {

    enum Network {
        static let title = DO.Text.string("network.title", "Network")
        static let failed = DO.Text.string("network.row.failed", "Failed")
        static let emptyFooter = DO.Text.string("network.empty", "No requests captured. Only URLSession is covered — WKWebView, WebSocket and raw sockets are not; sessions created before capture started are covered from the next session on.")
        static func requests(_ count: Int) -> String {
            return DO.Text.format("network.section.requests", "Requests (%d)", count)
        }
        static let overviewSection = DO.Text.string("network.section.overview", "Overview")
        static let requestSection = DO.Text.string("network.section.request", "Request")
        static let responseSection = DO.Text.string("network.section.response", "Response")
        static let requestHeaders = DO.Text.string("network.row.request_headers", "Request Headers")
        static let requestBody = DO.Text.string("network.row.request_body", "Request Body")
        static let responseHeaders = DO.Text.string("network.row.response_headers", "Response Headers")
        static let responseBody = DO.Text.string("network.row.response_body", "Response Body")
        static let rowURL = DO.Text.string("network.row.url", "URL")
        static let rowMethod = DO.Text.string("network.row.method", "Method")
        static let rowStatus = DO.Text.string("network.row.status", "Status")
        static let rowDuration = DO.Text.string("network.row.duration", "Duration")
        static let none = DO.Text.string("network.value.none", "None")
        static let view = DO.Text.string("network.value.view", "View")
        static func binaryBody(_ bytes: Int) -> String {
            return DO.Text.format("network.body.binary", "<%d bytes of binary data>", bytes)
        }
        static func truncatedBody(maxBytes: Int) -> String {
            return DO.Text.format("network.body.truncated", "\n\n… truncated to the first %d bytes", maxBytes)
        }
    }
}

extension DO.Text {

    enum Console {
        static let title = DO.Text.string("console.title", "Console")
        static let searchPlaceholder = DO.Text.string("console.search.placeholder", "Search lines")
        static let emptyNothing = DO.Text.string("console.empty.nothing", "Nothing captured yet.\nA pipe only sees output written after it is attached — tap record below,\nor call DO.ConsolePlugin.shared.start() at launch to keep the whole session.")
        static func emptyAllFiltered(_ count: Int) -> String {
            return DO.Text.format("console.empty.filtered", "All %d captured lines are hidden by the filter.\nCheck Settings → Sources.", count)
        }
        static let resume = DO.Text.string("console.toolbar.resume", "Resume")
        static let pause = DO.Text.string("console.toolbar.pause", "Pause")
        static let readUnifiedLog = DO.Text.string("console.toolbar.read_log", "Read Unified Log")
        static let readingUnifiedLog = DO.Text.string("console.toolbar.reading_log", "Reading Unified Log")
        static func totalLines(_ count: Int) -> String {
            return DO.Text.format("console.status.total", "total %d", count)
        }
        static func sourceCount(_ shortTitle: String, _ count: Int) -> String {
            return DO.Text.format("console.status.source", "%1$@ %2$d", shortTitle, count)
        }
        static func filteredSources(_ visible: Int, _ total: Int) -> String {
            return DO.Text.format("console.status.filtered", "%d/%d sources", visible, total)
        }
        static let captureOff = DO.Text.string("console.status.capture_off", "capture off")
        static let paused = DO.Text.string("console.status.paused", "paused")
        static let unifiedLogNeedsIOS15 = DO.Text.string("console.status.needs_ios15", "unified log needs iOS 15")
        static let readingUnifiedLogStatus = DO.Text.string("console.status.reading", "reading unified log…")
        static func readIn(_ seconds: Double) -> String {
            return DO.Text.format("console.status.read_in", "read in %.1fs", seconds)
        }
        static func clearConfirmation(_ count: Int) -> String {
            return DO.Text.format("console.clear.confirmation", "Clear all captured lines (%d)?", count)
        }
        static let show = DO.Text.string("console.settings.show", "Show")
        static let showDetail = DO.Text.string("console.settings.show_detail", "Include these lines in the list.")
        static let mergeSameTimestamp = DO.Text.string("console.settings.merge", "Merge Same Timestamp")
        static let mergeDetail = DO.Text.string("console.settings.merge_detail", "Consecutive lines sharing a timestamp become one block.")
        static let mergeDetailUnifiedLog = DO.Text.string("console.settings.merge_detail_log", "Off by default — unified log entries already carry their own boundaries.")
        static let unavailable = DO.Text.string("console.settings.unavailable", "Unavailable on this system.")
        static let unifiedLogFooter = DO.Text.string("console.settings.log_footer", "One read costs about a second regardless of how much is there, so it runs when you open the page or tap the button — never on a timer. Interpolated values are private by default: only what was logged with `privacy: .public` (and numbers) can be read.")
        static let noSubsystem = DO.Text.string("console.settings.no_subsystem", "No Subsystem")
        static let noSubsystemDetail = DO.Text.string("console.settings.no_subsystem_detail", "A bare `Logger()` has an empty subsystem — could be yours, could be a framework's")
        static let standardOutput = DO.Text.string("console.source.stdout", "Standard Output")
        static let standardError = DO.Text.string("console.source.stderr", "Standard Error")
        static let unifiedLog = DO.Text.string("console.source.unified_log", "Unified Log")
        static let standardOutputDetail = DO.Text.string("console.source.stdout_detail", "print / fputs / FileHandle — fd 1")
        static let standardErrorDetail = DO.Text.string("console.source.stderr_detail", "NSLog — fd 2")
        static let unifiedLogDetail = DO.Text.string("console.source.unified_log_detail", "os_log / Logger — readable since iOS 15")
        static let levelDebug = DO.Text.string("console.level.debug", "Debug")
        static let levelInfo = DO.Text.string("console.level.info", "Info")
        static let levelNotice = DO.Text.string("console.level.notice", "Notice")
        static let levelError = DO.Text.string("console.level.error", "Error")
        static let levelFault = DO.Text.string("console.level.fault", "Fault")
    }
}

extension DO.Text {

    enum Hierarchy {
        static let pluginTitle = DO.Text.string("hierarchy.title", "Hierarchy")
        static let detailTitle = DO.Text.string("hierarchy.detail_title", "UI Structure")
        static let infoTitle = DO.Text.string("hierarchy.info_title", "UI Hierarchy")
        static let pinnedSection = DO.Text.string("hierarchy.pinned", "Pinned")
        static let never = DO.Text.string("hierarchy.visibility.never", "Never")
        static let whileDragging = DO.Text.string("hierarchy.visibility.while_dragging", "While Dragging")
        static let always = DO.Text.string("hierarchy.visibility.always", "Always")
        static let colorPickerGroup = DO.Text.string("hierarchy.settings.color_picker", "Color Picker")
        static let alignRulerGroup = DO.Text.string("hierarchy.settings.align_ruler", "Align Ruler")
        static let viewHierarchyGroup = DO.Text.string("hierarchy.settings.view_hierarchy", "View Hierarchy")
        static let enabled = DO.Text.string("hierarchy.settings.enabled", "Enabled")
        static let loupe = DO.Text.string("hierarchy.settings.loupe", "Loupe")
        static let crossLines = DO.Text.string("hierarchy.settings.cross_lines", "Cross Lines")
        static let ignorePrivateClasses = DO.Text.string("hierarchy.settings.ignore_private", "Ignore Private Classes")
        static let colorPickerDetail = DO.Text.string("hierarchy.settings.color_picker_detail", "Pixel color readout in the panel, plus the loupe")
        static let loupeDetail = DO.Text.string("hierarchy.settings.loupe_detail", "When the magnifier appears")
        static let alignRulerDetail = DO.Text.string("hierarchy.settings.align_ruler_detail", "Distances to the four edges in the panel, plus the cross lines")
        static let crossLinesDetail = DO.Text.string("hierarchy.settings.cross_lines_detail", "When the ruler lines appear")
        static let ignorePrivateDetail = DO.Text.string("hierarchy.settings.ignore_private_detail", "Skip views whose class name starts with an underscore")
        static let settingsFooter = DO.Text.string("hierarchy.settings.footer", "Applied immediately and remembered in UserDefaults.")
        static let keyPosition = DO.Text.string("hierarchy.key.position", "Position:")
        static let keyName = DO.Text.string("hierarchy.key.name", "Name:")
        static let keyPixel = DO.Text.string("hierarchy.key.pixel", "Pixel:")
        static let keyFrame = DO.Text.string("hierarchy.key.frame", "Frame:")
        static let keyBackground = DO.Text.string("hierarchy.key.background", "Background:")
        static let keyTextColor = DO.Text.string("hierarchy.key.text_color", "Text Color:")
        static let keyFont = DO.Text.string("hierarchy.key.font", "Font:")
        static let keyTag = DO.Text.string("hierarchy.key.tag", "Tag:")
        static let parents = DO.Text.string("hierarchy.button.parents", "Parents")
        static let childs = DO.Text.string("hierarchy.button.children", "Children")
        static let more = DO.Text.string("hierarchy.button.more", "More")
        static let parentViewsSheet = DO.Text.string("hierarchy.sheet.parents", "Parent Views")
        static let subviewsSheet = DO.Text.string("hierarchy.sheet.subviews", "Subviews")
        static let note = DO.Text.string("hierarchy.alert.note", "Note")
        static let confirm = DO.Text.string("hierarchy.alert.confirm", "Confirm")
        static let colorHint = DO.Text.string("hierarchy.editor.color_hint", "Also accepts r,g,b,a · #RRGGBBAA")
        static let now = DO.Text.string("hierarchy.editor.now", "Now")
        static let plusOneDay = DO.Text.string("hierarchy.editor.plus_day", "+1 day")
        static let plusOneHour = DO.Text.string("hierarchy.editor.plus_hour", "+1 hour")
        static let done = DO.Text.string("hierarchy.editor.done", "Done")
        static let fontPreview = DO.Text.string("hierarchy.editor.font_preview", "The quick brown fox 0123456789")
        static func characterAndLineCount(_ characters: Int, _ lines: Int) -> String {
            return DO.Text.format("hierarchy.editor.count", "%1$d characters · %2$d lines", characters, lines)
        }
    }
}

extension DO.Text {

    enum UserDefaults {
        static let title = DO.Text.string("userdefaults.title", "UserDefaults")
        static let searchPlaceholder = DO.Text.string("userdefaults.search.placeholder", "Search by key")
        static let selectAll = DO.Text.string("userdefaults.select_all", "Select All")
        static let deselectAll = DO.Text.string("userdefaults.deselect_all", "Deselect All")
        static func deleteWithCount(_ count: Int) -> String {
            return DO.Text.format("userdefaults.delete_with_count", "Delete (%d)", count)
        }
        static func deleteConfirmation(_ count: Int) -> String {
            return DO.Text.format("userdefaults.delete_confirmation", "Delete selected keys (%d)?", count)
        }
        static let appDomain = DO.Text.string("userdefaults.domain.app", "App")
        static let otherDomains = DO.Text.string("userdefaults.domain.other", "Other Domains")
        static func dataSummary(_ bytes: Int) -> String {
            return DO.Text.format("userdefaults.data_summary", "Data · %d bytes", bytes)
        }
    }
}

extension DO.Text {

    enum FileBrowser {
        static let loading = DO.Text.string("filebrowser.loading", "Loading…")
        static let emptyFolder = DO.Text.string("filebrowser.empty", "Empty Folder")
    }
}

extension DO.Text {

    enum Menu {
        static let infoGroup = DO.Text.string("menu.group.info", "Info")
        static let visualGroup = DO.Text.string("menu.group.visual", "Visual")
    }
}
