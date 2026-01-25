//! Unit conversion utilities

use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use once_cell::sync::Lazy;

/// Result of unit conversion
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UnitResult {
    pub success: bool,
    pub value: f64,
    pub from_unit: String,
    pub to_unit: String,
    pub formula: String,
    pub error: Option<String>,
}

impl UnitResult {
    pub fn converted(value: f64, from: &str, to: &str, formula: &str) -> Self {
        Self {
            success: true,
            value,
            from_unit: from.to_string(),
            to_unit: to.to_string(),
            formula: formula.to_string(),
            error: None,
        }
    }

    pub fn error(msg: &str) -> Self {
        Self {
            success: false,
            value: f64::NAN,
            from_unit: String::new(),
            to_unit: String::new(),
            formula: String::new(),
            error: Some(msg.to_string()),
        }
    }
}

/// Unit category and conversion factors to base unit
struct UnitDef {
    category: &'static str,
    to_base: f64,      // multiply by this to get base unit
    offset: f64,       // add this after multiplication (for temperature)
}

/// All supported units with conversion to base unit
static UNITS: Lazy<HashMap<&'static str, UnitDef>> = Lazy::new(|| {
    let mut m = HashMap::new();
    
    // Length - base: meter
    m.insert("m", UnitDef { category: "length", to_base: 1.0, offset: 0.0 });
    m.insert("meter", UnitDef { category: "length", to_base: 1.0, offset: 0.0 });
    m.insert("meters", UnitDef { category: "length", to_base: 1.0, offset: 0.0 });
    m.insert("km", UnitDef { category: "length", to_base: 1000.0, offset: 0.0 });
    m.insert("kilometer", UnitDef { category: "length", to_base: 1000.0, offset: 0.0 });
    m.insert("cm", UnitDef { category: "length", to_base: 0.01, offset: 0.0 });
    m.insert("centimeter", UnitDef { category: "length", to_base: 0.01, offset: 0.0 });
    m.insert("mm", UnitDef { category: "length", to_base: 0.001, offset: 0.0 });
    m.insert("millimeter", UnitDef { category: "length", to_base: 0.001, offset: 0.0 });
    m.insert("um", UnitDef { category: "length", to_base: 1e-6, offset: 0.0 });
    m.insert("micrometer", UnitDef { category: "length", to_base: 1e-6, offset: 0.0 });
    m.insert("nm", UnitDef { category: "length", to_base: 1e-9, offset: 0.0 });
    m.insert("nanometer", UnitDef { category: "length", to_base: 1e-9, offset: 0.0 });
    m.insert("mi", UnitDef { category: "length", to_base: 1609.344, offset: 0.0 });
    m.insert("mile", UnitDef { category: "length", to_base: 1609.344, offset: 0.0 });
    m.insert("miles", UnitDef { category: "length", to_base: 1609.344, offset: 0.0 });
    m.insert("yd", UnitDef { category: "length", to_base: 0.9144, offset: 0.0 });
    m.insert("yard", UnitDef { category: "length", to_base: 0.9144, offset: 0.0 });
    m.insert("ft", UnitDef { category: "length", to_base: 0.3048, offset: 0.0 });
    m.insert("foot", UnitDef { category: "length", to_base: 0.3048, offset: 0.0 });
    m.insert("feet", UnitDef { category: "length", to_base: 0.3048, offset: 0.0 });
    m.insert("in", UnitDef { category: "length", to_base: 0.0254, offset: 0.0 });
    m.insert("inch", UnitDef { category: "length", to_base: 0.0254, offset: 0.0 });
    m.insert("inches", UnitDef { category: "length", to_base: 0.0254, offset: 0.0 });
    m.insert("nmi", UnitDef { category: "length", to_base: 1852.0, offset: 0.0 });
    m.insert("nautical_mile", UnitDef { category: "length", to_base: 1852.0, offset: 0.0 });
    m.insert("ly", UnitDef { category: "length", to_base: 9.461e15, offset: 0.0 });
    m.insert("lightyear", UnitDef { category: "length", to_base: 9.461e15, offset: 0.0 });
    m.insert("au", UnitDef { category: "length", to_base: 1.496e11, offset: 0.0 });
    
    // Mass - base: kilogram
    m.insert("kg", UnitDef { category: "mass", to_base: 1.0, offset: 0.0 });
    m.insert("kilogram", UnitDef { category: "mass", to_base: 1.0, offset: 0.0 });
    m.insert("g", UnitDef { category: "mass", to_base: 0.001, offset: 0.0 });
    m.insert("gram", UnitDef { category: "mass", to_base: 0.001, offset: 0.0 });
    m.insert("mg", UnitDef { category: "mass", to_base: 1e-6, offset: 0.0 });
    m.insert("milligram", UnitDef { category: "mass", to_base: 1e-6, offset: 0.0 });
    m.insert("ug", UnitDef { category: "mass", to_base: 1e-9, offset: 0.0 });
    m.insert("microgram", UnitDef { category: "mass", to_base: 1e-9, offset: 0.0 });
    m.insert("t", UnitDef { category: "mass", to_base: 1000.0, offset: 0.0 });
    m.insert("tonne", UnitDef { category: "mass", to_base: 1000.0, offset: 0.0 });
    m.insert("lb", UnitDef { category: "mass", to_base: 0.453592, offset: 0.0 });
    m.insert("pound", UnitDef { category: "mass", to_base: 0.453592, offset: 0.0 });
    m.insert("oz", UnitDef { category: "mass", to_base: 0.0283495, offset: 0.0 });
    m.insert("ounce", UnitDef { category: "mass", to_base: 0.0283495, offset: 0.0 });
    m.insert("st", UnitDef { category: "mass", to_base: 6.35029, offset: 0.0 });
    m.insert("stone", UnitDef { category: "mass", to_base: 6.35029, offset: 0.0 });
    
    // Time - base: second
    m.insert("s", UnitDef { category: "time", to_base: 1.0, offset: 0.0 });
    m.insert("sec", UnitDef { category: "time", to_base: 1.0, offset: 0.0 });
    m.insert("second", UnitDef { category: "time", to_base: 1.0, offset: 0.0 });
    m.insert("ms", UnitDef { category: "time", to_base: 0.001, offset: 0.0 });
    m.insert("millisecond", UnitDef { category: "time", to_base: 0.001, offset: 0.0 });
    m.insert("us", UnitDef { category: "time", to_base: 1e-6, offset: 0.0 });
    m.insert("microsecond", UnitDef { category: "time", to_base: 1e-6, offset: 0.0 });
    m.insert("ns", UnitDef { category: "time", to_base: 1e-9, offset: 0.0 });
    m.insert("nanosecond", UnitDef { category: "time", to_base: 1e-9, offset: 0.0 });
    m.insert("min", UnitDef { category: "time", to_base: 60.0, offset: 0.0 });
    m.insert("minute", UnitDef { category: "time", to_base: 60.0, offset: 0.0 });
    m.insert("h", UnitDef { category: "time", to_base: 3600.0, offset: 0.0 });
    m.insert("hr", UnitDef { category: "time", to_base: 3600.0, offset: 0.0 });
    m.insert("hour", UnitDef { category: "time", to_base: 3600.0, offset: 0.0 });
    m.insert("d", UnitDef { category: "time", to_base: 86400.0, offset: 0.0 });
    m.insert("day", UnitDef { category: "time", to_base: 86400.0, offset: 0.0 });
    m.insert("wk", UnitDef { category: "time", to_base: 604800.0, offset: 0.0 });
    m.insert("week", UnitDef { category: "time", to_base: 604800.0, offset: 0.0 });
    m.insert("yr", UnitDef { category: "time", to_base: 31557600.0, offset: 0.0 });
    m.insert("year", UnitDef { category: "time", to_base: 31557600.0, offset: 0.0 });
    
    // Temperature - special handling needed
    m.insert("c", UnitDef { category: "temperature", to_base: 1.0, offset: 273.15 });
    m.insert("celsius", UnitDef { category: "temperature", to_base: 1.0, offset: 273.15 });
    m.insert("k", UnitDef { category: "temperature", to_base: 1.0, offset: 0.0 });
    m.insert("kelvin", UnitDef { category: "temperature", to_base: 1.0, offset: 0.0 });
    m.insert("f", UnitDef { category: "temperature", to_base: 5.0/9.0, offset: 255.372 });
    m.insert("fahrenheit", UnitDef { category: "temperature", to_base: 5.0/9.0, offset: 255.372 });
    
    // Area - base: square meter
    m.insert("m2", UnitDef { category: "area", to_base: 1.0, offset: 0.0 });
    m.insert("sqm", UnitDef { category: "area", to_base: 1.0, offset: 0.0 });
    m.insert("km2", UnitDef { category: "area", to_base: 1e6, offset: 0.0 });
    m.insert("cm2", UnitDef { category: "area", to_base: 1e-4, offset: 0.0 });
    m.insert("mm2", UnitDef { category: "area", to_base: 1e-6, offset: 0.0 });
    m.insert("ha", UnitDef { category: "area", to_base: 10000.0, offset: 0.0 });
    m.insert("hectare", UnitDef { category: "area", to_base: 10000.0, offset: 0.0 });
    m.insert("acre", UnitDef { category: "area", to_base: 4046.86, offset: 0.0 });
    m.insert("sqft", UnitDef { category: "area", to_base: 0.092903, offset: 0.0 });
    m.insert("sqin", UnitDef { category: "area", to_base: 0.00064516, offset: 0.0 });
    m.insert("sqmi", UnitDef { category: "area", to_base: 2.59e6, offset: 0.0 });
    
    // Volume - base: cubic meter
    m.insert("m3", UnitDef { category: "volume", to_base: 1.0, offset: 0.0 });
    m.insert("l", UnitDef { category: "volume", to_base: 0.001, offset: 0.0 });
    m.insert("liter", UnitDef { category: "volume", to_base: 0.001, offset: 0.0 });
    m.insert("litre", UnitDef { category: "volume", to_base: 0.001, offset: 0.0 });
    m.insert("ml", UnitDef { category: "volume", to_base: 1e-6, offset: 0.0 });
    m.insert("milliliter", UnitDef { category: "volume", to_base: 1e-6, offset: 0.0 });
    m.insert("cm3", UnitDef { category: "volume", to_base: 1e-6, offset: 0.0 });
    m.insert("gal", UnitDef { category: "volume", to_base: 0.00378541, offset: 0.0 });
    m.insert("gallon", UnitDef { category: "volume", to_base: 0.00378541, offset: 0.0 });
    m.insert("qt", UnitDef { category: "volume", to_base: 0.000946353, offset: 0.0 });
    m.insert("quart", UnitDef { category: "volume", to_base: 0.000946353, offset: 0.0 });
    m.insert("pt", UnitDef { category: "volume", to_base: 0.000473176, offset: 0.0 });
    m.insert("pint", UnitDef { category: "volume", to_base: 0.000473176, offset: 0.0 });
    m.insert("cup", UnitDef { category: "volume", to_base: 0.000236588, offset: 0.0 });
    m.insert("floz", UnitDef { category: "volume", to_base: 2.9574e-5, offset: 0.0 });
    m.insert("tbsp", UnitDef { category: "volume", to_base: 1.4787e-5, offset: 0.0 });
    m.insert("tsp", UnitDef { category: "volume", to_base: 4.9289e-6, offset: 0.0 });
    
    // Speed - base: m/s
    m.insert("mps", UnitDef { category: "speed", to_base: 1.0, offset: 0.0 });
    m.insert("m/s", UnitDef { category: "speed", to_base: 1.0, offset: 0.0 });
    m.insert("kph", UnitDef { category: "speed", to_base: 0.277778, offset: 0.0 });
    m.insert("km/h", UnitDef { category: "speed", to_base: 0.277778, offset: 0.0 });
    m.insert("kmh", UnitDef { category: "speed", to_base: 0.277778, offset: 0.0 });
    m.insert("mph", UnitDef { category: "speed", to_base: 0.44704, offset: 0.0 });
    m.insert("knot", UnitDef { category: "speed", to_base: 0.514444, offset: 0.0 });
    m.insert("kn", UnitDef { category: "speed", to_base: 0.514444, offset: 0.0 });
    m.insert("fps", UnitDef { category: "speed", to_base: 0.3048, offset: 0.0 });
    m.insert("ft/s", UnitDef { category: "speed", to_base: 0.3048, offset: 0.0 });
    m.insert("mach", UnitDef { category: "speed", to_base: 343.0, offset: 0.0 });
    m.insert("c_speed", UnitDef { category: "speed", to_base: 299792458.0, offset: 0.0 });
    
    // Pressure - base: pascal
    m.insert("pa", UnitDef { category: "pressure", to_base: 1.0, offset: 0.0 });
    m.insert("pascal", UnitDef { category: "pressure", to_base: 1.0, offset: 0.0 });
    m.insert("kpa", UnitDef { category: "pressure", to_base: 1000.0, offset: 0.0 });
    m.insert("mpa", UnitDef { category: "pressure", to_base: 1e6, offset: 0.0 });
    m.insert("bar", UnitDef { category: "pressure", to_base: 100000.0, offset: 0.0 });
    m.insert("mbar", UnitDef { category: "pressure", to_base: 100.0, offset: 0.0 });
    m.insert("atm", UnitDef { category: "pressure", to_base: 101325.0, offset: 0.0 });
    m.insert("psi", UnitDef { category: "pressure", to_base: 6894.76, offset: 0.0 });
    m.insert("torr", UnitDef { category: "pressure", to_base: 133.322, offset: 0.0 });
    m.insert("mmhg", UnitDef { category: "pressure", to_base: 133.322, offset: 0.0 });
    
    // Energy - base: joule
    m.insert("j", UnitDef { category: "energy", to_base: 1.0, offset: 0.0 });
    m.insert("joule", UnitDef { category: "energy", to_base: 1.0, offset: 0.0 });
    m.insert("kj", UnitDef { category: "energy", to_base: 1000.0, offset: 0.0 });
    m.insert("mj", UnitDef { category: "energy", to_base: 1e6, offset: 0.0 });
    m.insert("cal", UnitDef { category: "energy", to_base: 4.184, offset: 0.0 });
    m.insert("calorie", UnitDef { category: "energy", to_base: 4.184, offset: 0.0 });
    m.insert("kcal", UnitDef { category: "energy", to_base: 4184.0, offset: 0.0 });
    m.insert("wh", UnitDef { category: "energy", to_base: 3600.0, offset: 0.0 });
    m.insert("kwh", UnitDef { category: "energy", to_base: 3.6e6, offset: 0.0 });
    m.insert("ev", UnitDef { category: "energy", to_base: 1.602e-19, offset: 0.0 });
    m.insert("btu", UnitDef { category: "energy", to_base: 1055.06, offset: 0.0 });
    
    // Power - base: watt
    m.insert("w", UnitDef { category: "power", to_base: 1.0, offset: 0.0 });
    m.insert("watt", UnitDef { category: "power", to_base: 1.0, offset: 0.0 });
    m.insert("kw", UnitDef { category: "power", to_base: 1000.0, offset: 0.0 });
    m.insert("mw", UnitDef { category: "power", to_base: 1e6, offset: 0.0 });
    m.insert("gw", UnitDef { category: "power", to_base: 1e9, offset: 0.0 });
    m.insert("hp", UnitDef { category: "power", to_base: 745.7, offset: 0.0 });
    m.insert("horsepower", UnitDef { category: "power", to_base: 745.7, offset: 0.0 });
    
    // Data - base: byte
    m.insert("b", UnitDef { category: "data", to_base: 1.0, offset: 0.0 });
    m.insert("byte", UnitDef { category: "data", to_base: 1.0, offset: 0.0 });
    m.insert("kb", UnitDef { category: "data", to_base: 1024.0, offset: 0.0 });
    m.insert("kilobyte", UnitDef { category: "data", to_base: 1024.0, offset: 0.0 });
    m.insert("mb", UnitDef { category: "data", to_base: 1048576.0, offset: 0.0 });
    m.insert("megabyte", UnitDef { category: "data", to_base: 1048576.0, offset: 0.0 });
    m.insert("gb", UnitDef { category: "data", to_base: 1073741824.0, offset: 0.0 });
    m.insert("gigabyte", UnitDef { category: "data", to_base: 1073741824.0, offset: 0.0 });
    m.insert("tb", UnitDef { category: "data", to_base: 1099511627776.0, offset: 0.0 });
    m.insert("terabyte", UnitDef { category: "data", to_base: 1099511627776.0, offset: 0.0 });
    m.insert("pb", UnitDef { category: "data", to_base: 1125899906842624.0, offset: 0.0 });
    m.insert("bit", UnitDef { category: "data", to_base: 0.125, offset: 0.0 });
    m.insert("kbit", UnitDef { category: "data", to_base: 128.0, offset: 0.0 });
    m.insert("mbit", UnitDef { category: "data", to_base: 131072.0, offset: 0.0 });
    m.insert("gbit", UnitDef { category: "data", to_base: 134217728.0, offset: 0.0 });
    
    // Angle - base: radian
    m.insert("rad", UnitDef { category: "angle", to_base: 1.0, offset: 0.0 });
    m.insert("radian", UnitDef { category: "angle", to_base: 1.0, offset: 0.0 });
    m.insert("deg", UnitDef { category: "angle", to_base: std::f64::consts::PI / 180.0, offset: 0.0 });
    m.insert("degree", UnitDef { category: "angle", to_base: std::f64::consts::PI / 180.0, offset: 0.0 });
    m.insert("grad", UnitDef { category: "angle", to_base: std::f64::consts::PI / 200.0, offset: 0.0 });
    m.insert("gradian", UnitDef { category: "angle", to_base: std::f64::consts::PI / 200.0, offset: 0.0 });
    m.insert("arcmin", UnitDef { category: "angle", to_base: std::f64::consts::PI / 10800.0, offset: 0.0 });
    m.insert("arcsec", UnitDef { category: "angle", to_base: std::f64::consts::PI / 648000.0, offset: 0.0 });
    m.insert("rev", UnitDef { category: "angle", to_base: 2.0 * std::f64::consts::PI, offset: 0.0 });
    m.insert("revolution", UnitDef { category: "angle", to_base: 2.0 * std::f64::consts::PI, offset: 0.0 });
    
    m
});

