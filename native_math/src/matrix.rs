//! Matrix operations using nalgebra

use nalgebra::{DMatrix, DVector, SymmetricEigen};
use serde::{Deserialize, Serialize};

/// Result of matrix operations
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MatrixResult {
    pub success: bool,
    pub data: Vec<f64>,
    pub rows: usize,
    pub cols: usize,
    pub scalar: Option<f64>,
    pub error: Option<String>,
}

impl MatrixResult {
    pub fn from_matrix(m: &DMatrix<f64>) -> Self {
        Self {
            success: true,
            data: m.iter().cloned().collect(),
            rows: m.nrows(),
            cols: m.ncols(),
            scalar: None,
            error: None,
        }
    }

    pub fn from_scalar(val: f64) -> Self {
        Self {
            success: true,
            data: vec![val],
            rows: 1,
            cols: 1,
            scalar: Some(val),
            error: None,
        }
    }

    pub fn from_vector(v: &DVector<f64>) -> Self {
        Self {
            success: true,
            data: v.iter().cloned().collect(),
            rows: v.len(),
            cols: 1,
            scalar: None,
            error: None,
        }
    }

    pub fn error(msg: &str) -> Self {
        Self {
            success: false,
            data: vec![],
            rows: 0,
            cols: 0,
            scalar: None,
            error: Some(msg.to_string()),
        }
    }
}

/// Result of matrix decompositions
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MatrixDecomposition {
    pub success: bool,
    pub decomposition_type: String,
    pub matrices: Vec<MatrixResult>,
    pub labels: Vec<String>,
    pub error: Option<String>,
}

impl MatrixDecomposition {
    pub fn error(msg: &str) -> Self {
        Self {
            success: false,
            decomposition_type: String::new(),
            matrices: vec![],
            labels: vec![],
            error: Some(msg.to_string()),
        }
    }
}

/// Create a matrix from flat data
fn create_matrix(data: &[f64], rows: usize, cols: usize) -> Option<DMatrix<f64>> {
    if data.len() != rows * cols {
        return None;
    }
    // nalgebra uses column-major, but we receive row-major data
    Some(DMatrix::from_row_slice(rows, cols, data))
}

