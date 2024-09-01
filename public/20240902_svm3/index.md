# Introduction to SVM Part 3. Asymmetric Kernels


# Introduction to Asymmetric Kernels

Recall that the dual form of LS-SVM is given by
\begin{align*}
	\begin{bmatrix}
	0 & y^T \\\\
	y & \Omega + \frac{1}{\gamma} I
	\end{bmatrix}
	\begin{bmatrix}
	b \\\\
	\alpha
	\end{bmatrix}
	=
	\begin{bmatrix}
	0 \\\\
	e
	\end{bmatrix}
\end{align*}
An interesting point here is that using an asymmetric kernel in LS-SVM will not reduce to its symmetrization and asymmetric information can be learned. Then we can develop asymmetric kernels in the LS-SVM framework in a straightforward way.

Asymmetric kernels are particularly useful in capturing directional relationships in data that symmetric kernels cannot. For instance, in scenarios involving directed graphs or conditional probabilities, the relationship from $x$ to $y$ is inherently different from the relationship from $y$ to $x$.

## AsK-LS Primal Problem Formulation
We first define a generalized kernel trick for an inner product of two mappings $\phi_s$ and $\phi_t$.
\begin{align*}
	K(\mathbf{u}, \mathbf{v}) = \langle \phi_s(\mathbf{u}), \phi_t(\mathbf{v})\rangle, \forall \mathbf{u} \in \mathbb{R}^{d_s}, \mathbf{v} \in \mathbb{R}^{d_t},
\end{align*}
where $\phi_s: \mathbb{R}^{d_s}\to \mathbb{R}^{p}$, $\phi_t: \mathbb{R}^{d_t}\to \mathbb{R}^{p}$, and $\mathbb{R}^p$ is a high-dimensional or even an infinite-dimensional space. Note that $d_s$ and $d_t$ can be different. 

This formulation is closely related to the traditional LS-SVM but extends it by simultaneously considering both source and target feature spaces. The optimization goal is to find the weight vectors $ \omega $ and $ \nu $, and bias terms $ b_1 $ and $ b_2 $, that minimize the following objective function:

\begin{align*}
	\min_{\omega, \nu, b_1, b_2, e, h} \frac{1}{2} \omega^T \nu + \frac{\gamma}{2} \sum_{i=1}^m e_i^2 + \frac{\gamma}{2} \sum_{i=1}^m h_i^2, 
\end{align*}
subject to the constraints:
\begin{align*}
	& y_i (\omega^T \phi_s(x_i) + b_1) = 1 - e_i\\
	& y_i (\nu^T \phi_t(x_i) + b_2) = 1 - h_i
\end{align*}
Here:
- $ \omega $ and $ \nu $ are weight vectors for the source and target features.
- $ \phi_s(x) $ and $ \phi_t(x) $ are the source and target feature mappings.
- $ e_i $ and $ h_i $ are error terms for the source and target constraints.
- $ \gamma $ is a regularization parameter.
Note that this formulation is almost the same as the LS-SVM except that this considers both the source and target feature spaces simultaneously.

## Dual Form
Let's transform it into a _dual_ form. The dual problem involves solving a system of linear equations derived from the primal problem's Lagrangian. The Lagrangian function for the primal problem is:

\begin{align*}
	\mathcal{L}( \omega, \nu, b\_1, b\_2, e, h, \alpha, \beta) &= \frac{1}{2} \omega\^T \nu + \frac{\gamma}{2} \sum\_{i=1}^m e\_i^2 + \frac{\gamma}{2} \sum\_{i=1}^m h\_i^2\\\\
		   + \sum\_{i=1}^m \alpha\_i (1 - e_i &- y_i (\omega^T \phi\_s(x_i) + b_1)) + \sum\_{i=1}^m \beta\_i (1 - h_i - y_i (\nu^T \phi\_t(x_i) + b_2))
\end{align*}

The KKT conditions are derived by setting the partial derivatives of the Lagrangian with respect to $ \omega, \nu, b_1, b_2, e, $ and $ h $ to zero. The dual problem leads to the following linear system:

\begin{align*}
\begin{bmatrix}
0 & 0 & Y^T & 0 \\\\
0 & 0 & 0 & Y^T \\\\
Y & 0 & \frac{I}{\gamma} & H \\\\
0 & Y & H^T & \frac{I}{\gamma}
\end{bmatrix}
\begin{bmatrix}
b_1 \\\\
b_2 \\\\
\alpha \\\\
\beta
\end{bmatrix}
=\begin{bmatrix}
0 \\\\
0 \\\\
1 \\\\
1
\end{bmatrix}
\end{align*}
where:
- $ Y $ is a vector of class labels.
- $ H $ is the kernel matrix with elements $ H_{ij} = y_i K(x_i, x_j) y_j $, where $ K(x_i, x_j) = \langle \phi_s(x_i), \phi_t(x_j) \rangle $ is the asymmetric kernel function.
    - For an asymmetric kernel $ K $, the kernel function $ K(x_i, x_j) \neq K(x_j, x_i) $. This asymmetry is directly incorporated into the matrix $ H $, where:
\begin{align*}
    H\_{ij} &= y_i K(x_i, x_j) y_j \\\\
    H\_{ji} &= y_j K(x_j, x_i) y_i
\end{align*}

AsK-LS uses two different feature mappings $ \phi_s $ and $ \phi_t $ for the source and target features. This approach allows capturing more information compared to symmetric kernels. The dual solution provides weight vectors $ \omega $ and $ \nu $, which span the target and source feature spaces, respectively.

The decision functions for classification from the source and target perspectives are given by
\begin{align*}
f_s(x) &= \sum\_{i=1}^m \beta_i y_i K(x, x_i) + b_1\\\\
f_t(x) &= \sum\_{i=1}^m \alpha_i y_i K(x_i, x) + b_2
\end{align*}
These decision functions leverage the learned asymmetric relationships in the data, providing a more nuanced classification model.




