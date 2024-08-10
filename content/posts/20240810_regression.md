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

# Getting Started with Regression: An Introductory Guide (Part 1)

Regression is a method used to identify the relationship between input and output variables. In a regression problem, we are given a set of noisy measurements (or output data) $\mathbf{y} = [y_1, \dots, y_d]^T$, which are affected by measurement noise $\boldsymbol{\eta} = [\eta_1, \dots, \eta_d]^T$. The corresponding input data is denoted by $\mathbf{x} = [x_1, \dots, x_d]$. We refer to the collection of these input-output pairs as the training data, $\mathcal{D} = \{(\mathbf{x}_1, \mathbf{y}_1), \dots, (\mathbf{x}_m, \mathbf{y}_m)\}$. The true relationship between the input and output data is unknown and is represented by a function $f(\cdot)$ that maps $\mathbf{x}_n$ to $y_n$, i.e.,

\[
	\mathbf{y} = f(\mathbf{x}).
\]

Determining the exact function $f(\cdot)$ from a finite set of data points $\mathcal{D}$ is not feasible because there are infinitely many possible mappings for each $\mathbf{x}_i$. Regression helps by introducing structure to the problem. Instead of trying to find the true $f(\cdot)$, we seek an approximate model $g_\theta(\cdot)$, which is parameterized by $\boldsymbol{\theta} = [\theta_1,\dots,\theta_d]^T$. For example, we might assume a linear relationship between $(\mathbf{x}_n, \mathbf{y}_n)$:

\[
g_{\boldsymbol{\theta}}(\mathbf{y}) = \mathbf{X}\boldsymbol{\theta} + \boldsymbol{\eta},
\]

where $\mathbf{X}$ is an $m \times d$ input matrix derived from our observations. Since the true relationship is unknown, any chosen model is essentially a hypothesis. However, we can quantify the error in our model. Given a parameter $\boldsymbol{\theta}$, the error between the noisy measurements and the estimated values is:

\[
\boldsymbol{\epsilon} = \mathbf{y} - \mathbf{X}\boldsymbol{\theta}.
\]

The goal of regression is to find the best $\boldsymbol{\theta}$ that minimizes this error. This leads us to the following objective function:

\[
J(\boldsymbol{\theta}) = \boldsymbol{\epsilon}^T \boldsymbol{\epsilon}.
\]

This objective function is equivalent to minimizing the mean squared error (MSE):

\[
MSE = \frac{1}{n}\sum_{i=1}^n (y_i - \mathbf{x}_i \boldsymbol{\theta})^2.
\]

We can optimize this function in closed form as follows:

\[
J(\boldsymbol{\theta}) = \|\mathbf{y} - \mathbf{X} \boldsymbol{\theta}\|^2_2 
= (\mathbf{y} - \mathbf{X} \boldsymbol{\theta})^T(\mathbf{y} - \mathbf{X} \boldsymbol{\theta}) 
= \mathbf{y}^T \mathbf{y} - \boldsymbol{\theta}^T \mathbf{X}^T \mathbf{y} - \mathbf{y}^T \mathbf{X} \boldsymbol{\theta} + \boldsymbol{\theta}^T \mathbf{X}^T \mathbf{X} \boldsymbol{\theta}.
\]

To find the $\boldsymbol{\theta}$ that minimizes the objective function, we compute the derivative of the function and set it equal to zero:

\[
\frac{\partial J}{\partial \boldsymbol{\theta}} = -\mathbf{X}^T \mathbf{y} - \mathbf{X}^T \mathbf{y} + \mathbf{X}^T \mathbf{X} \boldsymbol{\theta} + \mathbf{X}^T \mathbf{X} \boldsymbol{\theta} = 0,
\]

which simplifies to:

\[
\mathbf{X}^T (\mathbf{X} \boldsymbol{\theta} - \mathbf{y}) = 0,
\]

leading to the solution:

\[
\boldsymbol{\theta} = (\mathbf{X}^T \mathbf{X})^{-1} \mathbf{X}^T \mathbf{y}.
\]

The equation $\mathbf{X}^T(\mathbf{X} \boldsymbol{\theta} - \mathbf{y}) = 0$ is known as the *normal equation*.
