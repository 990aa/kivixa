using System.Windows.Input;

namespace Kivixa.PlatformChannels {
    public static class StylusHelper {
        public static float GetPressure() {
            // Fallback: return 1.0f if stylus not available
            if (Stylus.CurrentStylusDevice != null) {
                return Stylus.CurrentStylusDevice.GetStylusPoints(null)[0].PressureFactor;
            }
            return 1.0f;
        }
    }
}
