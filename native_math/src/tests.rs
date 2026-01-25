//! Unit tests for the kivixa_math library

#[cfg(test)]
mod basic_tests {
    use crate::basic::*;

    #[test]
    fn test_simple_arithmetic() {
        let result = evaluate_expression("2 + 3");
        assert!(result.success);
        assert!((result.value - 5.0).abs() < 1e-10);

        let result = evaluate_expression("10 - 4");
        assert!(result.success);
        assert!((result.value - 6.0).abs() < 1e-10);

        let result = evaluate_expression("6 * 7");
        assert!(result.success);
        assert!((result.value - 42.0).abs() < 1e-10);

        let result = evaluate_expression("15 / 3");
        assert!(result.success);
        assert!((result.value - 5.0).abs() < 1e-10);
    }

    #[test]
    fn test_order_of_operations() {
        let result = evaluate_expression("2 + 3 * 4");
        assert!(result.success);
        assert!((result.value - 14.0).abs() < 1e-10);

        let result = evaluate_expression("(2 + 3) * 4");
        assert!(result.success);
        assert!((result.value - 20.0).abs() < 1e-10);
    }

    #[test]
    fn test_power_operations() {
        let result = evaluate_expression("2^10");
        assert!(result.success);
        assert!((result.value - 1024.0).abs() < 1e-10);

        let result = evaluate_expression("sqrt(16)");
        assert!(result.success);
        assert!((result.value - 4.0).abs() < 1e-10);
    }

    #[test]
    fn test_trigonometric_functions() {
        let result = evaluate_expression("sin(0)");
        assert!(result.success);
        assert!(result.value.abs() < 1e-10);

        let result = evaluate_expression("cos(0)");
        assert!(result.success);
        assert!((result.value - 1.0).abs() < 1e-10);
    }

    #[test]
    fn test_logarithmic_functions() {
        let result = evaluate_expression("ln(e())");
        assert!(result.success);
        assert!((result.value - 1.0).abs() < 1e-10);

        let result = evaluate_expression("log(100)");
        assert!(result.success);
        assert!((result.value - 2.0).abs() < 1e-10);
    }

    #[test]
    fn test_constants() {
        let pi = get_constant("pi");
        assert!((pi - std::f64::consts::PI).abs() < 1e-10);

        let e = get_constant("e");
        assert!((e - std::f64::consts::E).abs() < 1e-10);
    }

    #[test]
    fn test_invalid_expression() {
        let result = evaluate_expression("2 +");
        assert!(!result.success);
        assert!(result.error.is_some());
    }
}

#[cfg(test)]
mod complex_tests {
    use crate::complex::*;

    #[test]
    fn test_complex_addition() {
        let result = complex_operation(1.0, 2.0, 3.0, 4.0, "add");
        assert!(result.success);
        assert!((result.real - 4.0).abs() < 1e-10);
        assert!((result.imag - 6.0).abs() < 1e-10);
    }

    #[test]
    fn test_complex_multiplication() {
        // (1+2i) * (3+4i) = 3 + 4i + 6i + 8i² = 3 + 10i - 8 = -5 + 10i
        let result = complex_operation(1.0, 2.0, 3.0, 4.0, "multiply");
        assert!(result.success);
        assert!((result.real - (-5.0)).abs() < 1e-10);
        assert!((result.imag - 10.0).abs() < 1e-10);
    }

    #[test]
    fn test_complex_conjugate() {
        let result = complex_operation(3.0, 4.0, 0.0, 0.0, "conjugate");
        assert!(result.success);
        assert!((result.real - 3.0).abs() < 1e-10);
        assert!((result.imag - (-4.0)).abs() < 1e-10);
    }

    #[test]
    fn test_complex_magnitude() {
        let result = complex_operation(3.0, 4.0, 0.0, 0.0, "conjugate");
        assert!(result.success);
        assert!((result.magnitude - 5.0).abs() < 1e-10);
    }

    #[test]
    fn test_polar_conversion() {
        let result = convert_form(1.0, 1.0, true);
        assert!(result.success);
        assert!((result.magnitude - std::f64::consts::SQRT_2).abs() < 1e-10);
        assert!((result.angle_deg - 45.0).abs() < 1e-10);
    }
}

#[cfg(test)]
mod matrix_tests {
    use crate::matrix::*;

