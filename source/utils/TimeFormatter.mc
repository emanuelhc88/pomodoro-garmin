using Toybox.Lang;

module TimeFormatter {
    function formatDuration(totalSeconds as Lang.Number) as Lang.String {
        var hours = totalSeconds / 3600;
        var minutes = (totalSeconds % 3600) / 60;

        if (hours > 0) {
            return Strings.format(:duration_hours_minutes, [hours, minutes]);
        }
        return Strings.format(:duration_minutes, [minutes]);
    }

    function formatTime(hour as Lang.Number, min as Lang.Number) as Lang.String {
        return Lang.format("$1$:$2$", [hour.format("%02d"), min.format("%02d")]);
    }
}
