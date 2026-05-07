using Toybox.Lang;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.System as Sys;

module DateUtils {
    function formatDate(epoch as Lang.Number) as Lang.String {
        var moment = new Time.Moment(epoch);
        var info = Gregorian.info(moment, Time.FORMAT_SHORT);
        var monthNames = getMonthNames();
        var monthIdx = (info.month as Lang.Number) - 1;
        if (monthIdx < 0 || monthIdx > 11) { monthIdx = 0; }
        var monthStr = monthNames[monthIdx] as Lang.String;
        var timeStr = TimeFormatter.formatTime(info.hour as Lang.Number, info.min as Lang.Number);

        if (getLocale() == :pt) {
            return Lang.format("$1$ $2$, $3$", [info.day, monthStr, timeStr]);
        }
        return Lang.format("$1$ $2$, $3$", [monthStr, info.day, timeStr]);
    }

    function getMonthNames() as Lang.Array<Lang.String> {
        if (getLocale() == :pt) {
            return ["Jan", "Fev", "Mar", "Abr", "Mai", "Jun", "Jul", "Ago", "Set", "Out", "Nov", "Dez"];
        }
        return ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    }

    function getLocale() as Lang.Symbol {
        var lang = Sys.getDeviceSettings().systemLanguage;
        if (lang == Sys.LANGUAGE_POR) {
            return :pt;
        }
        return :en;
    }
}