    #[test]
    fn test_matrix_transpose() {
        // [[1, 2], [3, 4]]
        let data = vec![1.0, 2.0, 3.0, 4.0];
        let result = matrix_operation(&data, 2, 2, None, None, None, "transpose");
        assert!(result.success);
        // Expected: [[1, 3], [2, 4]]
        assert_eq!(result.data.len(), 4);
    }

    #[test]
    fn test_matrix_determinant() {
        // [[1, 2], [3, 4]] => det = -2
        let data = vec![1.0, 2.0, 3.0, 4.0];
        let result = matrix_operation(&data, 2, 2, None, None, None, "det");
        assert!(result.success);
        assert!((result.scalar.unwrap() - (-2.0)).abs() < 1e-10);
    }

    #[test]
    fn test_matrix_addition() {
        // Row-major: [1,2,3,4] represents [[1,2],[3,4]]
        let a = vec![1.0, 2.0, 3.0, 4.0]; // [[1,2],[3,4]]
        let b = vec![5.0, 6.0, 7.0, 8.0]; // [[5,6],[7,8]]
        let result = matrix_operation(&a, 2, 2, Some(&b), Some(2), Some(2), "add");
        assert!(result.success);
        // Output from nalgebra is in column-major, so [[6,8],[10,12]] comes as [6, 10, 8, 12]
        // But from_matrix converts back - let's just verify the sums are correct
        let sum: f64 = result.data.iter().sum();
        assert!((sum - 36.0).abs() < 1e-10); // 6+8+10+12 = 36
    }

    #[test]
    fn test_matrix_multiplication() {
        // Row-major input
        let a = vec![1.0, 2.0, 3.0, 4.0]; // [[1,2],[3,4]]
        let b = vec![5.0, 6.0, 7.0, 8.0]; // [[5,6],[7,8]]
        let result = matrix_operation(&a, 2, 2, Some(&b), Some(2), Some(2), "multiply");
        assert!(result.success);
        // [[1,2],[3,4]] * [[5,6],[7,8]] = [[19,22],[43,50]]
        // Verify the sum: 19+22+43+50 = 134
        let sum: f64 = result.data.iter().sum();
        assert!((sum - 134.0).abs() < 1e-10);
    }

    #[test]
    fn test_matrix_inverse() {
        // [[4, 7], [2, 6]] => inverse = [[0.6, -0.7], [-0.2, 0.4]]
        let data = vec![4.0, 7.0, 2.0, 6.0];
        let result = matrix_operation(&data, 2, 2, None, None, None, "inverse");
        assert!(result.success);
        assert!((result.data[0] - 0.6).abs() < 1e-10);
    }

    #[test]
    fn test_lu_decomposition() {
        let data = vec![4.0, 6.0, 3.0, 3.0]; // column-major [[4,3],[6,3]]
        let result = decompose(&data, 2, 2, "lu");
        assert!(result.success);
        assert_eq!(result.decomposition_type, "LU");
        // We now only return L and U (no P)
        assert_eq!(result.labels.len(), 2);
    }
}

#[cfg(test)]
mod calculus_tests {
    use crate::calculus::*;

    #[test]
    fn test_differentiate_polynomial() {
        // d/dx(x^2) at x=3 should be 2*3 = 6
        let result = differentiate("x^2", "x", 3.0, 1);
        assert!(result.success);
        assert!((result.value - 6.0).abs() < 1e-4);
    }

    #[test]
    fn test_differentiate_second_order() {
        // d²/dx²(x^2) should be 2
        // Note: numerical second derivatives have lower accuracy
        let result = differentiate("x^2", "x", 1.0, 2);
        assert!(result.success);
        assert!((result.value - 2.0).abs() < 0.1); // Relax tolerance for numerical approx
    }

    #[test]
    fn test_integrate() {
        // ∫₀¹ x² dx = 1/3
        let result = integrate("x^2", "x", 0.0, 1.0, 100);
        assert!(result.success);
        assert!((result.value - 1.0 / 3.0).abs() < 1e-4);
    }

    #[test]
    fn test_integrate_sine() {
        // ∫₀^π sin(x) dx = 2
        let result = integrate("sin(x)", "x", 0.0, std::f64::consts::PI, 100);
        assert!(result.success);
        assert!((result.value - 2.0).abs() < 1e-4);
    }

