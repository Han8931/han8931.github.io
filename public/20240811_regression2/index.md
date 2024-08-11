# Getting Started with Regression: An Introductory Guide (Part 2)


# An Introductory Guide (Part 2)

## Understanding Ridge Regression

In machine learning, one of the key challenges is finding the right balance between underfitting and overfitting a model. 

- **Overfitting** occurs when a model is too complex and captures not only the underlying patterns in the training data but also the noise. This results in a model that performs well on the training data but poorly on new, unseen data.
  
- **Underfitting**, on the other hand, happens when a model is too simple to capture the underlying patterns in the data, leading to poor performance both on the training data and on new data.

To address these issues, regularization techniques are often used. Regularization involves adding a penalty term to the model's objective function, which helps control the complexity of the model and prevents it from overfitting.


## Overdetermined and Underdetermined Problems

Recall that linear regression is fundamentally an optimization problem where we aim to find the optimal parameter vector $\boldsymbol{\theta}_{opt}$ that minimizes the residual sum of squares between the observed data and the model's predictions. Mathematically, this is expressed as:

$$\boldsymbol{\theta}_{opt} = \argmin\_{\boldsymbol{\theta}\in \mathbb{R}^d}\lVert y-\mathbf{X}\boldsymbol{\theta}\rVert^2.$$

### Overdetermined Systems

An optimization problem is termed _overdetermined_ when the design matrix (or data matrix) $\mathbf{X}\in \mathbb{R}^{m\times d}$ has more rows than columns, i.e., $m>d$. This configuration means that there are more equations than unknowns, typically leading to a unique solution. The unique solution can be found using the formula: 
$$\boldsymbol{\theta} = (\mathbf{X}^T\mathbf{X})^{-1}\mathbf{X}^T\mathbf{y}$$

The solution exists if and only if $\mathbf{X}^T\mathbf{X}$ is invertible, which is true when the columns of $\mathbf{X}$ are linearly independent, meaning $\mathbf{X}$ is full rank. 

### Underdetermined Systems

In contrast, when $\mathbf{X}$ is fat and short (i.e., $N<d$), the problem is called _underdetermined_. In this scenario, there are more unknowns than equations, leading to infinitely many solutions. Among these, the solution that minimizes the squared norm of the parameters is preferred. This solution is known as the minimum-norm least-squares solution.

For an underdetermined linear regression problem, the objective can be written as:

\begin{align*}
	\boldsymbol{\theta} = \argmin\_{\boldsymbol{\theta}\in \mathbb{R}^d} \lVert \boldsymbol{\theta}\rVert^2, \quad \textrm{subject to}\ \mathbf{y} = \mathbf{X}\boldsymbol{\theta}.
\end{align*}

Here, $\mathbf{X}\in \mathbb{R}^{m\times d}, \boldsymbol{\theta}\in \mathbb{R}^d,$ and $\mathbf{y}\in \mathbb{R}^m$. If the matrix has full rank, meaning rank$(\mathbf{X})=N$, then the linear regression problem will have a unique global minimum 

\begin{align*}
	\boldsymbol{\theta} = \mathbf{X}^T(\mathbf{X}\mathbf{X}^T)^{-1}\mathbf{y}.
\end{align*}

This solution is called the minimum-norm least-squares solution. The proof of this solution is given by:
\begin{align*}
	\mathcal{L}(\boldsymbol{\theta}, \boldsymbol{\lambda}) = \lVert\boldsymbol{\theta}\rVert^2 + \boldsymbol{\lambda}^T(\mathbf{X}\boldsymbol{\theta}-\mathbf{y}),
\end{align*}

where $\boldsymbol{\lambda}$ is a Lagrange multiplier. The solution of the constrained optimization is the stationary point of the Lagrangian. To find it, we take the derivatives with respec to $\boldsymbol{\lambda}$ and $\boldsymbol{\theta}$ and setting them to zero: 

\begin{align*}
	\nabla_{\boldsymbol{\theta}} &= 2 \boldsymbol{\theta} + \mathbf{X}^T\boldsymbol{\lambda} = 0\\\\ 
	\nabla_{\boldsymbol{\lambda}} &= \mathbf{X}\boldsymbol{\theta} - \mathbf{y} = 0
\end{align*}

The first equation gives us $\boldsymbol{\theta} = -\mathbf{X}^T\boldsymbol{\lambda}/2$. Substituting it into the second equation, and assuming that rank$(\mathbf{X})=N$ so that $\mathbf{X}^T\mathbf{X}$ is invertible, we have $\boldsymbol{\lambda} = -2 (\mathbf{X}\mathbf{X}^T)^{-1}\mathbf{y}.$ Thus, we have

