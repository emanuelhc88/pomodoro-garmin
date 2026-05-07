using Toybox.System as Sys;
using Toybox.Lang;

module Bucket {
    function detect() as Lang.Symbol {
        var w = Sys.getDeviceSettings().screenWidth;
        if (w <= 220) {
            return :small;
        }
        if (w <= 290) {
            return :medium;
        }
        return :large;
    }
}