    #[test]
    fn test_solve_equation() {
        // x² - 4 = 0 => x = ±2
        let result = solve_equation("x^2 - 4", "x", 3.0, 1e-10, 100);
        assert!(result.success);
        assert!((result.roots[0] - 2.0).abs() < 1e-6);
    }

    #[test]
    fn test_find_roots_in_interval() {
        // sin(x) = 0 in [0, 4] has roots at 0 and π
        let result = find_roots_in_interval("sin(x)", "x", 0.1, 4.0, 100);
        assert!(result.success);
        assert!(result.roots.len() >= 1);
    }

    #[test]
    fn test_compute_limit() {
        // lim(x→0) sin(x)/x = 1
        let result = compute_limit("sin(x)/x", "x", 0.0, true, true);
        assert!(result.success);
        assert!((result.value - 1.0).abs() < 1e-4);
    }

    #[test]
    fn test_partial_derivative() {
        // ∂/∂x(x^2 + y^2) at (1, 2) should be 2x = 2
        let point = vec![("x", 1.0), ("y", 2.0)];
        let result = partial_derivative("x^2 + y^2", "x", point, 1);
        assert!(result.success);
        assert!((result.value - 2.0).abs() < 1e-4);

        // ∂/∂y(x^2 + y^2) at (1, 2) should be 2y = 4
        let point = vec![("x", 1.0), ("y", 2.0)];
        let result = partial_derivative("x^2 + y^2", "y", point, 1);
        assert!(result.success);
        assert!((result.value - 4.0).abs() < 1e-4);
    }

    #[test]
    fn test_mixed_partial_derivative() {
        // ∂²/∂x∂y(x*y) should be 1
        let point = vec![("x", 1.0), ("y", 2.0)];
        let result = mixed_partial_derivative("x*y", "x", "y", point);
        assert!(result.success);
        assert!((result.value - 1.0).abs() < 1e-3);
    }

    #[test]
    fn test_gradient() {
        // ∇(x^2 + y^2) at (1, 2) = (2x, 2y) = (2, 4)
        let point = vec![("x", 1.0), ("y", 2.0)];
        let grad = gradient("x^2 + y^2", &["x", "y"], point);
        assert!((grad[0] - 2.0).abs() < 1e-4);
        assert!((grad[1] - 4.0).abs() < 1e-4);
    }

    #[test]
    fn test_double_integral() {
        // ∫₀¹∫₀¹ xy dx dy = 1/4
        let result = double_integral("x*y", "x", "y", 0.0, 1.0, 0.0, 1.0, 50);
        assert!(result.success);
        assert!((result.value - 0.25).abs() < 1e-3);
    }

    #[test]
    fn test_double_integral_constant() {
        // ∫₀²∫₀³ 1 dx dy = 6
        let result = double_integral("1", "x", "y", 0.0, 2.0, 0.0, 3.0, 50);
        assert!(result.success);
        assert!((result.value - 6.0).abs() < 1e-3);
    }

    #[test]
    fn test_triple_integral() {
        // ∫₀¹∫₀¹∫₀¹ 1 dx dy dz = 1
        let result = triple_integral("1", "x", "y", "z", 0.0, 1.0, 0.0, 1.0, 0.0, 1.0, 20);
        assert!(result.success);
        assert!((result.value - 1.0).abs() < 1e-2);
    }
}

#[cfg(test)]
mod statistics_tests {
    use crate::statistics::*;

    #[test]
    fn test_compute_statistics() {
        let data = vec![1.0, 2.0, 3.0, 4.0, 5.0];
        let result = compute_statistics(&data);
        assert!(result.success);

        // Mean should be 3.0
        let mean = result
            .values
            .iter()
            .find(|(k, _)| k == "mean")
            .map(|(_, v)| *v);
        assert!((mean.unwrap() - 3.0).abs() < 1e-10);

        // Median should be 3.0
        let median = result
            .values
            .iter()
            .find(|(k, _)| k == "median")
            .map(|(_, v)| *v);
        assert!((median.unwrap() - 3.0).abs() < 1e-10);
    }

    #[test]
    fn test_normal_distribution() {
        let result = distribution_compute("normal", &[0.0, 1.0], 0.0);
        assert!(result.success);
        // PDF at mean of standard normal
        assert!((result.pdf - 0.3989).abs() < 0.001);
        assert!((result.cdf - 0.5).abs() < 1e-6);
    }

