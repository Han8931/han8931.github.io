---
weight: 1
title: "Getting Started with Regression: An Introductory Guide (Part 1)"
date: 2024-08-10
draft: false
author: Han
description: "Introduction to Regression: Understanding the Basics (Part 1)"
tags: ["machine learning", "regression", "least square"]
categories: ["machine learning"]
---

# An Introductory Guide (Part 1)

Even with the rapid advancements in deep learning, regression continues to be widely used across various fields (e.g., finance, data science, statistics, and so on), maintaining its importance as a fundamental algorithm. That's why I've decided to share this post, which is the first article in a dedicated series on regression. This series is designed to provide a thorough review while offering a gentle and accessible introduction.

## Linear Regression
Regression is a method used to identify the relationship between input and output variables. In a regression problem, we are given a set of noisy measurements (or output data) $\mathbf{y} = [y_1, \dots, y_d]^T$, which are affected by measurement noise $\boldsymbol{\eta} = [\eta_1, \dots, \eta_d]^T$. The corresponding input data is denoted by $\mathbf{x} = [x_1, \dots, x_d]$. We refer to the collection of these input-output pairs as the training data, $\mathcal{D} = \{(\mathbf{x}_1, \mathbf{y}_1), \dots, (\mathbf{x}_m, \mathbf{y}_m)\}$. The true relationship between the input and output data is unknown and is represented by a function $f(\cdot)$ that maps $\mathbf{x}_n$ to $y_n$, i.e.,
$$
	\mathbf{y} = f(\mathbf{x}).
$$
Determining the exact function $f(\cdot)$ from a finite set of data points $\mathcal{D}$ is not feasible because there are infinitely many possible mappings for each $\mathbf{x}_i$. 

The idea of regression is to *introduce structure to the problem*. Instead of trying to find the true $f(\cdot)$, we seek an approximate model $g_\theta(\cdot)$, which is parameterized by $\boldsymbol{\theta} = [\theta_1,\dots,\theta_d]^T$. For example, we might assume a linear relationship between $(\mathbf{x}_n, \mathbf{y}_n)$:

\begin{align*}
    g_{\boldsymbol{\theta}}(\mathbf{y}) = \mathbf{X}\boldsymbol{\theta} + \boldsymbol{\eta},
\end{align*}
where $\mathbf{X}$ is an $m \times d$ input matrix derived from our observations. Since the true relationship is unknown, any chosen model is essentially a hypothesis. However, we can quantify the error in our model. Given a parameter $\boldsymbol{\theta}$, the error between the noisy measurements and the estimated values is:

\begin{align*}
    \boldsymbol{\epsilon} = \mathbf{y} - \mathbf{X}\boldsymbol{\theta}.
\end{align*}
The goal of regression is to find the best $\boldsymbol{\theta}$ that minimizes this error. This leads us to the following objective function:

\begin{align*}
    J(\boldsymbol{\theta}) = \boldsymbol{\epsilon}^T \boldsymbol{\epsilon}.
\end{align*}
This objective function is equivalent to minimizing the mean squared error (MSE):

\begin{align*}
MSE = \frac{1}{n}\sum_{i=1}^n (y_i - \mathbf{x}_i \boldsymbol{\theta})^2.
\end{align*}
We can optimize this function in closed form as follows:

\begin{align*}
J(\boldsymbol{\theta}) &= \lVert\mathbf{y} - \mathbf{X} \boldsymbol{\theta}\rVert^2_2 \\\\
                        &= (\mathbf{y} - \mathbf{X} \boldsymbol{\theta})^T(\mathbf{y} - \mathbf{X} \boldsymbol{\theta}) \\\\
                        &= \mathbf{y}^T \mathbf{y} - \boldsymbol{\theta}^T \mathbf{X}^T \mathbf{y} - \mathbf{y}^T \mathbf{X} \boldsymbol{\theta} + \boldsymbol{\theta}^T \mathbf{X}^T \mathbf{X} \boldsymbol{\theta}.
\end{align*}
To find the $\boldsymbol{\theta}$ that minimizes the objective function, we compute the derivative of the function and set it equal to zero:
\begin{align*}
\frac{\partial J}{\partial \boldsymbol{\theta}} = -\mathbf{X}^T \mathbf{y} - \mathbf{X}^T \mathbf{y} + \mathbf{X}^T \mathbf{X} \boldsymbol{\theta} + \mathbf{X}^T \mathbf{X} \boldsymbol{\theta} = 0,
\end{align*}
which simplifies to:
\begin{align*}
\mathbf{X}^T (\mathbf{X} \boldsymbol{\theta} - \mathbf{y}) = 0,
\end{align*}
leading to the solution:
\begin{align*}
\boldsymbol{\theta} = (\mathbf{X}^T \mathbf{X})^{-1} \mathbf{X}^T \mathbf{y}.
\end{align*}
The equation $\mathbf{X}^T(\mathbf{X} \boldsymbol{\theta} - \mathbf{y}) = 0$ is known as the *normal equation*.