\begin{align*}
	\boldsymbol{\theta} = \mathbf{X}^T(\mathbf{X}\mathbf{X}^T)^{-1}\mathbf{y}.
\end{align*}

Note that $\mathbf{X}\mathbf{X}^T$ is often called a _Gram matrix_, $\mathbf{G}$. 

## Regularization and Ridge Regression

Regularization means that instead of seeking the model parameters by minimizing the training loss alone, we add a penalty term that encourages the parameters to "behave better," effectively controlling their magnitude. Ridge regression is a widely-used regularization technique that adds a penalty proportional to the square of the magnitude of the model parameters.

The objective function for ridge regression is formulated as:

\begin{align*}
    J(\boldsymbol{\theta}) = \lVert\mathbf{y}-\mathbf{X}\boldsymbol{\theta}\rVert^2_2 + \lambda \lVert\boldsymbol{\theta}\rVert^2_2 
\end{align*}

This can be expanded as:

\begin{align*}
	J(\boldsymbol{\theta}) = (\mathbf{y}-\mathbf{X}\boldsymbol{\theta})^T(\mathbf{y}-\mathbf{X}\boldsymbol{\theta}) + \lambda\boldsymbol{\theta}^T\boldsymbol{\theta}
\end{align*}

Breaking it down further:

\begin{align*}
	J(\boldsymbol{\theta}) = \mathbf{y}^T\mathbf{y} - \boldsymbol{\theta}^T\mathbf{X}^T\mathbf{y} - \mathbf{y}^T\mathbf{X}\boldsymbol{\theta} + \boldsymbol{\theta}^T\mathbf{X}^T\mathbf{X}\boldsymbol{\theta} + \lambda\boldsymbol{\theta}^T\mathbf{I}\boldsymbol{\theta}
\end{align*}

To minimize the objective function $J(\boldsymbol{\theta})$, we take the derivative with respect to $\boldsymbol{\theta}$ and set it to zero:

\begin{align*}
	\frac{\partial J}{\partial \boldsymbol{\theta}} = -\mathbf{X}^T\mathbf{y} - \mathbf{X}^T\mathbf{y} + \mathbf{X}^T\mathbf{X}\boldsymbol{\theta} + \mathbf{X}^T\mathbf{X}\boldsymbol{\theta} + 2\lambda\mathbf{I}\boldsymbol{\theta} = 0
\end{align*}

Solving for $\boldsymbol{\theta}$, we obtain the ridge regression solution:

\begin{align*}
	\boldsymbol{\theta} = (\mathbf{X}^T\mathbf{X} + \lambda\mathbf{I})^{-1}\mathbf{X}^T\mathbf{y}
\end{align*}

### Understanding the Role of $\lambda$ 

- When $\lambda$ approaches 0, the regularization term $\lambda \lVert\boldsymbol{\theta}\rVert^2_2$ becomes negligible, making ridge regression equivalent to ordinary least squares (OLS), which can lead to overfitting if the model is too complex.
    - If $\lambda\to 0$, then $\lVert\mathbf{y}-\mathbf{X}\boldsymbol{\theta}\rVert^2_2 + \underbrace{\lambda \lVert\boldsymbol{\theta}\rVert^2_2}_{=0}$ 
- As $\lambda$ increases towards infinity, the regularization term dominates, forcing $\boldsymbol{\theta}$ towards zero. In this case, the solution becomes overly simplistic, effectively shrinking the model parameters to zero, which may result in underfitting.
    - $\lambda\to \infty$, then $\underbrace{\frac{1}{\lambda}\lVert\mathbf{y}-\mathbf{X}\boldsymbol{\theta}\rVert^2_2}_{=0} + \lVert\boldsymbol{\theta}\rVert^2_2$
    - Since what we want to do is to minimize the objective function, we can divide it by $\lambda$. Therefore, the solution will be $\boldsymbol{\theta}=0$, because it is the smallest value the squared function can achieve. 





### Spectral Decomposition and Invertibility

It's important to note that $\mathbf{X}^T\mathbf{X}$ is always symmetric. According to the Spectral theorem, this matrix can be decomposed as $\mathbf{Q}\mathbf{\Lambda}\mathbf{Q}^T$, where $\mathbf{Q}$ is the eigenvector matrix, and $\mathbf{\Lambda}$ is the diagonal matrix of eigenvalues. This allows us to express the inverse operation in ridge regression as:

\begin{align*}
	\mathbf{X}^T\mathbf{X}+\lambda\mathbf{I} &= \mathbf{Q}\mathbf{\Lambda}\mathbf{Q}^T+\lambda\mathbf{I}\\\\
											 &= \mathbf{Q}\mathbf{\Lambda}\mathbf{Q}^T+\lambda\mathbf{Q}\mathbf{Q}^T\\\\
											 &= \mathbf{Q}(\mathbf{\Lambda}+\lambda\mathbf{I})\mathbf{Q}^T.
