# Gentle Introduction to Singular Value Decomposition


# Singular Value Decomposition

In linear algebra, the singular value decomposition (SVD) is a factorization of a real or complex matrix. It generalizes the eigendecomposition of a square matrix by extending the concept to asymmetric or rectangular matrices, which cannot be diagonalized directly using eigendecomposition. The SVD aims to find the following decomposition of a real-valued matrix $A$:
$$A = U\Sigma V^T,$$
where $U$ and $V$ are orthogonal (orthonormal) matrices, and $\Sigma$ is a diagonal matrix. The columns of $U$ are called the left singular vectors of $A$, the columns of $V$ are called the right singular vectors, and the diagonal elements of $\Sigma$ are called the singular values.

Despite its widespread applications in areas such as data compression, noise reduction, and machine learning, SVD is often perceived as challenging to grasp. Many people find the mathematical intricacies daunting, even though there are numerous tutorials and explanations available. I remember struggling to fully understand SVD during my undergraduate studies, despite spending significant time on it. The complexity often arises from the abstract nature of the concepts involved, such as the interplay between eigenvectors, eigenvalues, and matrix decompositions.

However, understanding SVD is crucial for many advanced techniques in data science and engineering. For instance, if the data matrix $A$ is close to being of low rank, it is often desirable to find a low-rank matrix that approximates the original data matrix well. As we will see, the singular value decomposition of $A$ provides the best low-rank approximation of $A$.

The SVD process involves finding the eigenvalues and eigenvectors of the matrices $AA^T$ and $A^TA$. Since $A$ is generally not symmetric, it does not have orthogonal eigenvectors or guaranteed real eigenvalues, which complicates the process of SVD.

However, the matrix $A^TA$ is guaranteed to be symmetric, as $$(A^TA)^T=A^TA,$$ and positive semi-definite, meaning all its eigenvalues are non-negative. Symmetric matrices have real eigenvalues and orthogonal eigenvectors, simplifying the decomposition process. These properties ensure that $A^TA$ can be diagonalized using an orthogonal matrix, which is crucial for deriving the SVD.

The eigenvectors of $A^TA$ form the columns of $V$. We can diagonalize $A^TA$ as follows:
$$A^TA = V\Lambda V^T = \sum_{i=1}^{n}\lambda_i v_iv_i^T = \sum_{i=1}^{n}\sigma_i^2v_iv_i^T,$$
where the singular values of $A$ are defined as $\sigma_i = \sqrt{\lambda_i}$. Since $A^TA$ is a symmetric matrix, its eigenvalues are non-negative. The matrix $\Sigma$ in the SVD is a diagonal matrix whose diagonal entries are the singular values $\sigma_1, \dots, \sigma_r$, where $r$ is the rank of $A$. Note that $rank(A) = rank(A^TA)$, and these singular values appear in the first $r$ positions on the diagonal of $\Sigma$.

For the $i$-th eigenvector-eigenvalue pair, we have
$$A^TAv_i = \sigma_i^2v_i.$$
Now, let's derive the eigenvectors of $U$:
\begin{align*}
	A A^T (Av_i) &= A (\lambda_i v_i)\\\\ 
				 &= \lambda_i (A v_i).
\end{align*}
Thus, $Av_i$ is an eigenvector of $AA^T$. However, to ensure that the matrix $U$ is orthonormal, we need to normalize these vectors as follows:
\begin{align*}
	u_i &= \frac{Av_i}{\|Av_i\|} \\\\
		&= \frac{Av_i}{\sqrt{(Av_i)^TAv_i}} \\\\
		&= \frac{Av_i}{\sqrt{v_i^TA^TAv_i}} \\\\
		&= \frac{Av_i}{\sqrt{v_i^T\lambda_i v_i}} \\\\
		&= \frac{Av_i}{\sigma_i \underbrace{\|v_i\|}_{=1}} \\\\
		&= \frac{Av_i}{\sigma_i}.
\end{align*}
We can express $U$ as follows:
$$U= \left[\frac{Av_1}{\sigma_1}, \dots, \frac{Av_r}{\sigma_r}, \dots, \frac{Av_n}{\sigma_n}\right].$$
Then, we have
$$U\Sigma = AV.$$
By rearranging, we get
$$A = U\Sigma V^{-1}.$$
Since the inverse of an orthogonal matrix $V$ is its transpose, $V^T$, the final form of the SVD is:
$$A = U\Sigma V^T.$$