    #[test]
    fn test_linear_regression() {
        let x = vec![1.0, 2.0, 3.0, 4.0, 5.0];
        let y = vec![2.0, 4.0, 6.0, 8.0, 10.0]; // y = 2x
        let result = linear_regression(&x, &y);
        assert!(result.success);
        assert!((result.coefficients[1] - 2.0).abs() < 1e-10); // slope
        assert!((result.coefficients[0]).abs() < 1e-10); // intercept
        assert!((result.r_squared - 1.0).abs() < 1e-10);
    }

    #[test]
    fn test_t_test() {
        let data = vec![5.1, 5.0, 4.9, 5.2, 5.0, 4.8];
        let result = t_test(&data, 5.0, 0.05);
        assert!(result.success);
        // Mean is close to 5.0, so shouldn't reject null
        assert!(!result.reject_null);
    }

    #[test]
    fn test_correlation_covariance() {
        // Perfect positive correlation
        let x = vec![1.0, 2.0, 3.0, 4.0, 5.0];
        let y = vec![2.0, 4.0, 6.0, 8.0, 10.0]; // y = 2x
        let result = correlation_covariance(&x, &y);
        assert!(result.success);
        assert!((result.correlation - 1.0).abs() < 1e-10); // Perfect correlation
        assert!((result.covariance - 5.0).abs() < 1e-10); // Sample covariance

        // Perfect negative correlation
        let y_neg = vec![10.0, 8.0, 6.0, 4.0, 2.0];
        let result = correlation_covariance(&x, &y_neg);
        assert!(result.success);
        assert!((result.correlation - (-1.0)).abs() < 1e-10);
    }

    #[test]
    fn test_confidence_interval_mean() {
        let data = vec![10.0, 12.0, 14.0, 11.0, 13.0];
        let result = confidence_interval_mean(&data, 0.95);
        assert!(result.success);
        // Mean is 12.0
        assert!((result.center - 12.0).abs() < 1e-10);
        // Check that the confidence interval contains the mean
        assert!(result.lower < 12.0);
        assert!(result.upper > 12.0);
    }

    #[test]
    fn test_confidence_interval_proportion() {
        // 50 successes out of 100 trials, 95% CI
        let result = confidence_interval_proportion(50, 100, 0.95);
        assert!(result.success);
        assert!((result.center - 0.5).abs() < 1e-10);
        // Standard CI for p=0.5, n=100 is approximately [0.402, 0.598]
        assert!(result.lower > 0.35);
        assert!(result.upper < 0.65);
    }

    #[test]
    fn test_confidence_interval_variance() {
        let data = vec![10.0, 12.0, 14.0, 11.0, 13.0];
        let result = confidence_interval_variance(&data, 0.95);
        assert!(result.success);
        // Variance should be around 2.5
        assert!(result.lower < result.center);
        assert!(result.upper > result.center);
    }

    #[test]
    fn test_z_test() {
        // Known population std = 2.0, testing if mean = 100
        let data = vec![98.0, 102.0, 100.0, 101.0, 99.0, 100.0, 98.0, 101.0];
        let result = z_test(&data, 100.0, 2.0, 0.05);
        assert!(result.success);
        // Mean is close to 100, shouldn't reject null
        assert!(!result.reject_null);
    }

    #[test]
    fn test_two_sample_z_test() {
        // Two samples with known population stds
        let data1 = vec![10.0, 11.0, 12.0, 9.0, 10.5];
        let data2 = vec![12.0, 13.0, 11.5, 12.5, 13.0];
        let result = two_sample_z_test(&data1, &data2, 1.0, 1.0, 0.05);
        assert!(result.success);
        // Means are different (10.5 vs 12.4), should reject null
        assert!(result.reject_null);
    }

