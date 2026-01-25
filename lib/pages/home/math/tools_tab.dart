import 'package:flutter/material.dart';

/// Tools tab - Unit conversion, constants, formulas reference
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
    _subTabController = TabController(length: 3, vsync: this);
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
            Tab(text: 'Constants'),
            Tab(text: 'Formulas'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _subTabController,
            children: const [
              _UnitConverter(),
              _ConstantsReference(),
              _FormulasReference(),
            ],
          ),
        ),
      ],
    );
  }
}

class _UnitConverter extends StatefulWidget {
  const _UnitConverter();

  @override
  State<_UnitConverter> createState() => _UnitConverterState();
}

class _UnitConverterState extends State<_UnitConverter> {
  String _category = 'length';
  String _fromUnit = 'meter';
  String _toUnit = 'foot';
  final _valueCtrl = TextEditingController(text: '1');
  String _result = '';
  bool _isConverting = false;

  final _categories = {
    'length': [
      'meter',
      'kilometer',
      'centimeter',
      'millimeter',
      'mile',
      'yard',
      'foot',
      'inch',
      'nautical_mile',
    ],
    'mass': [
      'kilogram',
      'gram',
      'milligram',
      'pound',
      'ounce',
      'ton',
      'metric_ton',
    ],
    'temperature': ['celsius', 'fahrenheit', 'kelvin'],
    'time': ['second', 'minute', 'hour', 'day', 'week', 'month', 'year'],
    'area': [
      'square_meter',
      'square_kilometer',
      'hectare',
      'acre',
      'square_foot',
      'square_inch',
    ],
    'volume': [
      'liter',
      'milliliter',
      'cubic_meter',
      'gallon',
      'quart',
      'pint',
      'cup',
      'fluid_ounce',
    ],
    'speed': [
      'meter_per_second',
      'kilometer_per_hour',
      'mile_per_hour',
      'knot',
    ],
    'pressure': ['pascal', 'kilopascal', 'bar', 'atmosphere', 'psi', 'torr'],
    'energy': [
      'joule',
      'kilojoule',
      'calorie',
      'kilocalorie',
      'watt_hour',
      'kilowatt_hour',
      'electronvolt',
    ],
    'force': ['newton', 'kilonewton', 'pound_force', 'dyne'],
    'angle': ['radian', 'degree', 'gradian', 'arcminute', 'arcsecond'],
    'data': ['bit', 'byte', 'kilobyte', 'megabyte', 'gigabyte', 'terabyte'],
  };

  List<String> get _units => _categories[_category] ?? [];

  @override
  void dispose() {
    _valueCtrl.dispose();
    super.dispose();
  }

