# Kivixa Math Module Details

The **Math Module** in Kivixa offers an extensive, high-performance toolkit powered by a Rust backend isolated from the AI inference engine. This ensures all mathematical operations—ranging from basic arithmetic to advanced calculus and statistics—are executed blazingly fast with robust precision. 

## Features

### 1. Basic Calculator
A fully-featured scientific calculator capable of parsing complex text expressions.
- **Support for Parentheses & Order of Operations:** Standard PEMDAS/BODMAS.
- **Trigonometric Functions:** `sin`, `cos`, `tan`, `asin`, `acos`, `atan`, `sinh`, `cosh`, `tanh`.
- **Logarithms & Exponents:** `ln`, `log`, `exp`, `sqrt`, `cbrt`, and power `^` operator.
- **Constants:** `pi` (π) and `e`.
- **Example:** `sin(pi/2) + ln(e^2) * 4` evaluates precisely to `9`.

### 2. Complex Numbers
Perform operations on numbers with real and imaginary parts.
- **Supported Operations:** Addition, Subtraction, Multiplication, Division, Conjugate, Magnitude.
- **Polar Conversion:** Convert standard $a + bi$ form into polar coordinates (Magnitude & Angle in Degrees or Radians).

### 3. Matrix & Linear Algebra
Extensive toolkit for handling $N \times M$ matrices.
- **Operations:** Addition, Subtraction, Multiplication.
- **Advanced Transformations:** 
  - Transpose
  - Determinant (for square matrices)
  - Inverse (for non-singular square matrices)
  - LU Decomposition (Lower-Upper)

### 4. Calculus Engine
A powerful numerical and symbolic calculus suite capable of handling complex multivariable expressions.
- **Differentiation:**
  - Standard Derivative: Compute $f^{(n)}(x)$ at a specific point for any arbitrary order $n$.
  - Symbolic Derivative: Retrieve the analytical algebraic derivative of an expression (e.g. $x^2 \to 2x$).
  - Partial Derivative: Compute $\frac{\partial^n f}{\partial x^n}$ with respect to a chosen variable for any arbitrary order $n$.
  - Mixed Partial Derivatives and Gradients ($\nabla f$).
- **Integration:** 
  - Definite integrals (Single, Double, and Triple).
  - Symbolic integration using an analytical rule-based AST engine.
- **Limits & Roots:** 
  - Compute limits ($x \to c$).
  - Find real roots/zeros of $f(x)=0$ within an interval using Newton-Raphson.

### 5. Statistics & Probability
Comprehensive support for data analysis and continuous/discrete probability distributions.
- **Descriptive Statistics:** Mean, Median, Mode, Variance, Standard Deviation, IQR, Skewness, Kurtosis.
- **Hypothesis Testing:** One/Two-Sample T-Tests, Z-Tests, ANOVA, Chi-Squared, F-Test (Variances), Mann-Whitney U Test, Binomial Test, and Durbin-Watson Test (Autocorrelation).
- **Regression:** Linear and Polynomial regression models with $R^2$ scores.
- **Distributions:**
  - **Continuous:** Normal, Log-Normal, Laplace, Logistic, Pareto, Rayleigh, Uniform, Exponential, Student's t, Chi-Square, Beta, Gamma, Cauchy, F-Distribution.
  - **Discrete:** Bernoulli, Binomial, Poisson, Hypergeometric, Geometric, Uniform.
  - *Functionality:* Compute the Probability Density Function (PDF), Probability Mass Function (PMF), Cumulative Distribution Function (CDF), Mean, and Variance for any of the above.

### 6. Discrete Math & Sequences
Robust tools for discrete structures, sequences, and number theory.
- **Modular Arithmetic:** Addition, subtraction, multiplication, exponentiation, and multiplicative inverses over a modulus.
- **Primes & Factors:** Prime checking, Sieve of Eratosthenes generation, GCD/LCM, and prime factorization.
- **Combinatorics:** Permutations, Combinations, and factorials.
- **Sequence Generators:** 
  - **Classical:** Arithmetic, Geometric, Triangular, Polygonal.
  - **Number-Theoretic:** Mersenne, Lucas, Pell.
  - **Combinatorial:** Stirling Numbers of the 1st kind, Partition numbers.
  - **Analytical:** Harmonic, Bernoulli, Euler numbers.

### 7. Unit Conversion
Convert physical quantities effortlessly.
- **Length:** meters, kilometers, centimeters, millimeters, miles, yards, feet, inches.
- **Mass:** kilograms, grams, milligrams, pounds, ounces.
- **Temperature:** Celsius, Fahrenheit, Kelvin.
- **Volume & Area:** liters, gallons, sq meters, acres.
- **Time & Speed:** seconds, minutes, hours, m/s, km/h, mph.

### 8. Graphing & Visualization
Input an arbitrary function $f(x)$ and plot it instantly.
- **Dynamic Domain:** Adjust $X_{min}$ and $X_{max}$.
- **Extrema & Zeros Detection:** The engine automatically highlights local minima, local maxima, and roots (zero-crossings) directly on the interactive chart.

---

*Note: All heavy computational lifting is safely offloaded to `native_math` using Rust concurrency to prevent blocking the Flutter UI thread.*
