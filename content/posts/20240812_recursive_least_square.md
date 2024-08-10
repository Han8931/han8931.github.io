---
weight: 1
title: "Getting Started with Regression: An Introductory Guide (Part 3)"
date: 2024-08-12
draft: false
author: Han
description: "Introduction to Regression: Recursive Least Squares (Part 3)"
tags: ["machine learning", "regression", "least square", "recursive least squares"]
categories: ["machine learning"]
---

<h1 style="line-height: 1.3;">Deep Dive into Regression: Recursive Least Squares Explained (Part 3)</h1>

## Introduction to Recursive Least Squares

Ordinary least squares assumes that all data is available at once, but in practice, this isn't always the case. **Often, measurements are obtained sequentially**, and we need to update our estimates as new data comes in. Simply augmenting the data matrix $\mathbf{X}$ each time a new measurement arrives can become computationally expensive, especially when dealing with a large number of measurements. This is where **_Recursive Least Squares_** (RLS) comes into play.

RLS allows us to update our estimates efficiently as new measurements are obtained, without having to recompute everything from scratch. Suppose we have an estimate $\boldsymbol{\theta}\_{k-1}$ after $k-1$ measurements and we receive a new measurement $\mathbf{y}\_k$. We want to update our estimate $\boldsymbol{\theta}\_k$ using the following linear recursive model:
\begin{align*}
    \mathbf{y}\_k&=\mathbf{X}\_k\boldsymbol{\theta} + \boldsymbol{\eta}\_k\\\\
    \boldsymbol{\theta}_k&=\boldsymbol{\theta}\_{k-1} + K\_k (\mathbf{y}\_k - \mathbf{X}\_k\boldsymbol{\theta}\_{k-1})
\end{align*}
where $\mathbf{X}\_k$ is the observation matrix, $K\_k$ is the gain matrix, and $\boldsymbol{\eta}_k$ represents the measurement error. The term $(\mathbf{y}\_k - \mathbf{X}\_k\boldsymbol{\theta}\_{k-1})$ is the correction term that adjusts our previous estimate using the new data. Also, $\boldsymbol{\eta}\_k$ is the measurement error. The new estimate is modified from the previous estimate $\boldsymbol{\theta}\_{k-1}$ with a correction via the gain matrix.

To update the estimate optimally, we need to calculate the gain matrix $K\_k$. This involves minimizing the variance of the estimation errors at time $k$. The error at step $k$ can be expressed as:

\begin{align*}
	\boldsymbol{\epsilon}_k	&= \boldsymbol{\theta}-\boldsymbol{\theta}\_k \\\\
							&= \boldsymbol{\theta}-\boldsymbol{\theta}\_{k-1} - K\_k (\mathbf{y}\_k-\mathbf{X}\_k\boldsymbol{\theta}\_{k-1})\\\\
							&= \boldsymbol{\epsilon}\_{k-1}-K\_k (\mathbf{X}\_k\boldsymbol{\theta}+\boldsymbol{\eta}\_k-\mathbf{X}\_k\boldsymbol{\theta}\_{k-1})\\\\
							&= \boldsymbol{\epsilon}\_{k-1}-K\_k \mathbf{X}\_k(\boldsymbol{\theta}-\boldsymbol{\theta}\_{k-1})-K_k\boldsymbol{\eta}\_k\\\\
							&= (I-K_k \mathbf{X}\_k)\boldsymbol{\epsilon}\_{k-1}-K\_k\boldsymbol{\eta}\_k,
\end{align*}

where $I$ is the $d\times d$ identity matrix. The mean of this error is then

\begin{align*}
    \mathbb{E}[\boldsymbol{\epsilon}\_{k}] = (I-K\_k \mathbf{X}\_k)\mathbb{E}[\boldsymbol{\epsilon}\_{k-1}]-K\_k\mathbb{E}[\boldsymbol{\eta}\_{k}]
\end{align*}

