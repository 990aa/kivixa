import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Tools tab - Unit conversion and formulas reference
/// Note: Constants are now in the General tab
class MathToolsTab extends StatefulWidget {
  const MathToolsTab({super.key});

  @override
  State<MathToolsTab> createState() => _MathToolsTabState();
}

class _MathToolsTabState extends State<MathToolsTab>
    with SingleTickerProviderStateMixin {
  late final TabController _subTabController;

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _subTabController,
          tabs: const [
            Tab(text: 'Unit Conversion'),
            Tab(text: 'Formulas'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _subTabController,
            children: const [_UnitConverter(), _FormulasReference()],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// UNIT CONVERTER
// ============================================================================

class _UnitConverter extends StatefulWidget {
  const _UnitConverter();

  @override
  State<_UnitConverter> createState() => _UnitConverterState();
}

class _UnitConverterState extends State<_UnitConverter> {
  var _category = 'length';
  var _fromUnit = 'meter';
  var _toUnit = 'foot';
  final _valueCtrl = TextEditingController(text: '1');
  var _result = '';
  var _isConverting = false;

  // Conversion factors to base unit for each category
  static const _conversionFactors = <String, Map<String, double>>{
    'length': {
      'meter': 1,
      'kilometer': 1000,
      'centimeter': 0.01,
      'millimeter': 0.001,
      'mile': 1609.344,
      'yard': 0.9144,
      'foot': 0.3048,
      'inch': 0.0254,
      'nautical_mile': 1852,
    },
    'mass': {
      'kilogram': 1,
      'gram': 0.001,
      'milligram': 0.000001,
      'pound': 0.45359237,
      'ounce': 0.028349523125,
      'ton': 907.18474,
      'metric_ton': 1000,
    },
    'time': {
      'second': 1,
      'minute': 60,
      'hour': 3600,
      'day': 86400,
      'week': 604800,
      'month': 2629746, // average
      'year': 31556952, // average
    },
    'area': {
      'square_meter': 1,
      'square_kilometer': 1000000,
      'hectare': 10000,
      'acre': 4046.8564224,
      'square_foot': 0.09290304,
      'square_inch': 0.00064516,
    },
    'volume': {
      'liter': 1,
      'milliliter': 0.001,
      'cubic_meter': 1000,
      'gallon': 3.785411784,
      'quart': 0.946352946,
      'pint': 0.473176473,
      'cup': 0.2365882365,
      'fluid_ounce': 0.0295735295625,
    },
    'speed': {
      'meter_per_second': 1,
      'kilometer_per_hour': 0.277778,
      'mile_per_hour': 0.44704,
      'knot': 0.514444,
    },
    'pressure': {
      'pascal': 1,
      'kilopascal': 1000,
      'bar': 100000,
      'atmosphere': 101325,
      'psi': 6894.757,
      'torr': 133.322,
    },
    'energy': {
      'joule': 1,
      'kilojoule': 1000,
      'calorie': 4.184,
      'kilocalorie': 4184,
      'watt_hour': 3600,
      'kilowatt_hour': 3600000,
      'electronvolt': 1.602176634e-19,
    },
    'force': {
      'newton': 1,
      'kilonewton': 1000,
      'pound_force': 4.4482216152605,
      'dyne': 0.00001,
    },
    'angle': {
      'radian': 1,
      'degree': 0.017453292519943,
      'gradian': 0.015707963267949,
      'arcminute': 0.00029088820866572,
      'arcsecond': 0.0000048481368110954,
    },
    'data': {
      'bit': 1,
      'byte': 8,
      'kilobyte': 8192,
      'megabyte': 8388608,
      'gigabyte': 8589934592,
      'terabyte': 8796093022208,
    },
  };

  List<String> get _units => _conversionFactors[_category]?.keys.toList() ?? [];

  @override
  void dispose() {
    _valueCtrl.dispose();
    super.dispose();
  }

  Future<void> _convert() async {
    setState(() {
      _isConverting = true;
      _result = '';
    });

    try {
      final value = double.parse(_valueCtrl.text);
      double converted;

      if (_category == 'temperature') {
        // Special handling for temperature
        converted = _convertTemperature(value, _fromUnit, _toUnit);
      } else {
        // Standard conversion via base unit
        final factors = _conversionFactors[_category];
        if (factors == null) throw Exception('Unknown category');

        final fromFactor = factors[_fromUnit];
        final toFactor = factors[_toUnit];
        if (fromFactor == null || toFactor == null)
          throw Exception('Unknown unit');

        // Convert to base unit then to target unit
        converted = value * fromFactor / toFactor;
      }

      setState(() {
        _result =
            '$value ${_formatUnit(_fromUnit)} = ${_formatNumber(converted)} ${_formatUnit(_toUnit)}';
        _isConverting = false;
      });
    } catch (e) {
      setState(() {
        _result = 'Error: ${e.toString().replaceAll('Exception: ', '')}';
        _isConverting = false;
      });
    }
  }

  double _convertTemperature(double value, String from, String to) {
    // Convert to Celsius first
    double celsius;
    switch (from) {
      case 'celsius':
        celsius = value;
      case 'fahrenheit':
        celsius = (value - 32) * 5 / 9;
      case 'kelvin':
        celsius = value - 273.15;
      default:
        throw Exception('Unknown temperature unit');
    }

    // Convert from Celsius to target
    switch (to) {
      case 'celsius':
        return celsius;
      case 'fahrenheit':
        return celsius * 9 / 5 + 32;
      case 'kelvin':
        return celsius + 273.15;
      default:
        throw Exception('Unknown temperature unit');
    }
  }

  String _formatNumber(double n) {
    if (n.isNaN) return 'undefined';
    if (n.isInfinite) return n > 0 ? '∞' : '-∞';

    // Use scientific notation for very large or small numbers
    if (n.abs() > 1e10 || (n.abs() < 1e-6 && n != 0)) {
      return n.toStringAsExponential(6);
    }

    // Round to reasonable precision
    if (n == n.toInt().toDouble()) return n.toInt().toString();
    return n
        .toStringAsFixed(8)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  String _formatUnit(String unit) {
    return unit
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final categories = [..._conversionFactors.keys, 'temperature'];
    final units = _category == 'temperature'
        ? ['celsius', 'fahrenheit', 'kelvin']
        : _units;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Unit Converter',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: _category,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
            items: categories
                .map(
                  (c) =>
                      DropdownMenuItem(value: c, child: Text(_formatUnit(c))),
                )
                .toList(),
            onChanged: (v) {
              setState(() {
                _category = v ?? 'length';
                final newUnits = _category == 'temperature'
                    ? ['celsius', 'fahrenheit', 'kelvin']
                    : (_conversionFactors[_category]?.keys.toList() ?? []);
                _fromUnit = newUnits.isNotEmpty ? newUnits.first : '';
                _toUnit = newUnits.length > 1
                    ? newUnits[1]
                    : (newUnits.isNotEmpty ? newUnits.first : '');
                _result = '';
              });
            },
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _valueCtrl,
            decoration: const InputDecoration(
              labelText: 'Value',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: units.contains(_fromUnit)
                      ? _fromUnit
                      : (units.isNotEmpty ? units.first : null),
                  decoration: const InputDecoration(
                    labelText: 'From',
                    border: OutlineInputBorder(),
                  ),
                  items: units
                      .map(
                        (u) => DropdownMenuItem(
                          value: u,
                          child: Text(_formatUnit(u)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _fromUnit = v ?? units.first),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: IconButton(
                  icon: const Icon(Icons.swap_horiz),
                  onPressed: () {
                    setState(() {
                      final temp = _fromUnit;
                      _fromUnit = _toUnit;
                      _toUnit = temp;
                    });
                  },
                ),
              ),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: units.contains(_toUnit)
                      ? _toUnit
                      : (units.isNotEmpty ? units.first : null),
                  decoration: const InputDecoration(
                    labelText: 'To',
                    border: OutlineInputBorder(),
                  ),
                  items: units
                      .map(
                        (u) => DropdownMenuItem(
                          value: u,
                          child: Text(_formatUnit(u)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _toUnit = v ?? units.first),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Center(
            child: FilledButton.icon(
              onPressed: _isConverting ? null : _convert,
              icon: _isConverting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.swap_vert),
              label: const Text('Convert'),
            ),
          ),
          const SizedBox(height: 16),

          if (_result.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _result.startsWith('Error')
                    ? Theme.of(
                        context,
                      ).colorScheme.errorContainer.withOpacity(0.3)
                    : Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                _result,
                style: const TextStyle(fontSize: 18, fontFamily: 'monospace'),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// FORMULAS REFERENCE
// ============================================================================

class _FormulasReference extends StatelessWidget {
  const _FormulasReference();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _FormulaSection(
          title: 'Algebra',
          formulas: [
            ('Quadratic Formula', 'x = (-b ± √(b² - 4ac)) / 2a'),
            ('Completing the Square', 'x² + bx = (x + b/2)² - (b/2)²'),
            ('Difference of Squares', 'a² - b² = (a+b)(a-b)'),
            ('Sum of Cubes', 'a³ + b³ = (a+b)(a² - ab + b²)'),
            ('Binomial Theorem', '(a+b)ⁿ = Σ C(n,k) aⁿ⁻ᵏ bᵏ'),
          ],
        ),
        _FormulaSection(
          title: 'Trigonometry',
          formulas: [
            ('Pythagorean Identity', 'sin²θ + cos²θ = 1'),
            ('Sum/Difference (sin)', 'sin(α ± β) = sinα cosβ ± cosα sinβ'),
            ('Sum/Difference (cos)', 'cos(α ± β) = cosα cosβ ∓ sinα sinβ'),
            ('Double Angle (sin)', 'sin(2θ) = 2 sinθ cosθ'),
            ('Double Angle (cos)', 'cos(2θ) = cos²θ - sin²θ'),
            ('Law of Cosines', 'c² = a² + b² - 2ab cosC'),
            ('Law of Sines', 'a/sinA = b/sinB = c/sinC'),
          ],
        ),
        _FormulaSection(
          title: 'Calculus',
          formulas: [
            ('Power Rule', 'd/dx[xⁿ] = n xⁿ⁻¹'),
            ('Product Rule', 'd/dx[fg] = f\'g + fg\''),
            ('Quotient Rule', 'd/dx[f/g] = (f\'g - fg\') / g²'),
            ('Chain Rule', 'd/dx[f(g(x))] = f\'(g(x)) · g\'(x)'),
            ('Integration by Parts', '∫u dv = uv - ∫v du'),
            ('Taylor Series', 'f(x) = Σ f⁽ⁿ⁾(a)/n! · (x-a)ⁿ'),
          ],
        ),
        _FormulaSection(
          title: 'Statistics',
          formulas: [
            ('Mean', 'μ = Σxᵢ / n'),
            ('Variance', 'σ² = Σ(xᵢ - μ)² / n'),
            ('Standard Deviation', 'σ = √(Σ(xᵢ - μ)² / n)'),
            ('Normal Distribution', 'f(x) = (1/σ√2π) e^(-(x-μ)²/2σ²)'),
            ('z-score', 'z = (x - μ) / σ'),
            ('Correlation', 'r = Σ(xᵢ-x̄)(yᵢ-ȳ) / √(Σ(xᵢ-x̄)² Σ(yᵢ-ȳ)²)'),
          ],
        ),
        _FormulaSection(
          title: 'Geometry',
          formulas: [
            ('Circle Area', 'A = πr²'),
            ('Circle Circumference', 'C = 2πr'),
            ('Sphere Volume', 'V = (4/3)πr³'),
            ('Sphere Surface Area', 'A = 4πr²'),
            ('Cone Volume', 'V = (1/3)πr²h'),
            ('Cylinder Volume', 'V = πr²h'),
            ('Triangle Area (Heron)', 'A = √(s(s-a)(s-b)(s-c)), s = (a+b+c)/2'),
          ],
        ),
        _FormulaSection(
          title: 'Linear Algebra',
          formulas: [
            ('Matrix Multiplication', '(AB)ᵢⱼ = Σ Aᵢₖ Bₖⱼ'),
            ('Transpose', '(Aᵀ)ᵢⱼ = Aⱼᵢ'),
            ('Determinant 2×2', 'det(A) = ad - bc'),
            ('Inverse 2×2', 'A⁻¹ = (1/det(A)) [[d,-b],[-c,a]]'),
            ('Eigenvalue', 'det(A - λI) = 0'),
          ],
        ),
      ],
    );
  }
}

class _FormulaSection extends StatelessWidget {
  final String title;
  final List<(String, String)> formulas;

  const _FormulaSection({required this.title, required this.formulas});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...formulas.map((f) {
              final (name, formula) = f;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 180,
                      child: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: formula));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Copied: $formula'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        child: SelectableText(
                          formula,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
