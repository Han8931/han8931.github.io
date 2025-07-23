---
weight: 1
title: "Introduction to SVM Part 2. LS-SVM"
date: 2024-08-31
draft: false
author: Han
description: "Introduction to Support Vector Machines Part 2."
tags: ["machine learning", "svm", "Support vector machines", "Least-Square SVM", "LS-SVM"]
categories: ["machine learning"]
---

# Introduction to Least-Square SVM

## Introduction
Least Squares Support Vector Machine (LS-SVM) is a modified version of the traditional Support Vector Machine (SVM) that simplifies the quadratic optimization problem by using a _least squares cost function_. LS-SVM transforms the quadratic programming problem in classical SVM into a set of linear equations, which are easier and faster to solve. 

### Optimization Problem (Primal Problem)

\begin{align*}
   &\min_{w, b, e} \frac{1}{2} \lVert w\rVert^2 + \frac{\gamma}{2} \sum_{i=1}^N e_i^2,\\\\
   &\text{subject to } y_i (w^T \phi(x_i) + b) = 1 - e_i, \ \forall i
\end{align*}
where:
- $w$ is the weight vector.
- $b$ is the bias term.
- $e_i$ are the error variables. 
- $\gamma$ is a regularization parameter.
- $\phi(x_i)$ is the feature mapping function.
- Note that $y_i^{-1} = y_i$, since $y_i = \pm 1$. 

### Lagrangian Function
To solve the constraint optimization problem, we define the Lagrangian function: 
\begin{align*}
	L(w, b, e, \alpha) = \min_{w, b, e} \frac{1}{2} \lVert w\rVert^2 + \frac{\gamma}{2} \sum_{i=1}^N e_i^2 - \sum_{i=1}^n \alpha_i \left[ y_i (w^T \phi(x_i) + b) - 1 + e_i \right],
\end{align*}
where $\alpha\_i$ are Lagrange multipliers. Then, by setting the partial derivatives of the Lagrangian with respect to $w$, $b$, $e$, and $\alpha$ to zero, we get the KKT conditions.


- $w$: 
    \begin{align*}
       \frac{\partial L}{\partial w} = w - \sum_{i=1}^n \alpha_i y_i \phi(x_i) = 0 \implies w = \sum_{i=1}^n \alpha_i y_i \phi(x_i)
    \end{align*}
- $b$:
    \begin{align*}
       \frac{\partial L}{\partial b} = -\sum_{i=1}^n \alpha_i y_i = 0
    \end{align*}
- $e_i$:
	\begin{align*}
	   \frac{\partial L}{\partial e_i} = \gamma e_i - \alpha_i = 0 \implies \alpha_i = \gamma e_i
	\end{align*}
	Thus, $e_i = \frac{\alpha_i}{\gamma}$
- $\alpha_i$:
	\begin{align*}
	   \frac{\partial L}{\partial \alpha_i} = - \left[ y_i (w^T \phi(x_i) + b) - 1 + e_i \right] = 0 \implies y_i (w^T \phi(x_i) + b) = 1 - e_i, i=1,\dots, N.
	\end{align*}

Let's substitute $w$ and $e$:
- $K$: kernel matrix
- $\alpha = [\alpha_1, \alpha_2, \ldots, \alpha_n]^T$: $N\times 1$
- $y = [y_1, y_2, \ldots, y_n]^T$.
- $\Omega = YKY^T$, where $\Omega\_{kl}= y\_ky_l\phi(x\_k)^T\phi(x\_l)$
- $Y = \text{diag}(y)$.
- $b$: $1\times 1$

Then, we can express it compactly
\begin{align*}
	& Y(KY^T\alpha+b\mathbf{1})-\mathbf{1}+\frac{\alpha}{2\gamma} = 0\\\\
    & \mathbf{1}^TY\alpha = 0.
\end{align*}
\begin{align*}
\end{align*}

By using the expression of $\alpha$ and $b$, we get
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
	1_n
	\end{bmatrix}
