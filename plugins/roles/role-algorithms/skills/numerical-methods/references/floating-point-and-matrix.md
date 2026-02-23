# Floating-Point Arithmetic and Matrix Computations

## When to load
When dealing with IEEE 754 precision issues, implementing Kahan summation, choosing matrix decomposition methods (LU, QR, SVD), or working with sparse matrix formats.

## Floating-Point Arithmetic

### IEEE 754 Basics
- float (32-bit): ~7 decimal digits precision, range ±3.4×10^38.
- double (64-bit): ~15 decimal digits precision, range ±1.8×10^308.
- Representation: sign (1 bit) + exponent + mantissa. Not all decimals are exactly representable.

### Common Pitfalls
- **Catastrophic cancellation**: Subtracting nearly equal numbers loses significant digits. Example: (1 + 10^(-16)) - 1 = 0 in double precision.
- **Accumulation error**: Summing many small numbers loses precision. Use Kahan summation.
- **Comparison**: Never use `==` for floats. Use |a - b| < ε with appropriate ε (relative or absolute).
- **Overflow/underflow**: Intermediate results may overflow even if final result is representable. Use log-space for products of many numbers.

### Kahan Summation
- Compensated summation algorithm. Tracks lost low-order bits in a compensation variable.
- Error: O(ε) instead of O(nε) for naive summation (ε = machine epsilon).
- Use whenever summing more than ~1000 floating-point numbers.

### When to Use What
- **Financial calculations**: BigDecimal / Decimal types (exact arithmetic for base-10).
- **Scientific computation**: double precision. Know your error bounds.
- **Graphics / ML inference**: float or half-precision (16-bit) acceptable for performance.
- **Exact integer arithmetic**: Use arbitrary-precision integers when overflow is possible (Python int, Java BigInteger).

## Matrix Computations

### Gaussian Elimination
- Solve Ax = b by row reduction. O(n³). Produces upper triangular system, back-substitute.
- Partial pivoting (swap rows): essential for numerical stability. Always use it.
- Full pivoting (swap rows and columns): better stability, rarely needed in practice.

### LU Decomposition
- A = LU (or PA = LU with pivoting). Factor once, solve for multiple right-hand sides.
- Solve Ax = b: forward substitution (Ly = b) then back substitution (Ux = y). O(n²) per solve after O(n³) factorization.
- Use for: repeated solves with same coefficient matrix, determinant computation (det = product of diagonal of U).

### QR Factorization
- A = QR where Q is orthogonal, R is upper triangular.
- Methods: Gram-Schmidt (unstable), modified Gram-Schmidt (better), Householder reflections (best stability).
- Use for: least squares problems (min ‖Ax - b‖), eigenvalue computation (QR algorithm).

### SVD (Singular Value Decomposition)
- A = UΣV^T. U, V orthogonal. Σ diagonal with singular values σ₁ ≥ σ₂ ≥ ... ≥ 0.
- Applications: low-rank approximation (keep top k singular values), pseudoinverse, PCA, matrix completion.
- Truncated SVD: compute only top k singular values/vectors. O(mnk) instead of O(mn × min(m,n)).

### Sparse Matrix Representations
- **COO (Coordinate)**: Store (row, col, value) triples. Good for construction.
- **CSR (Compressed Sparse Row)**: Row pointers + column indices + values. Efficient for row-wise access and SpMV.
- **CSC (Compressed Sparse Column)**: Column-wise variant. Efficient for column access.
- Use sparse formats when >90% of entries are zero. SciPy `scipy.sparse`, Eigen (C++).