/// Perform matrix operations
pub fn matrix_operation(
    a_data: &[f64],
    a_rows: usize,
    a_cols: usize,
    b_data: Option<&[f64]>,
    b_rows: Option<usize>,
    b_cols: Option<usize>,
    operation: &str,
) -> MatrixResult {
    let a = match create_matrix(a_data, a_rows, a_cols) {
        Some(m) => m,
        None => return MatrixResult::error("Invalid matrix A dimensions"),
    };

    match operation.to_lowercase().as_str() {
        // Unary operations
        "transpose" | "t" => MatrixResult::from_matrix(&a.transpose()),
        "inverse" | "inv" => {
            if a.nrows() != a.ncols() {
                return MatrixResult::error("Matrix must be square for inverse");
            }
            match a.clone().try_inverse() {
                Some(inv) => MatrixResult::from_matrix(&inv),
                None => MatrixResult::error("Matrix is singular, cannot invert"),
            }
        }
        "determinant" | "det" => {
            if a.nrows() != a.ncols() {
                return MatrixResult::error("Matrix must be square for determinant");
            }
            MatrixResult::from_scalar(a.determinant())
        }
        "trace" => {
            if a.nrows() != a.ncols() {
                return MatrixResult::error("Matrix must be square for trace");
            }
            MatrixResult::from_scalar(a.trace())
        }
        "rank" => MatrixResult::from_scalar(a.rank(1e-10) as f64),
        "norm" | "frobenius" => MatrixResult::from_scalar(a.norm()),
        "sum" => MatrixResult::from_scalar(a.sum()),
        "mean" => MatrixResult::from_scalar(a.mean()),
        "min" => MatrixResult::from_scalar(a.min()),
        "max" => MatrixResult::from_scalar(a.max()),

        // Power
        "power" | "pow" => {
            if a.nrows() != a.ncols() {
                return MatrixResult::error("Matrix must be square for power");
            }
            let n = b_data.and_then(|d| d.first().copied()).unwrap_or(2.0) as i32;
            if n < 0 {
                match a.clone().try_inverse() {
                    Some(inv) => {
                        let mut result = inv.clone();
                        for _ in 1..(-n) {
                            result = &result * &inv;
                        }
                        MatrixResult::from_matrix(&result)
                    }
                    None => MatrixResult::error("Matrix is singular"),
                }
            } else if n == 0 {
                MatrixResult::from_matrix(&DMatrix::identity(a.nrows(), a.ncols()))
            } else {
                let mut result = a.clone();
                for _ in 1..n {
                    result = &result * &a;
                }
                MatrixResult::from_matrix(&result)
            }
        }

        // Scalar operations
        "scale" | "scalar_mul" => {
            let s = b_data.and_then(|d| d.first().copied()).unwrap_or(1.0);
            MatrixResult::from_matrix(&(a * s))
        }

        // Binary operations (require matrix B)
        "add" | "+" => {
            let b = match (b_data, b_rows, b_cols) {
                (Some(d), Some(r), Some(c)) => match create_matrix(d, r, c) {
                    Some(m) => m,
                    None => return MatrixResult::error("Invalid matrix B dimensions"),
                },
                _ => return MatrixResult::error("Matrix B required for addition"),
            };
            if a.nrows() != b.nrows() || a.ncols() != b.ncols() {
                return MatrixResult::error("Matrices must have same dimensions for addition");
            }
            MatrixResult::from_matrix(&(a + b))
        }
        "subtract" | "sub" | "-" => {
            let b = match (b_data, b_rows, b_cols) {
                (Some(d), Some(r), Some(c)) => match create_matrix(d, r, c) {
                    Some(m) => m,
                    None => return MatrixResult::error("Invalid matrix B dimensions"),
                },
                _ => return MatrixResult::error("Matrix B required for subtraction"),
            };
            if a.nrows() != b.nrows() || a.ncols() != b.ncols() {
                return MatrixResult::error("Matrices must have same dimensions for subtraction");
            }
            MatrixResult::from_matrix(&(a - b))
        }
        "multiply" | "mul" | "*" | "×" => {
            let b = match (b_data, b_rows, b_cols) {
                (Some(d), Some(r), Some(c)) => match create_matrix(d, r, c) {
                    Some(m) => m,
                    None => return MatrixResult::error("Invalid matrix B dimensions"),
                },
                _ => return MatrixResult::error("Matrix B required for multiplication"),
            };
            if a.ncols() != b.nrows() {
                return MatrixResult::error("Matrix dimensions incompatible for multiplication");
            }
            MatrixResult::from_matrix(&(a * b))
        }
        "element_mul" | "hadamard" => {
            let b = match (b_data, b_rows, b_cols) {
                (Some(d), Some(r), Some(c)) => match create_matrix(d, r, c) {
                    Some(m) => m,
                    None => return MatrixResult::error("Invalid matrix B dimensions"),
                },
                _ => {
                    return MatrixResult::error("Matrix B required for element-wise multiplication")
                }
            };
            if a.nrows() != b.nrows() || a.ncols() != b.ncols() {
                return MatrixResult::error("Matrices must have same dimensions");
            }
            MatrixResult::from_matrix(&a.component_mul(&b))
        }

        _ => MatrixResult::error(&format!("Unknown operation: {}", operation)),
    }
}

