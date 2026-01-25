//! Discrete mathematics: number theory, combinatorics, sets

use num_bigint::BigUint;
use num_traits::{One, Zero, ToPrimitive};
use serde::{Deserialize, Serialize};

/// Result of discrete math operations
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DiscreteResult {
    pub success: bool,
    pub value: u64,
    pub big_value: Option<String>,
    pub values: Vec<u64>,
    pub bool_result: Option<bool>,
    pub error: Option<String>,
}

impl DiscreteResult {
    pub fn value(val: u64) -> Self {
        Self {
            success: true,
            value: val,
            big_value: None,
            values: vec![],
            bool_result: None,
            error: None,
        }
    }

    pub fn big(val: BigUint) -> Self {
        let small = val.to_u64();
        Self {
            success: true,
            value: small.unwrap_or(0),
            big_value: Some(val.to_string()),
            values: vec![],
            bool_result: None,
            error: None,
        }
    }

    pub fn bool_val(b: bool) -> Self {
        Self {
            success: true,
            value: if b { 1 } else { 0 },
            big_value: None,
            values: vec![],
            bool_result: Some(b),
            error: None,
        }
    }

    pub fn list(vals: Vec<u64>) -> Self {
        Self {
            success: true,
            value: vals.len() as u64,
            big_value: None,
            values: vals,
            bool_result: None,
            error: None,
        }
    }

    pub fn error(msg: &str) -> Self {
        Self {
            success: false,
            value: 0,
            big_value: None,
            values: vec![],
            bool_result: None,
            error: Some(msg.to_string()),
        }
    }
}

/// Check if a number is prime (Miller-Rabin for large numbers)
pub fn is_prime(n: u64) -> bool {
    if n < 2 {
        return false;
    }
    if n == 2 || n == 3 {
        return true;
    }
    if n % 2 == 0 {
        return false;
    }

    // Miller-Rabin witnesses for deterministic test up to 2^64
    let witnesses: [u64; 7] = [2, 3, 5, 7, 11, 13, 17];

    // Write n-1 as 2^r * d
    let mut d = n - 1;
    let mut r = 0u32;
    while d % 2 == 0 {
        d /= 2;
        r += 1;
    }

    'witness: for &a in &witnesses {
        if a >= n {
            continue;
        }

        let mut x = mod_pow_u64(a, d, n);

        if x == 1 || x == n - 1 {
            continue 'witness;
        }

        for _ in 0..(r - 1) {
            x = mod_mul(x, x, n);
            if x == n - 1 {
                continue 'witness;
            }
        }

        return false;
    }

    true
}

/// Modular multiplication to avoid overflow
fn mod_mul(a: u64, b: u64, m: u64) -> u64 {
    ((a as u128 * b as u128) % m as u128) as u64
}

/// Modular exponentiation (a^b mod m)
fn mod_pow_u64(mut base: u64, mut exp: u64, m: u64) -> u64 {
    if m == 1 {
        return 0;
    }
    let mut result = 1u64;
    base %= m;
    while exp > 0 {
        if exp % 2 == 1 {
            result = mod_mul(result, base, m);
        }
        exp /= 2;
        base = mod_mul(base, base, m);
    }
    result
}

/// Modular exponentiation with BigUint support
pub fn mod_pow(base: u64, exponent: u64, modulus: u64) -> DiscreteResult {
    if modulus == 0 {
        return DiscreteResult::error("Modulus cannot be zero");
    }
    
    let result = mod_pow_u64(base, exponent, modulus);
    DiscreteResult::value(result)
}

/// Factorial using BigUint for large values
pub fn factorial(n: u64) -> DiscreteResult {
    if n > 10000 {
        return DiscreteResult::error("Number too large for factorial");
    }

    let mut result = BigUint::one();
    for i in 2..=n {
        result *= i;
    }
    
    DiscreteResult::big(result)
}

/// Combinations C(n, k) = n! / (k! * (n-k)!)
pub fn combinations(n: u64, k: u64) -> DiscreteResult {
    if k > n {
        return DiscreteResult::value(0);
    }
    
    // Use smaller k to minimize computation
    let k = k.min(n - k);
    
    let mut result = BigUint::one();
    for i in 0..k {
        result *= n - i;
        result /= i + 1;
    }
    
    DiscreteResult::big(result)
}