/// Convert between units
pub fn convert_unit(value: f64, from_unit: &str, to_unit: &str) -> UnitResult {
    let from = from_unit.to_lowercase();
    let to = to_unit.to_lowercase();
    
    let from_def = match UNITS.get(from.as_str()) {
        Some(d) => d,
        None => return UnitResult::error(&format!("Unknown unit: {}", from_unit)),
    };
    
    let to_def = match UNITS.get(to.as_str()) {
        Some(d) => d,
        None => return UnitResult::error(&format!("Unknown unit: {}", to_unit)),
    };
    
    if from_def.category != to_def.category {
        return UnitResult::error(&format!(
            "Cannot convert between {} ({}) and {} ({})",
            from_unit, from_def.category, to_unit, to_def.category
        ));
    }
    
    // Special handling for temperature
    if from_def.category == "temperature" {
        let kelvin = convert_to_kelvin(value, &from);
        let result = convert_from_kelvin(kelvin, &to);
        let formula = format!("{} {} = {} {}", value, from_unit, result, to_unit);
        return UnitResult::converted(result, from_unit, to_unit, &formula);
    }
    
    // Standard conversion: value -> base -> target
    let base_value = value * from_def.to_base;
    let result = base_value / to_def.to_base;
    
    let formula = format!("{} {} = {} {}", value, from_unit, result, to_unit);
    UnitResult::converted(result, from_unit, to_unit, &formula)
}

