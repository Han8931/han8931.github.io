# Getting Started with Regression: An Introductory Guide (Part 2)


# An Introductory Guide (Part 2)

## Regularization

Regularization means that instead of seeking the model parameters by minimizing the training loss alone, we add a penalty term to force the parameters to ``behave better''. 
With the ridge regression principle, we can optimize it as follows:

\begin{align*}
	J(\boldsymbol{\theta}) &= \lVert\mathbf{y}-\mathbf{X}\boldsymbol{\theta}\rVert^2_2 + \lambda \lVert\boldsymbol{\theta}\rVert^2_2 \\\\
			&= (\mathbf{y}-\mathbf{X}\boldsymbol{\theta})^T(\mathbf{y}-\mathbf{X}\boldsymbol{\theta})+\lambda\boldsymbol{\theta}^T\boldsymbol{\theta}\\\\
			&= (\mathbf{y}^T-\boldsymbol{\theta}^T\mathbf{X}^T)(\mathbf{y}-\mathbf{X}\boldsymbol{\theta})+\lambda\boldsymbol{\theta}^T\boldsymbol{\theta}\\\\
			&= \mathbf{y}^T\\mathbf{y}-\boldsymbol{\theta}^T\mathbf{X}^T\mathbf{y}-\mathbf{y}^T\mathbf{X}\boldsymbol{\theta}+\boldsymbol{\theta}^T\mathbf{X}^T\mathbf{X}\boldsymbol{\theta}+\boldsymbol{\theta}^T\lambda\mathbf{I}\boldsymbol{\theta}\\\\
	\frac{\partial J}{\partial \boldsymbol{\theta}}&= -\mathbf{X}^T\mathbf{y}-\mathbf{X}^T\mathbf{y}+\mathbf{X}^T\mathbf{X}\boldsymbol{\theta}+\mathbf{X}^T\mathbf{X}\boldsymbol{\theta}+2\lambda\mathbf{I}\boldsymbol{\theta} = 0\\\\
	\boldsymbol{\theta}	&= (\mathbf{X}^T\mathbf{X}+\lambda\mathbf{I})^{-1}\mathbf{X}^T\mathbf{y}
\end{align*}

- If $\lambda\to 0$, then $\lVert\mathbf{y}-\mathbf{X}\boldsymbol{\theta}\rVert^2_2 + \underbrace{\lambda \lVert\boldsymbol{\theta}\rVert^2_2}_{=0}$ 
- $\lambda\to \infty$, then $\underbrace{\frac{1}{\lambda}\lVert\mathbf{y}-\mathbf{X}\boldsymbol{\theta}\rVert^2_2}_{=0} + \lVert\boldsymbol{\theta}\rVert^2_2$, since what we want to do is to minimize the objective function, we can divide it by $\lambda$. Therefore, the solution will be $\boldsymbol{\theta}=0$, because it is the smallest value the squared function can achieve. 

Note that $\mathbf{X}^T\mathbf{X}$ is always symmetric \footnote{$(\mathbf{X}^T\mathbf{X})^T = \mathbf{X}^T\mathbf{X}$.}. Thus, it can be decomposed as $Q\Lambda Q^T$ by the Spectral theorem. The $Q$ and $\Lambda$ are eigenvector and eigenvalue matrices, respectively. Then, the inverse operation in the ridge regression can be expressed as follows:
\begin{align*}
	\mathbf{X}^T\mathbf{X}+\lambda\mathbf{I} &= \mathbf{Q}\mathbf{\Lambda}\mathbf{Q}^T+\lambda\mathbf{I}\\\\
											 &= \mathbf{Q}\mathbf{\Lambda}\mathbf{Q}^T+\lambda\mathbf{Q}\mathbf{Q}^T\\\\
											 &= \mathbf{Q}(\mathbf{\Lambda}+\lambda\mathbf{I})\mathbf{Q}^T.
\end{align*}
Even if the symmetric matrix is not invertible or close to not invertible, the regularization constant $\lambda$ makes it invertible (by making it to be a full-rank). 

Note that we can change the ridge regression into a dual form:
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
This gives us the solution of the underdetermined problems.  


## Weighted Regression
So far, we have assumed an equal confidence on all the measurements. Now we look at varying confidence in the measurements. We assume that the noise for each measurement has zero mean and is independent, then the covariance matrix for all measurement noise is given by
\begin{align*}
	R &= \mathbb{E}(\eta\eta^T)\\\\
	  &= \begin{bmatrix}
		  \sigma_1^2 & \dots & 0\\\\
		  \vdots & \ddots & \vdots\\\\
		  0 & \ddots & \sigma_l^2
	  \end{bmatrix}
\end{align*}
By denoting the error vector $\mathbf{y}-\mathbf{X}\boldsymbol{\theta}$ as $\boldsymbol{\epsilon} = (\epsilon_1, \dots, \epsilon_l)^T$, we will minimize the sum of squared differences weighted over the variations of the measurements:
\begin{align*}
	J(\tilde{\mathbf{x}}) &= \boldsymbol{\epsilon}^TR^{-1}\boldsymbol{\epsilon}=\frac{\boldsymbol{\epsilon}_1^2}{\sigma_1^2}+\dots+\frac{\boldsymbol{\epsilon}_l^2}{\sigma_l^2}\\\\
					&= (\mathbf{y}-\mathbf{X}\boldsymbol{\theta})^TR^{-1}(\mathbf{y}-\mathbf{X}\boldsymbol{\theta})
\end{align*}
By taking the partial derivative of $J$ with respect to $\boldsymbol{\theta}$, we get the best estimate of the parameter, which is given by
$$\boldsymbol{\theta} = (\mathbf{X}^TR^{-1}\mathbf{X})^{-1}\mathbf{X}^TR^{-1}\mathbf{y}.$$
Note that the measurement noise matrix $R$ must be non-singular for a solution to exist.


#### References:
1. H. Pishro-Nik, Introduction to Probability, Statistics, and Random Processes, 2014
2. Simon, Dan, Optimal State Estimation: Kalman, H Infinity, and Nonlinear Approaches, 2006