### Python Code

Let's implement a simple regression in Python:
```python
import numpy as np
import matplotlib.pyplot as plt

N = 50
x = np.random.randn(N)
w_1 = 3.4 # True Parameter
w_0 = 0.9 # True Parameter
y = w_1*x + w_0 + 0.3*np.random.randn(N) # Synthesize training data

X = np.column_stack((x, np.ones(N)))
W = np.array([w_1, w_0])

# From Scratch
XtX    = np.dot(X.T, X)
XtXinvX = np.dot(np.linalg.inv(XtX), X.T) # d x m
W_best = np.dot(XtXinvX, y.T)
print(f"W_best: {W_best}") 

# Pythonic Approach
theta = np.linalg.lstsq(X, y, rcond=None)[0]
print(f"Theta: {theta}") 

t = np.linspace(0, 1, 200)
y_pred = W_best[0]*t+W_best[1]
yhat = theta[0]*t+theta[1]
plt.plot(x, y, 'o')
plt.plot(t, y_pred, 'r', linewidth=4)
plt.show()
```

## Overdetermined and Underdetermined Systems
Recall that the linear regression problem is an optimization problem of finding the optimal parameter as follows:

$$
\hat{\boldsymbol{\theta}}=\argmin_{\boldsymbol{\theta}\in \mathbb{R}^d}\lVert y-\mathbf{X}\boldsymbol{\theta}^2 \rVert
$$
We say the optimization problem is *overdetermined* if $\mathbf{X}\in \mathbb{R}^{m\times d}$ is tall and skinny, i.e., $m>d$. This problem has a unique solution $\boldsymbol{\theta}=(\mathbf{X}^T\mathbf{X})^{-1}\mathbf{X}^T\mathbf{y}$ if and only if $\mathbf{X}^T\mathbf{X}$ is invertible. Equivalently, $\mathbf{X}$ should be linearly independent (\ie full rank). 

If $\mathbf{X}$ is fat and short (i.e., $N<d$), a problem is called *underdetermined*. **This problem will have infinitely many solutions**. Among all the feasible solutions, we will pick the one that minimizes the squared norm. The solution is called the *minimum-norm least squares*. Consider an underdetermined linear regression problem:  

\begin{align*}
	\boldsymbol{\theta}=\argmin_{\boldsymbol{\theta}\in \mathbb{R}^d} \lVert\boldsymbol{\theta}\rVert^2, \quad\textrm{subject to}\ \mathbf{y} = \mathbf{X}\boldsymbol{\theta},
\end{align*}
where $\mathbf{X}\in \mathbb{R}^{m\times d}, \boldsymbol{\theta}\in \mathbb{R}^d,$ and $\mathbf{y}\in \mathbb{R}^m$. If rank$(\mathbf{X})=N$, then the linear regression problem will have a unique global minimum 
\begin{align*}
	\boldsymbol{\theta}=\mathbf{X}^T(\mathbf{X}\mathbf{X}^T)^{-1}\mathbf{y}.
\end{align*}
This solution is called the minimum-norm least-squares solution. The proof of this solution is given by:
\begin{align*}
	\mathcal{L}(\boldsymbol{\theta}, \boldsymbol{\lambda})=\lVert\boldsymbol{\theta}\rVert^2+\boldsymbol{\lambda}^T(\mathbf{X}\boldsymbol{\theta}-\mathbf{y}),
\end{align*}
where $\boldsymbol{\lambda}$ is a Lagrange multiplier. The solution of the constrained optimization is the stationary point of the Lagrangian. To find it, we take the derivatives w.r.t., $\boldsymbol{\lambda}$ and $\boldsymbol{\theta}$ as follows: 
\begin{align*}
	\nabla_{\boldsymbol{\theta}} &= 2 \boldsymbol{\theta} + \mathbf{X}^T\boldsymbol{\lambda} = 0\\\\
	\nabla_{\boldsymbol{\lambda}} &= \mathbf{X}\boldsymbol{\theta} - \mathbf{y} = 0
\end{align*}
The first equation gives us $\boldsymbol{\theta}=-\mathbf{X}^T\boldsymbol{\lambda}/2$. Substituting it into the second equation, and assuming that rank$(\mathbf{X})=N$ so that $\mathbf{X}^T\mathbf{X}$ is invertible, we have $\boldsymbol{\lambda} = -2 (\mathbf{X}\mathbf{X}^T)^{-1}\mathbf{y}.$ Thus, we have
\begin{align*}
	\boldsymbol{\theta}=\mathbf{X}^T(\mathbf{X}\mathbf{X}^T)^{-1}\mathbf{y}.
\end{align*}
Note that $\mathbf{X}\mathbf{X}^T$ is often called a *Gram matrix*, $\mathbf{G}$.

To learn more, please take a look at this [note](https://github.com/Han8931/deep_statistical_learning)!

This article continues in Part 2.

#### References:
1. H. Pishro-Nik, Introduction to Probability, Statistics, and Random Processes, 2014