fn convert_to_kelvin(value: f64, unit: &str) -> f64 {
    match unit {
        "c" | "celsius" => value + 273.15,
        "f" | "fahrenheit" => (value - 32.0) * 5.0 / 9.0 + 273.15,
        "k" | "kelvin" => value,
        _ => value,
    }
}

fn convert_from_kelvin(kelvin: f64, unit: &str) -> f64 {
    match unit {
        "c" | "celsius" => kelvin - 273.15,
        "f" | "fahrenheit" => (kelvin - 273.15) * 9.0 / 5.0 + 32.0,
        "k" | "kelvin" => kelvin,
        _ => kelvin,
    }
}

/// Get all available units in a category
pub fn get_units_in_category(category: &str) -> Vec<String> {
    let cat = category.to_lowercase();
    UNITS
        .iter()
        .filter(|(_, def)| def.category == cat)
        .map(|(name, _)| name.to_string())
        .collect()
}

/// Get all categories
pub fn get_categories() -> Vec<String> {
    let mut categories: Vec<String> = UNITS
        .values()
        .map(|def| def.category.to_string())
        .collect();
    categories.sort();
    categories.dedup();
    categories
}

/// Batch convert a value to multiple target units
pub fn convert_to_multiple(value: f64, from_unit: &str, to_units: &[String]) -> Vec<UnitResult> {
    to_units
        .iter()
        .map(|to| convert_unit(value, from_unit, to))
        .collect()
}

/// Convert to all units in the same category
pub fn convert_to_all_in_category(value: f64, from_unit: &str) -> Vec<UnitResult> {
    let from = from_unit.to_lowercase();
    let from_def = match UNITS.get(from.as_str()) {
        Some(d) => d,
        None => return vec![UnitResult::error(&format!("Unknown unit: {}", from_unit))],
    };
    
    let category_units = get_units_in_category(from_def.category);
    category_units
        .iter()
        .filter(|u| u != &&from)
        .map(|to| convert_unit(value, from_unit, to))
        .collect()
}
