# Root Finding, Numerical Integration, and FFT

## When to load
When implementing root-finding algorithms (bisection, Newton-Raphson, Brent's), numerical integration (trapezoidal, Simpson's, Gaussian quadrature), or FFT/NTT for polynomial multiplication and signal processing.

## Root Finding

### Bisection Method
- Bracket root in [a, b] where f(a) × f(b) < 0. Halve interval each step.
- Convergence: linear. Guaranteed for continuous f. One bit of precision per iteration.
- Use as fallback when other methods fail. Simple and robust.

### Newton-Raphson
- x_{k+1} = x_k - f(x_k) / f'(x_k). Requires derivative.
- Convergence: quadratic (doubles correct digits each iteration) near a simple root.
- Risks: divergence if starting point is far from root, division by zero near f'(x) = 0.
- Use for: smooth functions with available derivatives. Combine with bisection as safeguard.

### Secant Method
- Like Newton but approximates derivative: f'(x) ≈ (f(x_k) - f(x_{k-1})) / (x_k - x_{k-1}).
- Convergence: superlinear (~1.618 order). No derivative needed.
- Use when derivative is expensive or unavailable.

### Brent's Method
- Combines bisection, secant, and inverse quadratic interpolation. Guaranteed convergence with superlinear speed.
- Default root-finder in most numerical libraries (SciPy `brentq`).
- Use as the general-purpose root finder.

## Numerical Integration

### Trapezoidal Rule
- Approximate area with trapezoids. Error O(h²) where h = step size.
- Simple but slow convergence. Use as baseline.

### Simpson's Rule
- Approximate with parabolas (three points per interval). Error O(h⁴).
- Much better than trapezoidal for smooth functions. Requires even number of intervals.

### Gaussian Quadrature
- Choose optimal evaluation points and weights. n-point rule is exact for polynomials of degree ≤ 2n-1.
- Gauss-Legendre for general intervals. Gauss-Laguerre for [0, ∞). Gauss-Hermite for (-∞, ∞).
- Best accuracy per function evaluation for smooth functions.

### Adaptive Quadrature
- Subdivide intervals where error is large. Concentrate effort where integrand is complex.
- SciPy `quad` uses adaptive Gauss-Kronrod. Default choice for numerical integration.

## Fast Fourier Transform

### Cooley-Tukey FFT
- Compute DFT of n points in O(n log n) instead of O(n²).
- Divide-and-conquer: split into even and odd indices, recurse, combine with twiddle factors.
- Requires n to be a power of 2 (or use mixed-radix / Bluestein's for arbitrary n).

### Number Theoretic Transform (NTT)
- FFT over a finite field (modular arithmetic). No floating-point error.
- Use for: exact polynomial multiplication, competitive programming, large integer multiplication.
- Requires modulus with primitive root of unity (e.g., 998244353 = 119 × 2^23 + 1).

### Applications
- **Polynomial multiplication**: Multiply two degree-n polynomials in O(n log n) via FFT.
- **Convolution**: Signal processing, image filtering. Convolution theorem: conv(a,b) = IFFT(FFT(a) × FFT(b)).
- **Signal analysis**: Frequency spectrum, filtering, compression (JPEG, MP3).
- **String matching**: Wildcard matching via polynomial multiplication.