If $\mathbb{E}[\boldsymbol{\eta}\_{k}]=0$ and $\mathbb{E}[\boldsymbol{\epsilon}\_{k-1}]=0$, then $\mathbb{E}[\boldsymbol{\epsilon}\_{k}]=0$. So if the measurement noise has zero mean for all $k$, and the initial estimate of $\boldsymbol{\theta}$ is set equal to its expected value, then $\boldsymbol{\theta}_k=\boldsymbol{\theta}\_k, \forall k$. This property tells us that the estimator $\boldsymbol{\theta}\_k = \boldsymbol{\theta}\_{k-1}+K_k (\mathbf{y}\_k-\mathbf{X}\_k\boldsymbol{\theta}\_{k-1})$ is *unbiased*. This property holds regardless of the value of the gain vector $K_k$. This means the estimate will be equal to the true value $\boldsymbol{\theta}$ on average. 

The key task is to find the optimal $K_k$ by minimizing the trace of the estimation-error covariance matrix $P_k = \mathbb{E}[\boldsymbol{\epsilon}_k \boldsymbol{\epsilon}_k^T]$. This optimization leads to the following expression for \( K_k \):

\begin{align*}
	J_k &= \mathbb{E}[\lVert\boldsymbol{\theta}-\boldsymbol{\theta}\_k\rVert^2]\\\\
		&= \mathbb{E}[\boldsymbol{\epsilon}\_{k}^T\boldsymbol{\epsilon}\_{k}]\\\\
		&= \mathbb{E}[tr(\boldsymbol{\epsilon}\_{k}\boldsymbol{\epsilon}\_{k}^T)]\\\\
		&= tr(P_k),
\end{align*}

where $P\_k=\mathbb{E}[\boldsymbol{\epsilon}\_{k}\boldsymbol{\epsilon}\_{k}^T]$ is **_the estimation-error covariance_** (i.e., **covariance matrix**). Note that the third line holds by the trace of a product (i.e., _cyclic property_) and the expectation in the third line can go into the trace operator by its linearity. Next, we can obtain $P\_k$ by

\begin{align*}
	P_k = \mathbb{E}\bigg[\big((I-K\_k \mathbf{X}\_k)\boldsymbol{\epsilon}\_{k-1}-K\_k\boldsymbol{\eta}\_k\big)\big((I-K_k \mathbf{X}_k)\boldsymbol{\epsilon}\_{k-1}-K_k\boldsymbol{\eta}_k\big)^T\bigg]
\end{align*}

By rearranging the above equation with the property that the mean of noise is zero, we can get
\begin{align*}
	P_k = (I-K_k \mathbf{X}_k)P\_{k-1}(I-K_k \mathbf{X}_k)^T+K_kR_kK_k^T,
\end{align*}
where $R_k = \mathbb{E}[\boldsymbol{\eta}_k\boldsymbol{\eta}_k^T]$ as covariance of $\boldsymbol{\eta}_k$. This equation is the recurrence for the covariance of the least squares estimation error. It is consistent with the intuition that as the measurement noise $R_k$ increases, the uncertainty in our estimate also increases (i.e., $P_k$ increases). Note that $P_k$ should be positive definite since it is a covariance matrix.

Subsequently, let's compute $K\_k$ that minimizes the cost function given by the error equation. We are going to utilize the following property:

\begin{align*}
	\frac{\partial tr(CA^T)}{\partial A} &= C\\\\
	\frac{\partial tr(ACA^T)}{\partial A} &= AC + AC^T
\end{align*}

Then, take a derivative to the objective function:

\begin{align*}
	\frac{\partial J_k}{\partial K_k} &= \frac{\partial tr(P_k)}{\partial K_k} = \frac{\partial tr}{\partial K_k}\underbrace{(I-K_k \mathbf{X}_k)P\_{k-1}(I-K_k \mathbf{X}_k)^T}\_{\to ACA^T}+\frac{\partial}{\partial K_k}tr\left(K_k R_k K_k^T\right)\\\\
									  &= \frac{\partial tr(ACA^T)}{\partial (I-K_k \mathbf{X}_k)}\frac{\partial (I-K_k \mathbf{X}_k)}{\partial K_k} +\frac{\partial}{\partial K_k}tr\left(K_k R_k K_k^T\right) \quad \text{by Chain Rule}\\\\
	&= \left((I-K_k \mathbf{X}_k)P\_{k-1}+ (I-K_k \mathbf{X}_k)P\_{k-1}^T\right)(-\mathbf{X}_k^T) + \frac{\partial}{\partial K_k}tr\left(K_k R_k K_k^T\right)\\\\
	&= 2(I-K_k \mathbf{X}_k)P\_{k-1}(-\mathbf{X}_k^T) + \frac{\partial}{\partial K_k}tr\left(K_k R_k K_k^T\right)\quad \text{, since } P\_{k-1} \text{ is symmetric.}\\\\
									  &= -2(I-K_k \mathbf{X}_k)P\_{k-1}\mathbf{X}_k^T+2K_kR_k
\end{align*}

By setting the partial derivative to zero, we get
$$K_k = P\_{k-1}\mathbf{X}_k^T(\mathbf{X}_kP\_{k-1}\mathbf{X}_k^T+R_k)^{-1}.$$

### Alternative Formulations
Sometimes alternate forms of the equations for $P_k$ and $K_k$ are useful for computational purposes. Let's first set $\mathbf{X}_kP\_{k-1}\mathbf{X}_k^T+R_k = S_k$, then we get 

$$K_k = P\_{k-1}\mathbf{X}_k^TS_k^{-1}.$$

By putting this into $P_k$, we can obtain

\begin{align*}
	P_k &= (I-P\_{k-1}\mathbf{X}_k^TS_k^{-1} \mathbf{X}_k)P\_{k-1}(I-P\_{k-1}\mathbf{X}_k^TS_k^{-1} \mathbf{X}_k)^T+P\_{k-1}\mathbf{X}_k^TS_k^{-1} R_k S_k^{-1}\mathbf{X}_kP\_{k-1}\\\\
		&\quad \vdots\\\\
		&= P\_{k-1}-P\_{k-1}\mathbf{X}_k^TS_k^{-1}\mathbf{X}_k^TP\_{k-1}\\\\
		&= (I-K_k\mathbf{X}_k)P\_{k-1}.
\end{align*}

Note that $P_k$ is symmetric (c.f., $P\_k=\boldsymbol{\epsilon}\_{k}\boldsymbol{\epsilon}\_{k}^T$), since it is a covariance matrix, and so is $S_k$. Then, we take the inverse of both sides of 

$$P\_{k-1}^{-1} = \bigg(\underbrace{P\_{k-1}}\_{A}-\underbrace{P\_{k-1}\mathbf{X}\_k^T}\_{B}\big(\underbrace{\mathbf{X}\_kP\_{k-1}\mathbf{X}\_k^T}\_{D}\big)^{-1}\underbrace{\mathbf{X}_kP\_{k-1}}\_{C}\bigg)^{-1}.$$

Next, we apply the matrix inversion lemma which is known as _Sherman-Morrison-Woodbury matrix identity_ (or _matrix inversion lemma_) identity: 

$$(A-BD^{-1}C)^{-1} = A^{-1}+A^{-1}B(D-CA^{-1}B)^{-1}CA^{-1}.$$

Then, rewrite $P\_k^{-1}$ as follows:

\begin{align*}
	P_k^{-1} &= P\_{k-1}^{-1}+P\_{k-1}^{-1}P\_{k-1}\mathbf{X}\_k^T\big((\mathbf{X}\_kP\_{k-1}\mathbf{X}\_k^T+R\_k)-\mathbf{X}\_kP\_{k-1}P\_{k-1}^{-1}(P\_{k-1}\mathbf{X}\_k^T)\big)^{-1}\mathbf{X}\_kP\_{k-1}P\_{k-1}^{-1}\\\\
			 &= P\_{k-1}^{-1}+\mathbf{X}\_k^TR_{k}^{-1}\mathbf{X}_k
