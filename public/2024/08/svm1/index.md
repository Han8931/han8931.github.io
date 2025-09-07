# Introduction to SVM Part 1. Basics


# Support Vector Machine

## Introduction
Support Vector Machines (SVMs) are among the most effective and versatile tools in machine learning, widely used for various tasks. SVMs work by finding the optimal boundary, or hyperplane, that separates different classes of data with the maximum margin, making them highly reliable for classification, especially with complex datasets.

What truly sets SVMs apart is their ability to handle both linear and non-linear data through the _kernel trick_, allowing them to adapt to a wide range of problems with impressive accuracy. In this blog post, we'll delve into how SVMs work and gently explore the mathematical foundations behind their powerful performance.

### Decision Boundary with Margin
A hyperplane(or decision surface) is used to separate data points belonging to different classes. The goal of SVM is to find the optimal separating hyperplane. However, what is the optimal separating hyperplanes? **The optimal hyperplane is the one which maximizes the distance from the hyperplane to the nearest data point of any class. Support vectors are the data points that lie closest to the hyperplane**. The distance is referred to as the _margin_. SVMs maximize the margin around the separating hyperplane.

The equation of a hyperplane in $\mathbb{R}^p$ can be expressed as:
$$\mathbf{w}\cdot \mathbf{x}+b=0.$$
Here, $\mathbf{w}$ is the normal vector to the hyperplane. It is clear if we set it $b = \mathbf{w}\cdot\mathbf{x}_0$ 
$$\mathbf{w}(\mathbf{x}-\mathbf{x}_0)=0.$$

Let's consider a simple scenario, where training data is linearly separable: 
$$\mathcal{D} = \\{ (\mathbf{x}\_i, y_i) | \mathbf{x}\_i \in \mathbb{R}\^p,\ y\_i \in \{-1,1\}\\}\_{i=1}^N.$$
Then, we can build two supporting hyperplanes separating the data with no points between them:
- $H_1:\mathbf{w}\cdot \mathbf{x}+b=1$
- $H_2:\mathbf{w}\cdot \mathbf{x}+b=-1$

All samples have to satisfy one of two constraints:
- $\mathbf{w}\cdot \mathbf{x}+b\geq1$
- $\mathbf{w}\cdot \mathbf{x}+b\leq-1$
These constraints can be combined into a single expression:
$$y(\mathbf{w}\cdot \mathbf{x}+b)\geq 1.$$

To maximize the margin, we can consider a unit vector $\mathbf{u} = \frac{\mathbf{w}}{\lVert\mathbf{w}\rVert}$, which is perpendicular to the hyperplanes and a point $x\_0$ on the hyperplane $H\_2$. If we scale $\mathbf{u}$ from $\mathbf{x}\_0$, we get $z = \mathbf{x}\_0+\gamma\mathbf{u}$. If we assume $z$ is on $H_1$, then $\mathbf{w}\cdot z +b=1$. This is equivalent to 
\begin{align*}
	\mathbf{w}\cdot (\mathbf{x}\_0+\gamma \mathbf{u})+b=1\\\\
	\mathbf{w}x_0+\mathbf{w}\gamma\frac{\mathbf{w}}{\lVert\mathbf{w}\rVert}+b=1\\\\
	\mathbf{w}x_0+\gamma\lVert \mathbf{w}\rVert +b=1\\\\
	\mathbf{w}x_0+b=1-\gamma\lVert \mathbf{w}\rVert 
\end{align*}
As $x_0$ is on $H_2$, we get $\mathbf{w}x_0+b=-1$. Finally, we obtain
\begin{align*}
	-1=1-\gamma\lVert \mathbf{w}\rVert \\\\
	\gamma=\frac{2}{\lVert \mathbf{w}\rVert }.
\end{align*}
Note that the scaled unit vector $\gamma \mathbf{u}$'s magnitude is $\gamma$. Thus, the maximization of margin is equivalent to maximize $r$. To maximize $r$, we have to minimize $\lVert \mathbf{w} \rVert$. Thus, finding the optimal hyperplane reduces to solving the following optimization problem:
\begin{align*}
	&\min \lVert \mathbf{w}\rVert ,\quad \textrm{subject to } \\\\
	&y_i(\mathbf{w}\cdot \mathbf{x}_i+b)\geq 1 \quad\forall i.