\end{align*}
Note that the dimension of the matrix on the left-hand side is $(N+1)\times (N+1)$. Once we have $b$ and $\alpha$ by solving the linear system, the decision function for **a new input** $x$ can be obtained by:
\begin{align*}
	f(x) = \sum_{i=1}^n \alpha_i y_i K(x_i, x) + b.
\end{align*}

#### Example
Suppose we have three training examples with feature vectors $x_1, x_2$, and $x_3$, and corresponding labels $y_1, y_2$, and $y_3$. The kernel matrix $\Omega$ is defined as:

\begin{align*}
	\Omega_{ij} = y_i y_j K(x_i, x_j)
\end{align*}
The dual form is:
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

- $y = \begin{bmatrix} y_1 \\ y_2 \\ y_3 \end{bmatrix}$ 
- $\alpha = \begin{bmatrix} \alpha_1\\ \alpha_2 \\ \alpha_3 \end{bmatrix} $
- $e = \begin{bmatrix} 1 \\ 1 \\ 1 \end{bmatrix}$
- $I$ is a $3 \times 3$ identity matrix

Then, the $\Omega$ is given by
\begin{align*}
	\Omega = \begin{bmatrix}
	y_1 y_1 K(x_1, x_1) & y_1 y_2 K(x_1, x_2) & y_1 y_3 K(x_1, x_3) \\\\
	y_2 y_1 K(x_2, x_1) & y_2 y_2 K(x_2, x_2) & y_2 y_3 K(x_2, x_3) \\\\
	y_3 y_1 K(x_3, x_1) & y_3 y_2 K(x_3, x_2) & y_3 y_3 K(x_3, x_3)
	\end{bmatrix}
\end{align*}

Now, the complete matrix equation is:

\begin{align*}
	\begin{bmatrix}
	0 & y_1 & y_2 & y_3 \\\\
	y_1 & \Omega_{11} + \frac{1}{\gamma} & \Omega_{12} & \Omega_{13} \\\\
	y_2 & \Omega_{21} & \Omega_{22} + \frac{1}{\gamma} & \Omega_{23} \\\\
	y_3 & \Omega_{31} & \Omega_{32} & \Omega_{33} + \frac{1}{\gamma}
	\end{bmatrix}
	\begin{bmatrix}
	b \\\\
	\alpha_1 \\\\
	\alpha_2 \\\\
	\alpha_3
	\end{bmatrix}
	=
	\begin{bmatrix}
	0 \\\\
	1 \\\\
	1 \\\\
	1
	\end{bmatrix}
\end{align*}

This can be written explicitly as:
\begin{align*}
	\begin{bmatrix}
	0 & y_1 & y_2 & y_3 \\\\
	y_1 & y_1^2 K(x_1, x_1) + \frac{1}{\gamma} & y_1 y_2 K(x_1, x_2) & y_1 y_3 K(x_1, x_3) \\\\
	y_2 & y_2 y_1 K(x_2, x_1) & y_2^2 K(x_2, x_2) + \frac{1}{\gamma} & y_2 y_3 K(x_2, x_3) \\\\
	y_3 & y_3 y_1 K(x_3, x_1) & y_3 y_2 K(x_3, x_2) & y_3^2 K(x_3, x_3) + \frac{1}{\gamma}
	\end{bmatrix}
	\begin{bmatrix}
	b \\\\
	\alpha_1 \\\\
	\alpha_2 \\\\
	\alpha_3
	\end{bmatrix}
	=
	\begin{bmatrix}
	0 \\\\
	1 \\\\
	1 \\\\
	1
	\end{bmatrix}
\end{align*}
The solution to this matrix equation provides the values of $b$ and $ \alpha_1, \alpha_2, \alpha_3$, which are then used to construct the decision function:
\begin{align*}
	f(x) = \sum_{i=1}^3 \alpha_i y_i K(x, x_i) + b
\end{align*}