\end{align*}

Even if $\mathbf{X}^T\mathbf{X}$ is not invertible (or is close to being non-invertible), the regularization constant $\lambda$ ensures invertibility by making the matrix full-rank.

## Dual Form of Ridge Regression

Ridge regression can also be expressed in its dual form, which is particularly useful for solving underdetermined problems:
\begin{align*}
	(\mathbf{X}^T\mathbf{X}+\lambda\mathbf{I})\boldsymbol{\theta}	&= (\mathbf{X}^T\mathbf{X}+\lambda\mathbf{I})(\mathbf{X}^T\mathbf{X}+\lambda\mathbf{I})^{-1}\mathbf{X}^T\mathbf{y}\\\\
	(\mathbf{X}^T\mathbf{X}+\lambda\mathbf{I})\boldsymbol{\theta} &= \mathbf{X}^T\mathbf{y}\\\\
	\boldsymbol{\theta} &= \lambda^{-1}\mathbf{I}(\mathbf{X}^T\mathbf{y}-\mathbf{X}^T\mathbf{X}\boldsymbol{\theta})\\\\
	&= \mathbf{X}^T\lambda^{-1}(\mathbf{y}-\mathbf{X}\boldsymbol{\theta})\\\\
	&= \mathbf{X}^T\alpha\\\\
	\lambda\alpha &= (\mathbf{y}-\mathbf{X}\boldsymbol{\theta})\\\\
	&= (\mathbf{y}-\mathbf{X}\mathbf{X}^T\alpha)\\\\
	\mathbf{y} &= (\mathbf{X}\mathbf{X}^T\alpha+\lambda\alpha)\\\\
	\alpha &= (\mathbf{X}\mathbf{X}^T+\lambda)^{-1}\mathbf{y}\\\\
	\alpha &= (\mathbf{G}+\lambda)^{-1}\mathbf{y}.
\end{align*}
Here, $\alpha$ represents the dual coefficients, and $\mathbf{G}$ is the Gram matrix. This formulation is especially powerful when dealing with high-dimensional data, where the number of features exceeds the number of samples.

## Considering Varying Confidence in Measurements: Weighted Regression
Up to this point, we have assumed that all measurements are equally reliable. However, in practice, the confidence in different measurements may vary. To account for this, we can consider the situation where the noise associated with each measurement has a zero mean and is independent across measurements. Under these conditions, the covariance matrix for the measurement noise can be expressed as follows:

\begin{align*}
	R &= \mathbb{E}(\eta\eta^T)\\\\
	  &= \begin{bmatrix}
		  \sigma_1^2 & \dots & 0\\\\
		  \vdots & \ddots & \vdots\\\\
		  0 & \dots & \sigma_l^2
	  \end{bmatrix}
\end{align*}

By denoting the error vector $\mathbf{y}-\mathbf{X}\boldsymbol{\theta}$ as $\boldsymbol{\epsilon} = (\epsilon_1, \dots, \epsilon_l)^T$, we will minimize the sum of squared differences weighted over the variations of the measurements:
\begin{align*}
	J(\tilde{\mathbf{x}}) &= \boldsymbol{\epsilon}^TR^{-1}\boldsymbol{\epsilon}=\frac{\boldsymbol{\epsilon}_1^2}{\sigma_1^2}+\dots+\frac{\boldsymbol{\epsilon}_l^2}{\sigma_l^2}\\\\
					&= (\mathbf{y}-\mathbf{X}\boldsymbol{\theta})^TR^{-1}(\mathbf{y}-\mathbf{X}\boldsymbol{\theta})
\end{align*}
Note that by dividing each residual by its variance, we effectively equalize the influence of each data point on the overall fitting process. Subsequently, by taking the partial derivative of $J$ with respect to $\boldsymbol{\theta}$, we get the best estimate of the parameter, which is given by
$$\boldsymbol{\theta} = (\mathbf{X}^TR^{-1}\mathbf{X})^{-1}\mathbf{X}^TR^{-1}\mathbf{y}.$$
Note that the measurement noise matrix $R$ must be non-singular for a solution to exist.

To learn more, please take a look at this [note](https://github.com/Han8931/deep_statistical_learning)!

This article continues in Part 3.

#### References:
1. H. Pishro-Nik, Introduction to Probability, Statistics, and Random Processes, 2014
2. Simon, Dan, Optimal State Estimation: Kalman, H Infinity, and Nonlinear Approaches, 2006