\end{align*}
Equivalently, 
\begin{align*}
	&\min \frac{1}{2}\lVert w\rVert ^2,\quad \textrm{subject to } \\\\
	&y_i(\mathbf{w}\cdot \mathbf{x}_i+b)\geq 1 \quad\forall i.
\end{align*}
Now, we have _convex quadratic optimization problem_. The solution of this problem gives us the optimal hyperplane that maximizes the margin (Details are in the following section). However, in practice, the data may not be perfectly separable. To account for this, we introduce a _soft margin_ that allows for some misclassification. This is done by admitting small errors in classification and potentially using a more complex, _nonlinear decision boundary_, improving the generalization of the model.

### Alternative Derivation
Consider a point $\mathbf{x}$. Let $\mathbf{d}$ be the vector from a hyperplane (i.e., $\mathbf{w}\mathbf{x}+b=0$) to $\mathbf{x}$ of minimum length. Let $\mathbf{x}\_0$ be the projection of $\mathbf{x}$ onto the hyperplane. Then, 
\begin{align*}
	\mathbf{x}\_0 = \mathbf{x} - \mathbf{d}.
\end{align*}
As $\mathbf{d}$ is parallel to $\mathbf{w}$, so $\mathbf{d} = \alpha \mathbf{w}$ for some $\alpha\in \mathbb{R}$. Since $\mathbb{x}\_0$ is on the hyperplane, $\mathbf{w}\mathbf{x}\_0 + b = 0$. Thus,

\begin{align*}
	\mathbf{w}\mathbf{x}\_0 + b = \mathbf{w}(\mathbf{x}-\mathbf{d}) + b = \mathbf{w}(\mathbf{x}-\alpha\mathbf{w}) + b = 0.
\end{align*}

Then, we get
\begin{align*}
	\alpha = \frac{\mathbf{w}\mathbf{x}+b}{\mathbf{w}^T\mathbf{w}}.
\end{align*}
The length of $\mathbf{d}$ is given by  
\begin{align*}
	\lVert \mathbf{d} \|\_2 = \sqrt{\alpha^2\mathbf{w}^T\mathbf{w}} = \frac{|\mathbf{w}\mathbf{x}+b|}{\sqrt{\mathbf{w}^T\mathbf{w}}} = \frac{|\mathbf{w}\mathbf{x}+b|}{\lVert\mathbf{w}\rVert\_2}.
\end{align*}
We can obtain the margin by choosing the support vector, which is the closest point to the hyperplane by
\begin{align*}
	\gamma(\mathbf{w}, b) = \min\_{\mathbf{x}\in \mathcal{D}}\frac{|\mathbf{w}\mathbf{x}+b|}{\lVert\mathbf{w}\rVert\_2}.
\end{align*}
Note that the margin and hyperplane are scale invarianct:
\begin{align*}
	\gamma(\beta\mathbf{w}, \beta b) = \gamma(\mathbf{w}, b).
\end{align*}

## Error Handling in SVM
In practice, it's unrealistic to expect a perfect separation of data, especially when the data is noisy or not linearly separable. To address this, we can allow for some prediction errors while still striving to find an optimal decision boundary.

One approach is to minimize the norm of the weight vector, while penalizing the number of errors $N_e$. The optimization problem can be formulated as follows:
\begin{align*}
	&\min \frac{1}{2}\lVert \mathbf{w}\rVert^2 +C\cdot N_{e},\quad \text{subject to } \\\\
	&y_i(\mathbf{w}\cdot \mathbf{x}_i+b)\geq 1 \quad \forall i.
\end{align*}
Here, $C$ is a regularization parameter that controls the trade-off between minimizing the weight vector and the number of errors. The penalty approach described here is known as _0-1 loss_, where all errors are treated equally. However, this approach is not commonly used. Instead, a more practical approach introduces a _slack variable_ with _hinge loss_. The slack variable ($\xi_j$) measures the degree of misclassification or how much a point is violating the margin. This leads to the following problem:
\begin{align*}
	&\min \frac{1}{2}\lVert \mathbf{w}\rVert^2 +C\sum\_j\xi_j ,\quad \textrm{subject to } \\\\
	&y_i(\mathbf{w}\cdot \mathbf{x}\_i+b)\geq 1-\xi_j \quad \forall i,\ \xi_j\geq 0,\ \forall j.
\end{align*}
Note that $\xi\_j>1$, when SVMs make errors:
\begin{align*}
	\xi\_j = (1-(\mathbf{w}\mathbf{x}\_j+b)y\_j)\_+