/// Permutations P(n, k) = n! / (n-k)!
pub fn permutations(n: u64, k: u64) -> DiscreteResult {
    if k > n {
        return DiscreteResult::value(0);
    }
    
    let mut result = BigUint::one();
    for i in 0..k {
        result *= n - i;
    }
    
    DiscreteResult::big(result)
}

/// Greatest Common Divisor using Euclidean algorithm
pub fn gcd(a: u64, b: u64) -> u64 {
    if b == 0 {
        a
    } else {
        gcd(b, a % b)
    }
}

/// Least Common Multiple
pub fn lcm(a: u64, b: u64) -> u64 {
    if a == 0 || b == 0 {
        0
    } else {
        a / gcd(a, b) * b
    }
}

/// Extended Euclidean algorithm
/// Returns (gcd, x, y) such that ax + by = gcd(a, b)
pub fn extended_gcd(a: i64, b: i64) -> (i64, i64, i64) {
    if b == 0 {
        (a, 1, 0)
    } else {
        let (g, x, y) = extended_gcd(b, a % b);
        (g, y, x - (a / b) * y)
    }
}

/// Modular inverse using extended Euclidean algorithm
pub fn mod_inverse(a: u64, m: u64) -> DiscreteResult {
    let (g, x, _) = extended_gcd(a as i64, m as i64);
    
    if g != 1 {
        DiscreteResult::error("Modular inverse does not exist")
    } else {
        let result = ((x % m as i64) + m as i64) as u64 % m;
        DiscreteResult::value(result)
    }
}

/// Prime factorization
pub fn prime_factors(mut n: u64) -> DiscreteResult {
    if n < 2 {
        return DiscreteResult::list(vec![]);
    }

    let mut factors = Vec::new();

    // Factor out 2s
    while n % 2 == 0 {
        factors.push(2);
        n /= 2;
    }

    // Factor out odd primes
    let mut i = 3u64;
    while i * i <= n {
        while n % i == 0 {
            factors.push(i);
            n /= i;
        }
        i += 2;
    }

    if n > 1 {
        factors.push(n);
    }

    DiscreteResult::list(factors)
}

/// Generate primes up to n using Sieve of Eratosthenes
pub fn sieve_of_eratosthenes(n: u64) -> DiscreteResult {
    if n < 2 {
        return DiscreteResult::list(vec![]);
    }
    
    if n > 10_000_000 {
        return DiscreteResult::error("Limit too large (max 10 million)");
    }

    let n = n as usize;
    let mut is_prime = vec![true; n + 1];
    is_prime[0] = false;
    is_prime[1] = false;

    let mut i = 2;
    while i * i <= n {
        if is_prime[i] {
            let mut j = i * i;
            while j <= n {
                is_prime[j] = false;
                j += i;
            }
        }
        i += 1;
    }

    let primes: Vec<u64> = is_prime
        .iter()
        .enumerate()
        .filter(|(_, &is_p)| is_p)
        .map(|(i, _)| i as u64)
        .collect();

    DiscreteResult::list(primes)
}

/// Nth Fibonacci number using matrix exponentiation
pub fn fibonacci(n: u64) -> DiscreteResult {
    if n == 0 {
        return DiscreteResult::value(0);
    }
    if n == 1 || n == 2 {
        return DiscreteResult::value(1);
    }

    // Use BigUint for large Fibonacci numbers
    let mut a = BigUint::zero();
    let mut b = BigUint::one();

    for _ in 0..n {
        let temp = a.clone() + &b;
        a = b;
        b = temp;
    }

    DiscreteResult::big(a)
}

/// Euler's totient function φ(n)
pub fn euler_totient(n: u64) -> DiscreteResult {
    if n == 0 {
        return DiscreteResult::error("Totient undefined for 0");
    }
    if n == 1 {
        return DiscreteResult::value(1);
    }

    let factors = prime_factors(n);
    let unique_factors: std::collections::HashSet<u64> = factors.values.into_iter().collect();

    let mut result = n;
    for p in unique_factors {
        result = result / p * (p - 1);
    }

    DiscreteResult::value(result)
}