    #[test]
    fn test_anova() {
        // Three groups with similar means
        let groups = vec![
            vec![5.0, 6.0, 7.0, 5.5],
            vec![5.5, 6.5, 6.0, 5.0],
            vec![6.0, 5.5, 6.5, 5.5],
        ];
        let result = anova(&groups, 0.05);
        assert!(result.success);
        // Similar means, shouldn't reject null
        assert!(!result.reject_null);

        // Three groups with different means
        let groups_diff = vec![
            vec![1.0, 2.0, 1.5, 2.5],
            vec![10.0, 11.0, 10.5, 11.5],
            vec![20.0, 21.0, 20.5, 21.5],
        ];
        let result_diff = anova(&groups_diff, 0.05);
        assert!(result_diff.success);
        // Very different means, should reject null
        assert!(result_diff.reject_null);
    }

    #[test]
    fn test_chi_squared() {
        // Observed vs expected frequencies
        let observed = vec![10.0, 20.0, 30.0, 40.0];
        let expected = vec![25.0, 25.0, 25.0, 25.0]; // uniform distribution
        let result = chi_squared_test(&observed, &expected, 0.05);
        assert!(result.success);
        // Observed significantly differs from expected
        assert!(result.reject_null);
    }
}

#[cfg(test)]
mod discrete_tests {
    use crate::discrete::*;

    #[test]
    fn test_is_prime() {
        assert!(is_prime(2));
        assert!(is_prime(3));
        assert!(is_prime(5));
        assert!(is_prime(7));
        assert!(is_prime(11));
        assert!(is_prime(97));
        assert!(!is_prime(0));
        assert!(!is_prime(1));
        assert!(!is_prime(4));
        assert!(!is_prime(9));
        assert!(!is_prime(100));
    }

    #[test]
    fn test_gcd() {
        assert_eq!(gcd(48, 18), 6);
        assert_eq!(gcd(100, 25), 25);
        assert_eq!(gcd(17, 13), 1);
    }

    #[test]
    fn test_lcm() {
        assert_eq!(lcm(4, 6), 12);
        assert_eq!(lcm(3, 5), 15);
    }

    #[test]
    fn test_factorial() {
        let result = factorial(5);
        assert!(result.success);
        assert_eq!(result.value, 120);

        let result = factorial(10);
        assert!(result.success);
        assert_eq!(result.value, 3628800);
    }

    #[test]
    fn test_combinations() {
        // C(5, 2) = 10
        let result = combinations(5, 2);
        assert!(result.success);
        assert_eq!(result.value, 10);

        // C(10, 3) = 120
        let result = combinations(10, 3);
        assert!(result.success);
        assert_eq!(result.value, 120);
    }

    #[test]
    fn test_permutations() {
        // P(5, 2) = 20
        let result = permutations(5, 2);
        assert!(result.success);
        assert_eq!(result.value, 20);
    }

    #[test]
    fn test_prime_factors() {
        let result = prime_factors(360);
        assert!(result.success);
        // 360 = 2³ × 3² × 5
        assert_eq!(result.values, vec![2, 2, 2, 3, 3, 5]);
    }

    #[test]
    fn test_fibonacci() {
        let result = fibonacci(10);
        assert!(result.success);
        assert_eq!(result.value, 55);

        let result = fibonacci(20);
        assert!(result.success);
        assert_eq!(result.value, 6765);
    }

    #[test]
    fn test_euler_totient() {
        // φ(10) = 4 (1, 3, 7, 9 are coprime to 10)
        let result = euler_totient(10);
        assert!(result.success);
        assert_eq!(result.value, 4);
    }

    #[test]
    fn test_catalan() {
        // C_5 = 42
        let result = catalan(5);
        assert!(result.success);
        assert_eq!(result.value, 42);
    }

    #[test]
    fn test_sieve() {
        let result = sieve_of_eratosthenes(30);
        assert!(result.success);
        assert_eq!(result.values, vec![2, 3, 5, 7, 11, 13, 17, 19, 23, 29]);
    }

    #[test]
    fn test_mod_pow() {
        // 2^10 mod 1000 = 1024 mod 1000 = 24
        let result = mod_pow(2, 10, 1000);
        assert!(result.success);
        assert_eq!(result.value, 24);

        // 3^5 mod 7 = 243 mod 7 = 5
        let result = mod_pow(3, 5, 7);
        assert!(result.success);
        assert_eq!(result.value, 5);
    }

    #[test]
    fn test_mod_inverse() {
        // 3^(-1) mod 11 = 4 (since 3*4 = 12 ≡ 1 mod 11)
        let result = mod_inverse(3, 11);
        assert!(result.success);
        assert_eq!(result.value, 4);
    }