\end{align*}
Let's look at the new constraint. If some data points are misclassified, then $\xi_j>1$ and $y_i(\mathbf{w}\cdot \mathbf{x}_i+b)\leq 0$. This approach is called *soft-margin SVM*. Lastly, how do we set $C$? A large value of $C$ places a higher penalty on errors, leading to a narrower margin but fewer misclassifications (i.e.,  the SVM will try to classify all data points correctly), whereas a smaller value of $C$ allows for a wider margin but potentially more misclassifications. The optimal value of $C$ is typically chosen through cross-validation.


## SVM Optimization: Lagrange Multipliers

### Lagrange Multipliers

Consider the optimization problem:
\begin{align*}
&\min_{\mathbf{x}} f(\mathbf{x}) \\\\
&\text{subject to}\quad g(\mathbf{x})=0.
\end{align*}
To find the minimum of $f$ under the constraint $g(\mathbf{x})$, we use the method of _Lagrange multipliers_. The key idea is that at the optimal point, the gradient of $f(\mathbf{x})$ must be parallel to the gradient of $g(\mathbf{x})$. Mathematically, this condition is expressed as: 
$$\nabla f(\mathbf{x}) = \lambda\nabla g(\mathbf{x}).$$

#### Example:
Consider a simple 2D example where you want to minimize the function $f(x,y)=x^2+y^2$, which represents a circle centered at the origin. This function increases as you move away from the origin, so the minimum is at the origin. 

Now, consider the constraint: $g(x,y)=x+y-1=0$. This constraint is a line that runs through the $xy$-plane. Our goal is to find the point on this line that minimizes $f(x,y)$.

A Lagrange multiplier is like a balancing factor that adjusts the direction and magnitude of your search along the constraint. As you move along the constraint line $g(x,y)$, $\lambda$ ensures that the solution also respects the shape of the function $f(x,y)$ that you are trying to minimize. 
To solve the constraint optimization problem, we define the Lagrangian function: 
$$\mathcal{L}(\mathbf{x}, \lambda) = f(\mathbf{x}) - \lambda g(\mathbf{x}).$$

To find the minimum, we take the partial derivatives of $\mathcal{L}(\mathbf{x}, \lambda)$ with respect to both $\mathbf{x}$ and $\lambda$, and set them equal to zero. 

### SVM Optimization
Recall that we want to solve the following convex quadratic optimization problem:
\begin{align*}
	&\min \frac{1}{2}\lVert \mathbf{w}\rVert ^2,\quad \textrm{subject to } \\\\
	&y_i(\mathbf{w}\cdot \mathbf{x}_i+b)\geq 1 \quad\forall i.
\end{align*}
The objective is to find the optimal hyperplane that maximizes the margin between two classes of data points. 

We can reformulate this optimization problem using the method of Lagrange multipliers, which introduces a set of multipliers $\alpha_i$ (one for each constraint). The Lagrangian function for this problem is given by:
\begin{align*}
	\mathcal{L}(\mathbf{w}, b, \alpha) = \frac{1}{2}\lVert \mathbf{w}\rVert ^2 - \sum_{i=1}^N \alpha_i \left[y_i(\mathbf{w}\cdot \mathbf{x}_i+b)-1\right]
\end{align*}

### Duality and the Lagrangian Problem

While we could attempt to solve the primal optimization problem directly, it is often more practical, especially for large datasets, to reformulate the problem using the duality principle. The dual form is advantageous because it depends only on the inner products of the data points, which allows the use of kernel methods for non-linear classification.

To find the solution to the primal problem, we solve the following problem:
\begin{align*}
	&\max_{\mathbf{w}, b}\min_\alpha \mathcal{L}(\mathbf{w}, b, \alpha)\\\\
	&\textrm{subject to}\quad \alpha_i\geq 0, \forall i.
\end{align*}
Here, we maximize the Lagrangian with respect to the multipliers $\alpha_i$, while minimizing with respect to the primal variables $\mathbf{w}$ and $b$.

### Handling Inequality Constraints with KKT Conditions

You may observe that the method of Lagrange multipliers is used for equality constraints. However, it can be extended to handle inequality constraints through the use of additional conditions known as the _Karush-Kuhn-Tucker (KKT) conditions_. These conditions ensure that the solution satisfies the necessary optimality criteria for problems with inequality constraints. 

