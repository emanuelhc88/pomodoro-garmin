using Toybox.Lang;
using Toybox.WatchUi as Ui;

module TimeFormatter {
    function formatDuration(totalSeconds as Lang.Number) as Lang.String {
        var hours = totalSeconds / 3600;
        var minutes = (totalSeconds % 3600) / 60;

        if (hours > 0) {
            var pattern = Ui.loadResource(Rez.Strings.duration_hours_minutes) as Lang.String;
            return Lang.format(pattern, [hours, minutes]);
        }
        var pattern = Ui.loadResource(Rez.Strings.duration_minutes) as Lang.String;
        return Lang.format(pattern, [minutes]);
    }

    function formatTime(hour as Lang.Number, min as Lang.Number) as Lang.String {
        return Lang.format("$1$:$2$", [hour.format("%02d"), min.format("%02d")]);
    }
}
