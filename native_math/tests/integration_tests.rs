use kivixa_math::statistics::advanced_regression;
use kivixa_math::discrete::{permutations, combinations, stirling_second, integer_partitions, derangements};

#[test]
fn test_regression_linear() {
    let x = vec![1.0, 2.0, 3.0, 4.0, 5.0];
    let y = vec![2.0, 4.0, 5.0, 4.0, 5.0];
    let res = advanced_regression(&x, &y, "linear");
    assert!(res.success);
    assert!(!res.coefficients.is_empty());
}

#[test]
fn test_regression_logistic() {
    let x = vec![1.0, 2.0, 3.0, 4.0, 5.0, 6.0];
    let y = vec![0.0, 0.0, 0.0, 1.0, 1.0, 1.0];
    let res = advanced_regression(&x, &y, "logistic");
    assert!(res.success);
}

#[test]
fn test_combinatorics_permutations() {
    let res = permutations(5, 3); // P(5,3)
    assert!(res.success);
}

#[test]
fn test_combinatorics_combinations() {
    let res = combinations(5, 3); // C(5,3)
    assert!(res.success);
}

#[test]
fn test_stirling_second() {
    let res = stirling_second(5, 3);
    assert!(res.success);
}

#[test]
fn test_partitions() {
    let res = integer_partitions(5);
    assert!(res.success);
}

#[test]
fn test_derangements() {
    let res = derangements(4);
    assert!(res.success);
}