## The Wolfe Dual Problem
The Lagrangian problem for SVM optimization involves $N$ inequality constraints, where $N$ is the number of training examples. This problem is typically tacked using its _dual form_. The duality principle provides a powerful framework, stating that **an optimization problem can be approached from two perspectives**: 

- The _primal problem_, which in our context is a minimization problem.
- The _dual problem_, which is a maximization problem.

An important aspect of duality is that **the maximum value of the dual problem is always less than or equal to the minimum value of the primal problem.** This relationship means that the dual problem **provides a lower bound to the solution of the primal problem**.

In the context of SVM optimization, we are dealing with a convex optimization problem. According to _Slater's condition_, which applies to problems with affine constraints, strong duality holds. Strong duality implies that the optimal values of the primal and dual problems are equal, meaning the maximum value of the dual problem equals the minimum value of the primal problem. This equality allows us to solve the dual problem instead of the primal problem, often leading to computational advantages.

Recall that we aim to solve the following optimization problem:
\begin{align*}
	\mathcal{L}(\mathbf{w}, b, \alpha) = \frac{1}{2}\lVert \mathbf{w}\rVert\^2 - \sum\_{i=1}^N \alpha\_i \left[y_i(\mathbf{w}\cdot \mathbf{x}\_i+b)-1\right]
\end{align*}
The minimization problem involves solving the partial derivatives of $\mathcal{L}$ with respect to $\mathbf{w}$ and $b$ and set them equal to zero:
\begin{align*}
	&\nabla\_\mathbf{w}\mathcal{L}(\mathbf{w}, b, \alpha) = \mathbf{w} - \sum\_i \alpha\_i y_i \mathbf{x}\_i\\\\
	& \nabla_b\mathcal{L}(\mathbf{w}, b, \alpha) = -\sum\_i \alpha\_i y\_i
\end{align*}
Form the first equation, we obtain:
\begin{align*}
	&\mathbf{w} = \sum\_{i=1}^m \alpha\_i y_i \mathbf{x}\_i\\
\end{align*}
Next, we substitute the objective function with $\mathbf{w}$:
\begin{align*}
	\mathbf{W}(\alpha, b) &= \frac{1}{2}\left(\sum_i \alpha_i y_i \mathbf{x}_i\right)\cdot \left(\sum_j \alpha_j y_j \mathbf{x}_j\right)\\\\
                    &\quad - \sum_i \alpha_i \left[y_i\left(\left(\sum_j \alpha_j y_j \mathbf{x}_j\right)\cdot \mathbf{x}_i+b\right)-1\right]\\\\
						  &= \frac{1}{2}\Big(\sum_i\sum_j \alpha_i\alpha_j y_iy_j \mathbf{x}_i\cdot \mathbf{x}_j\Big)\\\\ 
                          &\quad - \sum_i \alpha_i \Bigg[y_i\Bigg(\Big(\sum_j \alpha_j y_j \mathbf{x}_j\Big)\cdot \mathbf{x}_i+b\Bigg)\Bigg]+\sum_i \alpha_i \\\\
						  &= \frac{1}{2}\sum_i\sum_j \alpha_i\alpha_j y_iy_j \mathbf{x}_i\cdot \mathbf{x}_j - \sum_i\sum_j \alpha_i\alpha_j y_iy_j \mathbf{x}_i \cdot \mathbf{x}_j\\\\
                          &\quad -\sum_i \alpha_i y_i b+\sum_i \alpha_i \\\\
						  &= \sum_i \alpha_i -\frac{1}{2}\sum_i\sum_j \alpha_i\alpha_j y_iy_j \mathbf{x}_i\cdot \mathbf{x}_j-\sum_i \alpha_i y_i b
\end{align*}
Note that we use two indices, $i$ and $j$ when substituting $\mathbf{W}$. This is obvious if we consider a simple example. Imagine you have two data points:
\begin{align*}
	\mathbf{x}_1,y1&=(1,2),1\\\\
	\mathbf{x}_2,y2&=(2,1),−1
\end{align*}
Then,
\begin{align*}
	\lVert \mathbf{w}\rVert^2=\mathbf{w}\cdot \mathbf{w}=\underbrace{(\alpha_1y_1\mathbf{x}_1+\alpha_2y_2\mathbf{x}\_2)}\_{\sum\_i}\cdot\underbrace{(\alpha_1y_1\mathbf{x}_1+\alpha_2y_2\mathbf{x}\_2)}\_{\sum\_j}.