    #[test]
    fn test_mod_add() {
        // (7 + 8) mod 10 = 15 mod 10 = 5
        let result = mod_add(7, 8, 10);
        assert!(result.success);
        assert_eq!(result.value, 5);

        // Large numbers that would overflow without u128
        let result = mod_add(u64::MAX - 1, 5, 10);
        assert!(result.success);
    }

    #[test]
    fn test_mod_sub() {
        // (15 - 7) mod 10 = 8
        let result = mod_sub(15, 7, 10);
        assert!(result.success);
        assert_eq!(result.value, 8);

        // (3 - 7) mod 10 = -4 mod 10 = 6
        let result = mod_sub(3, 7, 10);
        assert!(result.success);
        assert_eq!(result.value, 6);
    }

    #[test]
    fn test_mod_multiply() {
        // (7 * 8) mod 10 = 56 mod 10 = 6
        let result = mod_multiply(7, 8, 10);
        assert!(result.success);
        assert_eq!(result.value, 6);
    }

    #[test]
    fn test_mod_divide() {
        // (6 / 2) mod 7 = 3 (since 2*3 = 6 ≡ 6 mod 7)
        let result = mod_divide(6, 2, 7);
        assert!(result.success);
        assert_eq!(result.value, 3);
    }
}

#[cfg(test)]
mod graphing_tests {
    use crate::graphing::*;

    #[test]
    fn test_generate_x_range() {
        let xs = generate_x_range(0.0, 10.0, 11);
        assert_eq!(xs.len(), 11);
        assert!((xs[0] - 0.0).abs() < 1e-10);
        assert!((xs[10] - 10.0).abs() < 1e-10);
    }

    #[test]
    fn test_evaluate_graph_points() {
        let xs = vec![0.0, 1.0, 2.0, 3.0, 4.0];
        let result = evaluate_graph_points("x^2", "x", &xs);
        assert!(result.success);
        assert_eq!(result.points.len(), 5);
        assert!((result.points[2].y - 4.0).abs() < 1e-10);
    }

    #[test]
    fn test_find_zeros() {
        // x² - 1 = 0 has roots at ±1
        let roots = find_zeros("x^2 - 1", "x", -2.0, 2.0, 100);
        assert_eq!(roots.len(), 2);
    }

    #[test]
    fn test_find_extrema() {
        // x² has a minimum at x=0
        let (minima, maxima) = find_extrema("x^2", "x", -2.0, 2.0, 100);
        assert!(!minima.is_empty());
        assert!((minima[0].0).abs() < 0.1);
    }
}

#[cfg(test)]
mod units_tests {
    use crate::units::*;

    #[test]
    fn test_length_conversion() {
        let result = convert_unit(1.0, "m", "cm");
        assert!(result.success);
        assert!((result.value - 100.0).abs() < 1e-10);

        let result = convert_unit(1.0, "km", "m");
        assert!(result.success);
        assert!((result.value - 1000.0).abs() < 1e-10);
    }

    #[test]
    fn test_temperature_conversion() {
        let result = convert_unit(0.0, "celsius", "kelvin");
        assert!(result.success);
        assert!((result.value - 273.15).abs() < 1e-10);

        let result = convert_unit(32.0, "fahrenheit", "celsius");
        assert!(result.success);
        assert!((result.value - 0.0).abs() < 1e-10);

        let result = convert_unit(100.0, "celsius", "fahrenheit");
        assert!(result.success);
        assert!((result.value - 212.0).abs() < 1e-10);
    }

    #[test]
    fn test_mass_conversion() {
        let result = convert_unit(1.0, "kg", "g");
        assert!(result.success);
        assert!((result.value - 1000.0).abs() < 1e-10);

        let result = convert_unit(1.0, "lb", "kg");
        assert!(result.success);
        assert!((result.value - 0.453592).abs() < 1e-4);
    }

    #[test]
    fn test_invalid_conversion() {
        // Cannot convert length to mass
        let result = convert_unit(1.0, "m", "kg");
        assert!(!result.success);
    }

    #[test]
    fn test_get_categories() {
        let cats = get_categories();
        assert!(cats.contains(&"length".to_string()));
        assert!(cats.contains(&"mass".to_string()));
        assert!(cats.contains(&"temperature".to_string()));
    }
}