  Future<void> _convert() async {
    setState(() => _isConverting = true);

    // TODO: Call Rust backend api.convert_unit
    await Future.delayed(const Duration(milliseconds: 100));

    // Placeholder conversion
    final value = double.tryParse(_valueCtrl.text) ?? 0;
    double converted;

    if (_category == 'length' && _fromUnit == 'meter' && _toUnit == 'foot') {
      converted = value * 3.28084;
    } else if (_category == 'temperature' &&
        _fromUnit == 'celsius' &&
        _toUnit == 'fahrenheit') {
      converted = value * 9 / 5 + 32;
    } else {
      converted = value; // Placeholder
    }

    setState(() {
      _result = '$value $_fromUnit = ${converted.toStringAsFixed(6)} $_toUnit';
      _isConverting = false;
    });
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
            items: _categories.keys
                .map(
                  (c) =>
                      DropdownMenuItem(value: c, child: Text(_formatUnit(c))),
                )
                .toList(),
            onChanged: (v) {
              setState(() {
                _category = v ?? 'length';
                _fromUnit = _units.first;
                _toUnit = _units.length > 1 ? _units[1] : _units.first;
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
                  value: _units.contains(_fromUnit) ? _fromUnit : _units.first,
                  decoration: const InputDecoration(
                    labelText: 'From',
                    border: OutlineInputBorder(),
                  ),
                  items: _units
                      .map(
                        (u) => DropdownMenuItem(
                          value: u,
                          child: Text(_formatUnit(u)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _fromUnit = v ?? _units.first),
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
                  value: _units.contains(_toUnit) ? _toUnit : _units.first,
                  decoration: const InputDecoration(
                    labelText: 'To',
                    border: OutlineInputBorder(),
                  ),
                  items: _units
                      .map(
                        (u) => DropdownMenuItem(
                          value: u,
                          child: Text(_formatUnit(u)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _toUnit = v ?? _units.first),
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
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
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

class _ConstantsReference extends StatelessWidget {
  const _ConstantsReference();

  static const _constants = [
    ('π (Pi)', '3.14159265358979323846', 'Ratio of circumference to diameter'),
    (
      'e (Euler\'s number)',
      '2.71828182845904523536',
      'Base of natural logarithm',
    ),
    ('φ (Golden ratio)', '1.61803398874989484820', '(1 + √5) / 2'),
    ('√2', '1.41421356237309504880', 'Pythagoras\' constant'),
    ('√3', '1.73205080756887729352', 'Theodorus\' constant'),
    ('c (Speed of light)', '299792458 m/s', 'In vacuum'),
    (
      'G (Gravitational constant)',
      '6.67430 × 10⁻¹¹ m³/(kg·s²)',
      'Newtonian constant',
    ),
    ('h (Planck constant)', '6.62607015 × 10⁻³⁴ J·s', 'Quantum of action'),
    ('ℏ (Reduced Planck)', '1.054571817 × 10⁻³⁴ J·s', 'h / (2π)'),
    (
      'e (Elementary charge)',
      '1.602176634 × 10⁻¹⁹ C',
      'Electron charge magnitude',
    ),
    ('mₑ (Electron mass)', '9.1093837015 × 10⁻³¹ kg', 'Rest mass of electron'),
    ('mₚ (Proton mass)', '1.67262192369 × 10⁻²⁷ kg', 'Rest mass of proton'),
    (
      'kB (Boltzmann constant)',
      '1.380649 × 10⁻²³ J/K',
      'Thermal energy per temperature',
    ),
    ('NA (Avogadro constant)', '6.02214076 × 10²³ mol⁻¹', 'Particles per mole'),
    ('R (Gas constant)', '8.314462618 J/(mol·K)', 'NA × kB'),
    (
      'ε₀ (Vacuum permittivity)',
      '8.8541878128 × 10⁻¹² F/m',
      'Electric constant',
    ),
    (
      'μ₀ (Vacuum permeability)',
      '1.25663706212 × 10⁻⁶ H/m',
      'Magnetic constant',
    ),
    ('g (Standard gravity)', '9.80665 m/s²', 'Earth surface acceleration'),
    ('atm (Standard atmosphere)', '101325 Pa', 'Standard pressure'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _constants.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final (name, value, description) = _constants[index];
        return ListTile(
          title: Text(name),
          subtitle: Text(description),
          trailing: SelectableText(
            value,
            style: const TextStyle(fontFamily: 'monospace'),
          ),
          onTap: () {
            // Copy to clipboard
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('$name: $value copied')));
          },
        );
      },
    );
  }
}

class _FormulasReference extends StatelessWidget {
  const _FormulasReference();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _FormulaSection(
          title: 'Algebra',
          formulas: const [
            ('Quadratic Formula', 'x = (-b ± √(b² - 4ac)) / 2a'),
            ('Completing the Square', 'x² + bx = (x + b/2)² - (b/2)²'),
            ('Difference of Squares', 'a² - b² = (a+b)(a-b)'),
            ('Sum of Cubes', 'a³ + b³ = (a+b)(a² - ab + b²)'),
            ('Binomial Theorem', '(a+b)ⁿ = Σ C(n,k) aⁿ⁻ᵏ bᵏ'),
          ],
        ),
        _FormulaSection(
          title: 'Trigonometry',
          formulas: const [
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
          formulas: const [
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
          formulas: const [
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
          formulas: const [
            ('Circle Area', 'A = πr²'),
            ('Circle Circumference', 'C = 2πr'),
            ('Sphere Volume', 'V = (4/3)πr³'),
            ('Sphere Surface Area', 'A = 4πr²'),
            ('Cone Volume', 'V = (1/3)πr²h'),
            ('Cylinder Volume', 'V = πr²h'),
            ('Triangle Area (Heron)', 'A = √(s(s-a)(s-b)(s-c)), s = (a+b+c)/2'),
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
                      child: SelectableText(
                        formula,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          color: Theme.of(context).colorScheme.primary,
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