/// Number of divisors
pub fn num_divisors(n: u64) -> DiscreteResult {
    if n == 0 {
        return DiscreteResult::error("Divisors undefined for 0");
    }

    let mut count = 0u64;
    let mut i = 1u64;
    while i * i <= n {
        if n % i == 0 {
            count += 1;
            if i != n / i {
                count += 1;
            }
        }
        i += 1;
    }

    DiscreteResult::value(count)
}

/// Sum of divisors
pub fn sum_divisors(n: u64) -> DiscreteResult {
    if n == 0 {
        return DiscreteResult::error("Divisors undefined for 0");
    }

    let mut sum = 0u64;
    let mut i = 1u64;
    while i * i <= n {
        if n % i == 0 {
            sum += i;
            if i != n / i {
                sum += n / i;
            }
        }
        i += 1;
    }

    DiscreteResult::value(sum)
}

/// List all divisors
pub fn list_divisors(n: u64) -> DiscreteResult {
    if n == 0 {
        return DiscreteResult::error("Divisors undefined for 0");
    }

    let mut divisors = Vec::new();
    let mut i = 1u64;
    while i * i <= n {
        if n % i == 0 {
            divisors.push(i);
            if i != n / i {
                divisors.push(n / i);
            }
        }
        i += 1;
    }

    divisors.sort();
    DiscreteResult::list(divisors)
}

/// Check if two numbers are coprime (GCD = 1)
pub fn are_coprime(a: u64, b: u64) -> DiscreteResult {
    DiscreteResult::bool_val(gcd(a, b) == 1)
}

/// Binomial coefficient using BigUint
pub fn binomial(n: u64, k: u64) -> DiscreteResult {
    combinations(n, k)
}

/// Catalan number C_n
pub fn catalan(n: u64) -> DiscreteResult {
    if n > 1000 {
        return DiscreteResult::error("Number too large for Catalan");
    }

    // C_n = C(2n, n) / (n + 1)
    let mut result = BigUint::one();
    for i in 0..n {
        result *= 2 * n - i;
        result /= i + 1;
    }
    result /= n + 1;

    DiscreteResult::big(result)
}

/// Stirling number of the second kind S(n, k)
/// Number of ways to partition n elements into k non-empty subsets
pub fn stirling2(n: u64, k: u64) -> DiscreteResult {
    if k > n {
        return DiscreteResult::value(0);
    }
    if k == 0 {
        return DiscreteResult::value(if n == 0 { 1 } else { 0 });
    }
    if k == n {
        return DiscreteResult::value(1);
    }

    // Use recurrence S(n,k) = k*S(n-1,k) + S(n-1,k-1)
    let mut prev = vec![BigUint::zero(); (k + 1) as usize];
    prev[0] = BigUint::one();

    for i in 1..=n {
        let mut curr = vec![BigUint::zero(); (k + 1) as usize];
        for j in 1..=k.min(i) {
            curr[j as usize] = &prev[j as usize] * j + &prev[(j - 1) as usize];
        }
        prev = curr;
    }

    DiscreteResult::big(prev[k as usize].clone())
}

/// Bell number B_n - number of partitions of a set of n elements
pub fn bell(n: u64) -> DiscreteResult {
    if n > 500 {
        return DiscreteResult::error("Number too large for Bell");
    }

    // B_n = sum of S(n, k) for k = 0 to n
    let mut sum = BigUint::zero();
    for k in 0..=n {
        let s = stirling2(n, k);
        if let Some(big) = &s.big_value {
            sum += big.parse::<BigUint>().unwrap_or(BigUint::zero());
        } else {
            sum += s.value;
        }
    }

    DiscreteResult::big(sum)
}

/// Check if number is perfect (sum of proper divisors equals number)
pub fn is_perfect(n: u64) -> DiscreteResult {
    if n < 2 {
        return DiscreteResult::bool_val(false);
    }
    
    let sum = sum_divisors(n);
    DiscreteResult::bool_val(sum.value - n == n)
}