\end{align*}
This simplification shows that the optimization problem can be reformulated purely in terms of the Lagrange multipliers $\alpha_i$. Note that the term involving $b$ can be removed by setting $b=0$, simplifying our equation further:
\begin{align*}
	 \mathbf{W}(\alpha, b) = \sum\_i \alpha\_i -\frac{1}{2}\sum\_i\sum\_j \alpha\_i\alpha\_j y\_iy\_j (\mathbf{x}\_i\cdot \mathbf{x}\_j)
\end{align*}
This expression is known as the *Wolfe dual Lagrangian function*. We have transformed the problem into one involving only the multipliers $\alpha_i$, resulting in a quadratic programming problem, commonly referred to as the *Wolfe dual problem*:
\begin{align*}
	 &\max\_\alpha \mathbf{W}(\alpha, b) = \sum\_i \alpha\_i -\frac{1}{2}\sum\_i\sum\_j \alpha\_i\alpha\_j y\_iy\_j (\mathbf{x}\_i\cdot \mathbf{x}\_j)\\\\
	 &\text{subject to } \alpha_i\geq 0 \text{ for any } i=1,\dots,m\\\\
	 & \sum\_{i=1}\^m \alpha\_iy\_i=0
\end{align*}
Once we get the value of $\alpha$, the optimal $\mathbf{w}$ and $b$ can be computed using 
\begin{align*} 
	\alpha\_i \left[ y\_i(\mathbf{w} \cdot \mathbf{x}\_i + b) - 1 \right] = 0. 
\end{align*}
One important aspect of the dual problem is that it only involves the dot product of the input vectors $\mathbf{x}$. This property allows us to use of the *kernel trick* to handle non-linearly separable data by mapping it to a higher-dimensional space. 

## Karush-Kuhn-Tucker conditions

When dealing with optimization problems that involve inequality constraints, such as those encountered in Support Vector Machines (SVMs), an additional requirement must be met: the solution must satisfy the _Karush-Kuhn-Tucker (KKT) conditions_.

The KKT conditions are a set of first-order necessary conditions that must be satisfied for a solution to be optimal. These conditions extend the method of Lagrange multipliers to handle inequality constraints and are particularly useful in non-linear programming. For the KKT conditions to apply, the problem must also satisfy certain regularity conditions. Fortunately, one of these regularity conditions is Slater’s condition, which we have already established holds true for SVMs.

### KKT Conditions and SVM Optimization

In the context of SVMs, the optimization problem is convex, meaning that the KKT conditions are not only necessary but also sufficient for optimality. This implies that if a solution satisfies the KKT conditions, it is guaranteed to be the optimal solution for both the primal and dual problems. Moreover, in this case, there is no duality gap, meaning the optimal values of the primal and dual problems are equal.


## Prediction

Firstly, for a Linear SVM with no kernel, the primal weight vector is given by
$$ w=\sum_{i\in \mathcal S}\alpha\_i\,y\_i\,x\_i $$

Then, the decision function is
$$ f(x)=w^{\!\top}x + b $$

Since the feature map $\phi(\,\cdot\,)$ may live in a huge or even infinite-dimensional space, we never form $w$ explicitly. Instead we keep the **kernel trick** inside the decision function:
$$ f(x)=\sum_{i\in\mathcal S}\alpha\_i\,y\_i\,K(x\_i,\,x)+b $$

where $K(x_i,x)=\langle\phi(x\_i),\phi(x)\rangle$.
Typical kernels are the RBF $K(u,v)=\exp\\!\bigl(-\frac{\|u-v\|^2}{2\sigma^2}\bigr)$ or the polynomial $K(u,v)=(u^{\\!\top}v+c)^p$.

Finally, we need to turn the decision value into a class label. For binary classification the prediction is simply the sign of the decision function:

\begin{align*}
    \hat y = \operatorname{sign}\bigl(f(x)\bigr) = 
    \begin{cases}
        +1 &\text{if }f(x)\gt 0,\\\\
        -1 &\text{if }f(x)\lt 0.
    \end{cases}
\end{align*}

In sum,
\begin{align*}
    \textbf{Predict}(x):
    \quad f(x)=\sum_{i\in\mathcal S}\alpha_i\,y_i\,K(x_i,x)+b,\;
    \hat y=\text{sign}\bigl(f(x)\bigr)
\end{align*}



#### Reference
- Alexandre Kowalczyk, Support Vector Machines Succinctly, 2017