\end{align*}

This yields an alternative expression for the covariance matrix:

\begin{align*}
	P_k = \big(P\_{k-1}^{-1}+\mathbf{X}\_k^TR\_{k}^{-1}\mathbf{X}\_k\big)^{-1}
\end{align*}

We can also obtain
\begin{align*}
	K_k = P_{k}\mathbf{X}\_k^TR\_{k}^{-1}
\end{align*}

By

\begin{align*}
	P_k &= (I-K_k\mathbf{X}\_k)P\_{k-1}\\\\
	P_kP_{k-1}^{-1} &= (I-K_k\mathbf{X}\_k)\\\\
	P_kP_k^{-1} &= P_kP\_{k-1}^{-1}+P_k\mathbf{X}\_k^TR_{k}^{-1}\mathbf{X}\_k=I\\\\
	I &= (I-K_k\mathbf{X}\_k)+P_k\mathbf{X}\_k^TR_{k}^{-1}\mathbf{X}\_k\\\\
	K_k &= P_{k}\mathbf{X}\_k^TR_{k}^{-1}.
\end{align*}


### Summary of RLS

To summarize, the RLS algorithm can be updated as follows:

1. **Gain Matrix Update:**
    - $K_k = P\_{k-1}\mathbf{X}\_k^T(\mathbf{X}\_kP\_{k-1}\mathbf{X}\_k^T+R_k)^{-1}$ or
    - $K_k = P_{k}\mathbf{X}\_k^TR_{k}^{-1}$
2. **Estimate Update:** 
    - $\boldsymbol{\theta}\_k = \boldsymbol{\theta}\_{k-1}+K_k (\mathbf{y}\_k-\mathbf{X}\_k\boldsymbol{\theta}\_{k-1})$
3. **Covariance Matrix Update:**
    - $P_k = (I-K_k\mathbf{X}\_k)P\_{k-1}$.
    - $P_k = (I-K_k \mathbf{X}\_k)P\_{k-1}(I-K\_k \mathbf{X}\_k)^T+K_kR_kK_k^T,$

<!-- ### Example: Scalar Case -->

<!-- Consider a simple scalar problem where \( X_k = 1 \) and \( R_k = \mathbb{E}[\eta_k^2] \). Initially, before any measurements, we have some estimate \( \hat{\theta}_0 \) and an associated covariance \( P_0 \). As we receive each new measurement \( y_k \), the gain matrix and the estimate are updated accordingly. -->

<!-- If the initial covariance \( P_0 \) is large (indicating uncertainty), the RLS algorithm effectively weights the new measurements heavily, updating the estimate significantly with each new data point. -->

<!-- ### Curve Fitting with RLS -->

<!-- RLS can also be applied to curve fitting problems where we sequentially receive data points and want to fit a curve to them. For example, if we want to fit a straight line to noisy data, we use a linear model and update our estimates of the line parameters as new data comes in. -->

## Alternate Derivation of RLS
This chapter will be posted soon. Stay tuned for updates!

<!-- In cases where training samples arrive one by one, we can express the problem in matrix form and use the matrix inversion lemma (Sherman-Morrison-Woodbury identity) to efficiently update our estimates. This approach can also incorporate a forgetting factor \( \lambda \), which allows the model to gradually forget older data, focusing more on recent measurements. -->

<!-- The RLS method is versatile and powerful, capable of handling a wide range of scenarios where data arrives sequentially, and efficient updates are needed without recalculating from scratch. -->

#### References:
1. Simon, Dan, Optimal State Estimation: Kalman, H Infinity, and Nonlinear Approaches, 2006