/// Compute matrix decompositions
pub fn decompose(
    data: &[f64],
    rows: usize,
    cols: usize,
    decomposition_type: &str,
) -> MatrixDecomposition {
    let m = match create_matrix(data, rows, cols) {
        Some(m) => m,
        None => return MatrixDecomposition::error("Invalid matrix dimensions"),
    };

    match decomposition_type.to_lowercase().as_str() {
        "lu" => {
            if rows != cols {
                return MatrixDecomposition::error("LU decomposition requires square matrix");
            }
            let lu = m.clone().lu();
            let l = lu.l();
            let u = lu.u();
            // Return just L and U for now - permutation is complex to extract
            MatrixDecomposition {
                success: true,
                decomposition_type: "LU".to_string(),
                matrices: vec![MatrixResult::from_matrix(&l), MatrixResult::from_matrix(&u)],
                labels: vec!["L".to_string(), "U".to_string()],
                error: None,
            }
        }
        "qr" => {
            let qr = m.qr();
            MatrixDecomposition {
                success: true,
                decomposition_type: "QR".to_string(),
                matrices: vec![
                    MatrixResult::from_matrix(&qr.q()),
                    MatrixResult::from_matrix(&qr.r()),
                ],
                labels: vec!["Q".to_string(), "R".to_string()],
                error: None,
            }
        }
        "svd" => {
            match m.svd(true, true) {
                svd => {
                    let mut matrices = vec![];
                    let mut labels = vec![];

                    if let Some(u) = svd.u {
                        matrices.push(MatrixResult::from_matrix(&u));
                        labels.push("U".to_string());
                    }

                    // Singular values as diagonal matrix
                    let s = DMatrix::from_diagonal(&svd.singular_values);
                    matrices.push(MatrixResult::from_matrix(&s));
                    labels.push("Σ".to_string());

                    if let Some(v_t) = svd.v_t {
                        matrices.push(MatrixResult::from_matrix(&v_t));
                        labels.push("V^T".to_string());
                    }

                    MatrixDecomposition {
                        success: true,
                        decomposition_type: "SVD".to_string(),
                        matrices,
                        labels,
                        error: None,
                    }
                }
            }
        }
        "cholesky" => {
            if rows != cols {
                return MatrixDecomposition::error("Cholesky decomposition requires square matrix");
            }
            match m.cholesky() {
                Some(chol) => MatrixDecomposition {
                    success: true,
                    decomposition_type: "Cholesky".to_string(),
                    matrices: vec![MatrixResult::from_matrix(&chol.l())],
                    labels: vec!["L".to_string()],
                    error: None,
                },
                None => MatrixDecomposition::error("Matrix is not positive definite"),
            }
        }
        "eigen" | "eigenvalues" => {
            if rows != cols {
                return MatrixDecomposition::error(
                    "Eigenvalue decomposition requires square matrix",
                );
            }
            // Make symmetric for guaranteed real eigenvalues
            let sym = (&m + m.transpose()) / 2.0;
            let eigen = SymmetricEigen::new(sym);

            MatrixDecomposition {
                success: true,
                decomposition_type: "Eigen".to_string(),
                matrices: vec![
                    MatrixResult::from_vector(&eigen.eigenvalues),
                    MatrixResult::from_matrix(&eigen.eigenvectors),
                ],
                labels: vec!["Eigenvalues".to_string(), "Eigenvectors".to_string()],
                error: None,
            }
        }
        _ => MatrixDecomposition::error(&format!("Unknown decomposition: {}", decomposition_type)),
    }
}

/// Compute matrix properties
pub fn compute_properties(data: &[f64], rows: usize, cols: usize) -> MatrixResult {
    let m = match create_matrix(data, rows, cols) {
        Some(m) => m,
        None => return MatrixResult::error("Invalid matrix dimensions"),
    };

    // Return multiple properties as a special matrix result
    let mut props = vec![];

    // Rank
    props.push(m.rank(1e-10) as f64);

    // Determinant (if square)
    if rows == cols {
        props.push(m.determinant());
        props.push(m.trace());
    } else {
        props.push(f64::NAN);
        props.push(f64::NAN);
    }

    // Norms
    props.push(m.norm()); // Frobenius

    MatrixResult {
        success: true,
        data: props,
        rows: 1,
        cols: 4,
        scalar: None,
        error: None,
    }
}

/// Row reduce matrix to RREF
pub fn row_reduce(data: &[f64], rows: usize, cols: usize) -> MatrixResult {
    let mut m = match create_matrix(data, rows, cols) {
        Some(m) => m,
        None => return MatrixResult::error("Invalid matrix dimensions"),
    };

    let mut lead = 0;
    let row_count = m.nrows();
    let col_count = m.ncols();

    for r in 0..row_count {
        if lead >= col_count {
            break;
        }

        let mut i = r;
        while m[(i, lead)].abs() < 1e-10 {
            i += 1;
            if i == row_count {
                i = r;
                lead += 1;
                if lead == col_count {
                    return MatrixResult::from_matrix(&m);
                }
            }
        }

        // Swap rows
        m.swap_rows(i, r);

        // Scale pivot row
        let pivot = m[(r, lead)];
        if pivot.abs() > 1e-10 {
            for j in 0..col_count {
                m[(r, j)] /= pivot;
            }
        }

        // Eliminate column
        for i in 0..row_count {
            if i != r {
                let factor = m[(i, lead)];
                for j in 0..col_count {
                    m[(i, j)] -= factor * m[(r, j)];
                }
            }
        }

        lead += 1;
    }

    MatrixResult::from_matrix(&m)
}
