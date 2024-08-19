# Direction of Gradient Descent Update


# On Gradient Descent

Gradient descent is an optimization algorithm used to minimize a function by iteratively moving towards the function's minimum value. It is a fundamental concept in machine learning, particularly in training models such as neural networks. The gradient is a vector that represents the direction of the steepest increase of the function at a given point. For example, for a convex function $z = ax^2 + by^2$, the gradient is $[2ax, 2by]$, which points in the direction of the steepest ascent.

In gradient descent, the goal is to minimize the function, so the algorithm moves in the opposite direction of the gradient, which is $[-2ax, -2by]$. This opposite direction is chosen because it is the direction of the steepest decrease in the function value. But how do we know that moving in this direction will strictly decrease the function value?

## Direction of Gradient Descent
Let's investigate the direction of gradient descent. 
- The derivative of the objective function $f(\mathbf{x})$ provides the slope of $f(\mathbf{x})$ at the point $f(\mathbf{x})$.
- It tells us how to change $\mathbf{x}$ in order to make a small improvement in our goal.

A function $f(\mathbf{x})$ can be approximated by its first-order Taylor expansion at $\bar{\mathbf{x}}$:
$$f(\mathbf{x})\approx f(\bar{\mathbf{x}})+\nabla f(\bar{\mathbf{x}})^T(x-\bar{\mathbf{x}})$$
Now let $\mathbf{d}\neq0, \|\mathbf{d}\|=1$ be a direction, and in consideration of a new point $\mathbf{x}:=\bar{\mathbf{x}}+\mathbf{d}$, we define:
$$f(\bar{\mathbf{x}}+\mathbf{d})\approx f(\bar{\mathbf{x}})+\nabla f(\bar{\mathbf{x}})^T\mathbf{d}$$

We would like to choose $\mathbf{d}$ that minimizes the function $f$. From the Cauchy-Schwarz inequality[^1] , we know that
$$|\nabla f(\bar{\mathbf{x}})^T\mathbf{d}|\leq \lVert\nabla f(\bar{\mathbf{x}})\rVert\,\lVert\mathbf{d}\rVert.$$
The equality holds if and only if $\mathbf{d}=\lambda \nabla f(\bar{\mathbf{x}})$, where $\lambda\in \mathbb{R}$. Since we want to minimize the function $f$, we negate the steepest direction $\mathbf{d}^{*}$, then 
$$f(\bar{\mathbf{x}}+\mathbf{d})\approx f(\bar{\mathbf{x}})-\lambda\nabla f(\bar{\mathbf{x}})^T\nabla f(\bar{\mathbf{x}}).$$
Since $\nabla f(\bar{\mathbf{x}})^T\nabla f(\bar{\mathbf{x}})$ is \textbf{always positive}, the term $-\lambda\nabla f(\bar{\mathbf{x}})^T\nabla f(\bar{\mathbf{x}})$ is always negative. Therefore by updating $\rvx$
$$\mathbf{x}^{(k+1)} = \mathbf{x}^{(k)} - \eta \nabla f(\mathbf{x}^{(k)}),$$
we get
$$f(\mathbf{x}^{(k+1)}) < f(\mathbf{x}^{(k)}).$$

[^1]: Cauchy-Schwarz Inequaility: $|\mathbf{a}\cdot \mathbf{b}|\leq \lVert\mathbf{a}\rVert \, \lVert\mathbf{b}\rVert$. Equality holds if and only if either $\mathbf{a}$ or $\mathbf{b}$ is a multiple of the other.

